import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../data/scan_history.dart';
import '../l10n/app_strings.dart';
import '../models/chat_message.dart';
import '../models/crop_diagnosis.dart';
import '../models/crop_photo.dart';
import '../services/ai_failure.dart';
import '../services/crop_doctor_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../widgets/cassia_ui.dart';
import '../widgets/language_toggle.dart';
import 'ask_cassia_screen.dart';

/// Crop Doctor — the app's #1 feature, laid out as in the approved design.
///
/// One page, top to bottom: the green header with its three steps, one-tap
/// crop chips, the details (crop, growth stage, days, notes), three photo
/// slots, the Take Photo / Choose from Gallery / Diagnose My Crop buttons,
/// the diagnosis as a stack of cards, and the farmer's recent scans.
///
/// The photos and details go to the `diagnoseCrop` Cloud Function (OpenAI
/// vision); the API key stays server-side. The diagnosis is written in the
/// app's current language.
class CropDoctorScreen extends StatefulWidget {
  const CropDoctorScreen({
    super.key,
    this.service,
    this.history,
    this.embedded = false,
  });

  /// True when shown as a tab under the app's shared header: the screen then
  /// has no bar of its own.
  final bool embedded;

  /// Replaceable in tests; defaults to the real Cloud Function client.
  final CropDoctorService? service;

  /// Replaceable in tests; defaults to the list kept on this phone.
  final ScanHistory? history;

  @override
  State<CropDoctorScreen> createState() => _CropDoctorScreenState();
}

/// One card of the diagnosis: its emoji, title and text, and — on the "most
/// likely problem" card — how sure the diagnosis is, drawn as a bar.
typedef _Finding = ({String emoji, String title, String body, int? percent});

