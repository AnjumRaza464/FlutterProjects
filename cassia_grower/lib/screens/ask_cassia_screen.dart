import 'package:material_ui/material_ui.dart';

import '../l10n/app_strings.dart';
import '../models/chat_message.dart';
import '../models/product.dart';
import '../services/ai_failure.dart';
import '../services/ask_cassia_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_palette.dart';
import '../widgets/language_toggle.dart';

/// Ask Cassia AI — the farming chat assistant.
///
/// Laid out as in the approved design: the page name and a line of help, a
/// row of ready-made questions, the chat (opening with Cassia's greeting),
/// and the question box with its green send button at the bottom.
///
/// Answers farming and variety questions through the `askCassia` Cloud
/// Function (the API key stays server-side). When opened from a product page
/// it receives that [product], so the farmer's questions are about that
/// variety — including varieties that are not yet available to order: the
/// chat still works for those, but it never offers them for sale.
///
/// Answers come in the app's current language.
class AskCassiaScreen extends StatefulWidget {
  const AskCassiaScreen({
    super.key,
    this.product,
    this.service,
    this.embedded = false,
    this.initialQuestion,
    this.initialMessages = const [],
  });

  final Product? product;

  /// A conversation to open with, as when Crop Doctor's "Ask follow-up"
  /// hands over a diagnosis: the farmer then types their question about it.
  final List<ChatMessage> initialMessages;

  /// True when shown as a tab under the app's shared header: the screen then
  /// has no bar of its own and shows its name as a page title instead.
  final bool embedded;

  /// A question to ask straight away, as when the chat is opened from one of
  /// Home's "Common Problems".
  final String? initialQuestion;

  /// Replaceable in tests; defaults to the real Cloud Function client.
  final AskCassiaService? service;

  @override
  State<AskCassiaScreen> createState() => _AskCassiaScreenState();
}

class _AskCassiaScreenState extends State<AskCassiaScreen> {
  late final AskCassiaService _service = widget.service ?? AskCassiaService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _sending = false;
  AiFailure? _failure;

  AppPalette get _c => context.colors;
  AppStrings get _s => context.s;

  /// The green behind white text — the farmer's own messages and the send
  /// button. The same in both themes, as in the design.
  static const _solidGreen = AppColors.greenLight;