class _CropDoctorScreenState extends State<CropDoctorScreen>
    with SingleTickerProviderStateMixin {
  late final CropDoctorService _service =
      widget.service ?? CropDoctorService();
  ScanHistory? _history;

  // The details. Crop and stage hold the English value that is sent for
  // diagnosis ('' = not chosen); the lists show them in the app's language.
  String _crop = '';
  String _stage = '';
  final _days = TextEditingController();
  final _notes = TextEditingController();

  final List<CropPhoto> _photos = [];

  bool _busy = false;
  CropDiagnosis? _result;
  AiFailure? _failure;

  /// The language the diagnosis on screen was asked for in. Its cards stay
  /// in that language even if the app's language is switched afterwards.
  AppStrings _resultStrings = AppStrings.en;

  /// Drives the green line that sweeps over the photos while they are read.
  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  final _outputKey = GlobalKey();

  AppPalette get _c => context.colors;
  AppStrings get _s => context.s;

  static const int _max = CropDoctorService.maxPhotos;

  @override
  void initState() {
    super.initState();
    _history = widget.history;
    if (_history == null) {
      ScanHistory.open().then((history) {
        if (mounted) setState(() => _history = history);
      });
    }
  }

  @override
  void dispose() {
    _scan.dispose();
    _days.dispose();
    _notes.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------- photos

  Future<void> _takePhoto() => _addPhotos(() async {
        final photo = await _service.pickImage(ImageSource.camera);
        return [?photo];
      });

  Future<void> _chooseFromGallery() =>
      _addPhotos(() => _service.pickFromGallery(_max - _photos.length));

  Future<void> _addPhotos(Future<List<XFile>> Function() pick) async {
    if (_photos.length >= _max) {
      _toast(_s.photoLimit(_max));
      return;
    }
    FocusScope.of(context).unfocus(); // put the keyboard away
    try {
      final files = await pick();
      final photos = [for (final f in files) await CropPhoto.fromFile(f)];
      if (!mounted || photos.isEmpty) return;
      setState(() => _photos.addAll(photos.take(_max - _photos.length)));
    } catch (_) {
      if (mounted) _toast(_s.couldNotAddPhoto);
    }
  }

  void _removePhoto(int index) => setState(() => _photos.removeAt(index));

  // ----------------------------------------------------------- diagnosis

  Future<void> _diagnose() async {
    if (_photos.isEmpty || _busy) return;
    // Read these now: they are what the farmer sees when they tap.
    final s = _s;
    final crop = _crop;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _result = null;
      _failure = null;
    });
    _scan.repeat();
    _revealOutput();

    CropDiagnosis? diagnosis;
    AiFailure? failure;
    try {
      diagnosis = await _service.diagnose(
        List.of(_photos),
        language: s.languageCode,
        crop: crop,
        stage: _stage,
        days: _days.text,
        notes: _notes.text,
      );
    } on AiFailure catch (e) {
      failure = e;
    } catch (_) {
      failure = const AiFailure(AiFailureKind.other);
    }
    if (!mounted) return;

    _scan
      ..stop()
      ..reset();
    setState(() {
      _busy = false;
      _result = diagnosis;
      _failure = failure;
      _resultStrings = s;
    });
    _revealOutput();

    if (diagnosis != null && diagnosis.isPlant) {
      await _history?.add(crop: crop, summary: _summaryOf(diagnosis));
      if (mounted) setState(() {}); // show it under "Recent scans"
    }
  }

  /// The line a scan is remembered by.
  static String _summaryOf(CropDiagnosis d) {
    for (final text in [d.summary, d.problem, d.observed]) {
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  /// Scrolls the "Analysing…" line, and then the diagnosis, into view.
  void _revealOutput() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _outputKey.currentContext;
      if (box == null) return;
      Scrollable.ensureVisible(
        box,
        alignment: 0.1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  /// The diagnosis as cards, in the design's order. A part the diagnosis
  /// left empty gets no card.
  static List<_Finding> _findings(CropDiagnosis d, AppStrings s) {
    String bullets(List<String> items) => items.length == 1
        ? items.first
        : [for (final item in items) '• $item'].join('\n');
    String steps(List<String> items) => items.length == 1
        ? items.first
        : [
            for (final (i, item) in items.indexed) '${i + 1}. $item',
          ].join('\n');

    final sure = d.confidencePercent > 0 ? d.confidencePercent : null;
    final problem = [
      if (d.problem.isNotEmpty)
        d.problem
      else if (d.healthy)
        s.looksHealthy
      else
        s.notSure,
      if (sure != null) s.confidencePercent(sure),
      if (d.reason.isNotEmpty) d.reason,
    ].join('\n');

    return [
      if (d.observed.isNotEmpty)
        (emoji: '👁️', title: s.whatISee, body: d.observed, percent: null),
      (
        emoji: '🎯',
        title: s.mostLikelyProblem,
        body: problem,
        percent: sure,
      ),
      if (d.alternatives.isNotEmpty)
        (
          emoji: '🔀',
          title: s.otherPossibilities,
          body: bullets(d.alternatives),
          percent: null,
        ),
      if (d.cause.isNotEmpty)
        (emoji: '🧪', title: s.whatIsLacking, body: d.cause, percent: null),
      if (d.treatment.isNotEmpty)
        (
          emoji: '💊',
          title: s.treatmentSteps,
          body: steps(d.treatment),
          percent: null,
        ),
      if (d.prevention.isNotEmpty)
        (
          emoji: '🛡️',
          title: s.preventionNextTime,
          body: bullets(d.prevention),
          percent: null,
        ),
      if (d.needMore.isNotEmpty)
        (
          emoji: '📸',
          title: s.forSurerDiagnosis,
          body: d.needMore,
          percent: null,
        ),
    ];
  }

  /// The diagnosis as plain text — what "Copy" copies and what "Ask
  /// follow-up" hands to Ask Cassia.
  static String _plainText(CropDiagnosis d, AppStrings s) {
    return [
      for (final (i, f) in _findings(d, s).indexed)
        '${i + 1}) ${f.title}:\n${f.body}',
    ].join('\n\n');
  }

  Future<void> _copy(CropDiagnosis d) async {
    final s = _resultStrings;
    await Clipboard.setData(ClipboardData(text: _plainText(d, s)));
    if (mounted) _toast(_s.diagnosisCopied);
  }

  /// Opens Ask Cassia with the diagnosis already in the chat, ready for the
  /// farmer's question about it.
  void _askFollowUp(CropDiagnosis d) {
    final s = _resultStrings;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AskCassiaScreen(
        initialMessages: [
          ChatMessage.user(s.followUpIntro(_plainText(d, s))),
          ChatMessage.assistant(s.followUpReply),
        ],
      ),
    ));
  }

  /// The design's toast: a dark pill that comes and goes by itself.
  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: const StadiumBorder(),
        duration: const Duration(milliseconds: 2400),
      ));
  }

  // ---------------------------------------------------------------- page

  /// Room for the bottom bar, which a tab's content scrolls underneath.
  double get _under => MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final s = _s;
    const gap = SizedBox(height: 10);

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(s.cropDoctor),
              actions: const [LanguageToggle(), SizedBox(width: 4)],
            ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + _under),
        children: [
          _headerCard(),
          const SizedBox(height: 6),
          _cropChips(),
          gap,
          _select(
            value: _crop,
            placeholder: s.whichCrop,
            options: s.doctorCrops,
            onChanged: (value) => setState(() => _crop = value),
          ),
          gap,
          _select(
            value: _stage,
            placeholder: s.growthStage,
            options: s.growthStages,
            onChanged: (value) => setState(() => _stage = value),
          ),
          gap,
          TextField(
            controller: _days,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            textInputAction: TextInputAction.next,
            style: _fieldText,
            decoration: _fieldDecoration(hint: s.sinceHowManyDays),
          ),
          gap,
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 5,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            style: _fieldText,
            decoration: _fieldDecoration(hint: s.doctorNotesHint),
          ),
          const SizedBox(height: 12),
          _photoSlots(),
          gap,
          BlockButton(label: '📷 ${s.takePhoto}', onTap: _takePhoto),
          gap,
          BlockButton(
            label: '🖼️ ${s.chooseFromGallery}',
            outlined: true,
            onTap: _chooseFromGallery,
          ),
          gap,
          BlockButton(
            label: '🔍 ${s.diagnoseMyCrop}',
            onTap: _photos.isEmpty || _busy ? null : _diagnose,
          ),
          KeyedSubtree(key: _outputKey, child: _output()),
          _recentScans(),
          const SizedBox(height: 12),
          Text(
            s.doctorNote,
            style: TextStyle(color: _c.muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- header

  /// The green card at the top: what Crop Doctor is, and its three steps.
  Widget _headerCard() {
    final s = _s;

    Widget step(String number, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0x1FFFFFFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(number,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        height: 1.2)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xE6FFFFFF),
                        fontWeight: FontWeight.w500,
                        fontSize: 11)),
              ],
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF143D20), Color(0xFF2F7A3F)],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x144A2F1B), blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('\u{1FA7A} ${s.cropDoctor}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(s.doctorHeader,
              style: const TextStyle(
                  color: Color(0xD9FFFFFF), fontSize: 13, height: 1.35)),
          const SizedBox(height: 12),
          Row(
            children: [
              step('1', s.stepPhotos),
              const SizedBox(width: 8),
              step('2', s.stepDetails),
              const SizedBox(width: 8),
              step('3', s.stepDiagnosis),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- details

  /// The one-tap crops: a row of pills that scrolls sideways. Tapping one
  /// fills in the "Which crop?" list underneath.
  Widget _cropChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Room underneath for the pills' lip.
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        children: [
          for (final (emoji, value, label) in _s.doctorCropChips)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: _cropChip(emoji, value, label),
            ),
        ],
      ),
    );
  }

  Widget _cropChip(String emoji, String value, String label) {
    final on = _crop == value;
    // The green is the same in both themes, as in the design.
    const green = AppColors.greenLight;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: on ? green : _c.card,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: on ? green : _c.line),
        boxShadow: [
          BoxShadow(
            color: on ? const Color(0xFF17492A) : _c.line,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() => _crop = value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Text(
              '$emoji $label',
              style: TextStyle(color: on ? Colors.white : _c.ink, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  /// The text inside the lists and boxes. It starts from the theme's own
  /// style so that it keeps the app's font — in the lists too, where a bare
  /// style would drop it and Urdu would fall back to a poorer one.
  TextStyle get _fieldText =>
      (Theme.of(context).textTheme.bodyLarge ?? const TextStyle())
          .copyWith(color: _c.ink, fontSize: 16, letterSpacing: 0);

  /// The look shared by the lists and text boxes: a white box with a thin
  /// line round it.
  InputDecoration _fieldDecoration({String? hint}) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _c.muted, fontSize: 16),
      counterText: '', // no 0/300 counter
      isDense: true,
      filled: true,
      fillColor: _c.card,
      contentPadding: const EdgeInsets.all(13),
      border: border(_c.line),
      enabledBorder: border(_c.line),
      focusedBorder: border(_c.green, 1.5),
    );
  }

  /// A drop-down list whose first entry is its own question ("Which crop?"),
  /// standing for "not chosen" — as in the design.
  Widget _select({
    required String value,
    required String placeholder,
    required List<(String, String)> options,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      // The field reads its value only when first built, so a new value
      // (from a crop chip, say) needs a new field.
      key: ValueKey('$placeholder/$value'),
      initialValue: value,
      isExpanded: true,
      icon: Icon(Icons.keyboard_arrow_down, color: _c.ink),
      dropdownColor: _c.card,
      borderRadius: BorderRadius.circular(12),
      style: _fieldText,
      decoration: _fieldDecoration(),
      items: [
        DropdownMenuItem(value: '', child: Text(placeholder)),
        for (final (optionValue, label) in options)
          DropdownMenuItem(value: optionValue, child: Text(label)),
      ],
      onChanged: (chosen) => onChanged(chosen ?? ''),
    );
  }

  // --------------------------------------------------------- photo slots

  Widget _photoSlots() {
    final labels = _s.photoSlots;
    return Row(
      children: [
        for (var i = 0; i < _max; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1,
              child: i < _photos.length
                  ? _filledSlot(i, _photos[i])
                  : _emptySlot(labels[i]),
            ),
          ),
        ],
      ],
    );
  }

  /// An empty slot says which photo belongs in it; tapping it opens the
  /// camera.
  Widget _emptySlot(String label) {
    return Semantics(
      button: true,
      child: Material(
        color: _c.card,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _takePhoto,
          child: CustomPaint(
            painter: _DashedBorder(color: _c.line),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📷', style: TextStyle(fontSize: 24, height: 1.2)),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _c.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filledSlot(int index, CropPhoto photo) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(photo.bytes, fit: BoxFit.cover, gaplessPlayback: true),
          CustomPaint(painter: _DashedBorder(color: _c.line)),
          // While the photos are being read, a green line sweeps down them.
          if (_busy)
            AnimatedBuilder(
              animation: _scan,
              builder: (context, _) => Align(
                alignment: Alignment(0, _scan.value * 2 - 1),
                child: const _ScanLine(),
              ),
            ),
          PositionedDirectional(
            top: 0,
            end: 0,
            child: Tooltip(
              message: _s.removePhoto,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _removePhoto(index),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xAA000000),
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '×',
                      style: TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- output

  /// Under the buttons: "Analysing…", then the diagnosis or what went wrong.
  Widget _output() {
    if (_busy) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(_s.analysing, style: TextStyle(color: _c.ink, fontSize: 15)),
          ],
        ),
      );
    }

    final failure = _failure;
    if (failure != null) {
      final (title, body) = _explain(failure);
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: _findingCard((emoji: '⚠️', title: title, body: body, percent: null)),
      );
    }

    final d = _result;
    if (d == null) return const SizedBox.shrink();

    // The diagnosis keeps the language — and so the reading direction — it
    // was asked for in.
    final s = _resultStrings;
    return Directionality(
      textDirection: s.isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!d.isPlant)
              _findingCard((
                emoji: '🚫',
                title: s.notACropTitle,
                body: d.summary.isNotEmpty ? d.summary : s.notACropBody,
                percent: null,
              ))
            else ...[
              for (final finding in _findings(d, s)) _findingCard(finding),
              Row(
                children: [
                  Expanded(
                    child: BlockButton(
                      label: '📋 ${s.copy}',
                      outlined: true,
                      onTap: () => _copy(d),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: BlockButton(
                      label: '💬 ${s.askFollowUp}',
                      outlined: true,
                      onTap: () => _askFollowUp(d),
                    ),
                  ),
                ],
              ),
              // Room for the buttons' lip.
              const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  /// A title and a sentence for a diagnosis that could not be had.
  (String, String) _explain(AiFailure failure) {
    final s = _s;
    return switch (failure.kind) {
      AiFailureKind.notSetUp => (s.cropDoctorNotSetUp, s.notSetUpBody),
      AiFailureKind.offline => (s.noConnectionTitle, s.noConnectionBody),
      AiFailureKind.other => (
          s.diagnosisFailed,
          // The server explains itself in English only.
          s.isUrdu
              ? s.somethingWentWrong
              : failure.serverMessage ?? s.somethingWentWrong
        ),
    };
  }

  /// One card of the diagnosis: white, with the design's gold edge on the
  /// side the text starts from. It rises into place as it appears.
  Widget _findingCard(_Finding finding) {
    final percent = finding.percent;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        // The gold shows only as a strip, beside the white box laid over it.
        decoration: BoxDecoration(
          color: _c.gold,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x144A2F1B), blurRadius: 20, offset: Offset(0, 6)),
          ],
        ),
        child: Container(
          margin: const EdgeInsetsDirectional.only(start: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _c.card,
            border: Border.all(color: _c.line),
            borderRadius: const BorderRadiusDirectional.horizontal(
              start: Radius.circular(12),
              end: Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${finding.emoji} ${finding.title}',
                style: TextStyle(
                    color: _c.green,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                finding.body,
                style: TextStyle(color: _c.ink, fontSize: 15, height: 1.7),
              ),
              if (percent != null) _confidenceBar(percent),
            ],
          ),
        ),
      ),
    );
  }

  /// How sure the diagnosis is, as a bar that fills from amber to green.
  Widget _confidenceBar(int percent) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: 9,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _c.line,
        borderRadius: BorderRadius.circular(9),
      ),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: percent.clamp(0, 100) / 100,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            gradient: const LinearGradient(
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
              colors: [Color(0xFFE0A21B), Color(0xFF2F7A3F)],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------- recent scans

  Widget _recentScans() {
    final scans = _history?.recent ?? const <ScanRecord>[];
    if (scans.isEmpty) return const SizedBox.shrink();
    final s = _s;
    final cropNames = {for (final (value, name) in s.doctorCrops) value: name};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(s.recentScans),
        for (final scan in scans)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _c.card,
              border: Border.all(color: _c.line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('\u{1FA7A}', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: cropNames[scan.crop] ??
                              (scan.crop.isEmpty ? s.cropFallback : scan.crop),
                          style: TextStyle(
                              color: _c.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 16),
                          children: [
                            TextSpan(
                              text: '  ${s.data(_date(scan.at))}',
                              style: TextStyle(
                                  color: _c.muted,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (scan.summary.isNotEmpty)
                        Text(
                          scan.summary,
                          style: TextStyle(
                              color: _c.muted, fontSize: 13, height: 1.4),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _date(DateTime at) => '${at.day}/${at.month}/${at.year}';
}

/// The green line that sweeps down a photo while it is being read.
class _ScanLine extends StatelessWidget {
  const _ScanLine();

  static const _glow = Color(0xFF7CFC9A);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x007CFC9A), _glow, Color(0x007CFC9A)],
        ),
        boxShadow: [BoxShadow(color: _glow, blurRadius: 12)],
      ),
    );
  }
}

/// A thin dashed line round a photo slot, with rounded corners.
class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});

  final Color color;

  static const double _radius = 14;
  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(0.5),
        const Radius.circular(_radius),
      ));
    for (final metric in outline.computeMetrics()) {
      for (var at = 0.0; at < metric.length; at += _dash + _gap) {
        canvas.drawPath(
          metric.extractPath(at, math.min(at + _dash, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