  @override
  void initState() {
    super.initState();
    _messages.addAll(widget.initialMessages);
    final first = widget.initialQuestion;
    if (first != null) {
      // After the first frame, so the language is known when it is sent.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _send(first);
      });
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Sends [preset] (a tapped suggestion) or whatever is typed in the box.
  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    if (preset == null) _input.clear();
    setState(() => _messages.add(ChatMessage.user(text)));
    await _requestReply();
  }

  /// Asks for a reply to the conversation so far. Also used by "Try again",
  /// which is why it doesn't add a message itself.
  Future<void> _requestReply() async {
    setState(() {
      _sending = true;
      _failure = null;
    });
    _scrollToEnd();
    try {
      final reply = await _service.ask(
        List.of(_messages),
        language: _s.languageCode,
        product: widget.product,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage.assistant(reply));
        _sending = false;
      });
    } on AiFailure catch (e) {
      _fail(e);
    } catch (_) {
      _fail(const AiFailure(AiFailureKind.other));
    }
    _scrollToEnd();
  }

  void _fail(AiFailure failure) {
    if (!mounted) return;
    setState(() {
      _failure = failure;
      _sending = false;
    });
  }

  void _newChat() {
    setState(() {
      _messages.clear();
      _failure = null;
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final about = widget.product;
    // A reply that is still on its way belongs to this chat, so wait for
    // it before starting over.
    final newChat = _messages.isEmpty
        ? null
        : IconButton(
            onPressed: _sending ? null : _newChat,
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: _s.newChat,
            color: widget.embedded ? _c.green : null,
            // Beside the page title it is a little smaller than in a bar.
            padding: widget.embedded ? EdgeInsets.zero : null,
            constraints: widget.embedded
                ? const BoxConstraints.tightFor(width: 40, height: 40)
                : null,
          );

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: Text(_s.askCassiaAi),
              actions: [
                ?newChat,
                const LanguageToggle(),
                const SizedBox(width: 4),
              ],
            ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (about != null) _productBanner(about),
          Expanded(child: _page(about, newChat)),
          _inputBar(),
        ],
      ),
    );
  }

  /// Everything above the question box. It scrolls as one page, so on a
  /// small phone a long chat can use the whole screen.
  Widget _page(Product? about, Widget? newChat) {
    final intro = about != null ? _s.askVarietyIntro : _s.askGeneralIntro;
    final suggestions =
        about != null ? _s.varietySuggestions : _s.generalSuggestions;
    final welcome =
        about != null ? _s.cassiaWelcomeAbout(about.name) : _s.cassiaWelcome;

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, widget.embedded ? 8 : 14, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The page name, as on the other tabs. Its row keeps one
              // height, so nothing moves when "New chat" appears beside it.
              if (widget.embedded)
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '\u{1F4AC} ${_s.askCassia}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _c.ink),
                        ),
                      ),
                      ?newChat,
                    ],
                  ),
                ),
              Text(intro, style: TextStyle(color: _c.muted, fontSize: 14)),
            ],
          ),
        ),
        _suggestionRow(suggestions),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _cassiaBubble(_message(welcome, rtl: _s.isUrdu)),
              for (final m in _messages)
                m.isUser
                    ? _userBubble(m)
                    : _cassiaBubble(_message(m.text, rtl: m.isRtl)),
              if (_sending) _thinkingBubble(),
              if (_failure != null) _errorCard(_failure!),
              if (_messages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _s.aiDisclaimer,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: _c.muted, fontSize: 11, height: 1.4),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------ product banner

  /// Shows which variety the chat is about. A not-available variety keeps its
  /// "Not available yet" label here too, so it never looks like it's on sale.
  Widget _productBanner(Product p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _c.green.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(Icons.grass, size: 16, color: _c.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _s.askingAbout(p.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: _c.green, fontWeight: FontWeight.w700),
            ),
          ),
          if (!p.available) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _c.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: _c.gold),
              ),
              child: Text(
                _s.notAvailableYet,
                style: TextStyle(
                    color: _c.goldInk,
                    fontWeight: FontWeight.w800,
                    fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------- suggestions

  /// The ready-made questions: one row of pills that scrolls sideways.
  Widget _suggestionRow(List<AskSuggestion> suggestions) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Room underneath for the pills' lip.
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 14),
      child: Row(
        children: [for (final s in suggestions) _suggestion(s)],
      ),
    );
  }

  /// A raised pill with a short label; tapping it asks the full question.
  Widget _suggestion(AskSuggestion suggestion) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _c.card,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: _c.line),
          boxShadow: [BoxShadow(color: _c.line, offset: const Offset(0, 3))],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _send(suggestion.question),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: Text(
                suggestion.label,
                style: TextStyle(color: _c.ink, fontSize: 13),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- messages

  /// The text of a message. Each one reads in its own direction, whatever
  /// the app's; Urdu is set a little larger, as in the design.
  Widget _message(String text, {required bool rtl, Color? color}) {
    return Text(
      text,
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      style: TextStyle(
        color: color ?? _c.ink,
        height: 1.65,
        fontSize: rtl ? 17 : 15,
      ),
    );
  }

  /// A chat bubble no wider than most of the line, with one tight corner
  /// pointing at whoever is speaking: the farmer's sit at the end of the line
  /// (right in English, left in Urdu), Cassia's at the start.
  Widget _bubble({required bool mine, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(
        builder: (context, box) => Align(
          alignment: mine
              ? AlignmentDirectional.centerEnd
              : AlignmentDirectional.centerStart,
          child: Container(
            constraints: BoxConstraints(maxWidth: box.maxWidth * 0.86),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: mine ? _solidGreen : _c.card,
              border: mine ? null : Border.all(color: _c.line),
              borderRadius: BorderRadiusDirectional.only(
                topStart: const Radius.circular(18),
                topEnd: const Radius.circular(18),
                bottomStart: Radius.circular(mine ? 18 : 4),
                bottomEnd: Radius.circular(mine ? 4 : 18),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _userBubble(ChatMessage m) {
    return _bubble(
      mine: true,
      child: _message(m.text, rtl: m.isRtl, color: Colors.white),
    );
  }

  /// One of Cassia's bubbles, signed with her name as in the design.
  Widget _cassiaBubble(Widget child) {
    return _bubble(
      mine: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '\u{1F331} ${_s.cassiaName}',
              style: TextStyle(
                  color: _c.green, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _thinkingBubble() {
    return _cassiaBubble(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text(_s.thinking, style: TextStyle(color: _c.muted)),
        ],
      ),
    );
  }

  Widget _errorCard(AiFailure failure) {
    final (IconData icon, String title, String body) = switch (failure.kind) {
      AiFailureKind.notSetUp => (
          Icons.cloud_off,
          _s.askCassiaNotSetUp,
          _s.notSetUpBody
        ),
      AiFailureKind.offline => (
          Icons.wifi_off,
          _s.noConnectionTitle,
          _s.noConnectionBody
        ),
      AiFailureKind.other => (
          Icons.error_outline,
          _s.couldNotGetAnswer,
          // The server explains itself in English only.
          _s.isUrdu
              ? _s.somethingWentWrong
              : failure.serverMessage ?? _s.somethingWentWrong
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 8, 6),
      decoration: BoxDecoration(
        color: _c.card,
        border: Border.all(color: _c.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _c.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style:
                      TextStyle(fontWeight: FontWeight.w800, color: _c.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(color: _c.muted, height: 1.4)),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: _requestReply,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(_s.tryAgain),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- input

  /// The question box and, beside it, the green send button — the same
  /// height as the box, however many lines have been typed.
  Widget _inputBar() {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  // A chat opened on a diagnosis is waiting for a question.
                  autofocus: widget.initialMessages.isNotEmpty,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: TextStyle(color: _c.ink, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: _s.typeYourQuestion,
                    hintStyle: TextStyle(color: _c.muted, fontSize: 15),
                    counterText: '', // hide the 0/1000 counter
                    isDense: true,
                    filled: true,
                    fillColor: _c.card,
                    contentPadding: const EdgeInsets.all(13),
                    border: border(_c.line),
                    enabledBorder: border(_c.line),
                    focusedBorder: border(_solidGreen, 1.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: _s.send,
                child: Material(
                  color: _sending
                      ? _solidGreen.withValues(alpha: 0.5)
                      : _solidGreen,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _sending ? null : () => _send(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 17),
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
