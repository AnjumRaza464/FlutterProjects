// Tests for the Crop Doctor page, driven by a fake service (so no camera and
// no Firebase are needed).

import 'dart:convert';

import 'package:cassia_grower/data/local_store.dart';
import 'package:cassia_grower/data/scan_history.dart';
import 'package:cassia_grower/models/crop_diagnosis.dart';
import 'package:cassia_grower/models/crop_photo.dart';
import 'package:cassia_grower/screens/ask_cassia_screen.dart';
import 'package:cassia_grower/screens/crop_doctor_screen.dart';
import 'package:cassia_grower/services/ai_failure.dart';
import 'package:cassia_grower/services/crop_doctor_service.dart';
import 'package:cassia_grower/state/app_settings.dart';
import 'package:cassia_grower/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

/// A 1×1 PNG, standing in for a photo the farmer takes.
final _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
    '60e6kgAAAABJRU5ErkJggg==');

const _blight = CropDiagnosis(
  isPlant: true,
  cropGuess: 'Tomato',
  observed: 'Brown rings on the lower leaves.',
  problem: 'Early blight',
  confidencePercent: 70,
  reason: 'Target-like spots are typical of it.',
  alternatives: ['Septoria leaf spot: smaller spots with pale centres.'],
  cause: 'A fungus that spreads in warm, wet weather.',
  treatment: ['Remove affected leaves', 'Ask a dealer for a fungicide'],
  prevention: ['Water at the base of the plant'],
  summary: 'Brown spots point to early blight.',
);

/// What one tap on "Diagnose My Crop" sent.
typedef _Request = ({
  int photos,
  String language,
  String crop,
  String stage,
  String days,
  String notes,
});

/// "Takes" photos at once and records what is sent for diagnosis.
class _FakeDoctor extends CropDoctorService {
  _FakeDoctor({this.answer = _blight, this.failure});

  final CropDiagnosis answer;
  final AiFailure? failure;

  final List<_Request> requests = [];

  /// How many photos the gallery was asked for, each time it was opened.
  final List<int> galleryLimits = [];

  @override
  Future<XFile?> pickImage(ImageSource source) async =>
      XFile.fromData(_png, name: 'leaf.png');

  @override
  Future<List<XFile>> pickFromGallery(int limit) async {
    galleryLimits.add(limit);
    return [
      for (var i = 0; i < limit; i++) XFile.fromData(_png, name: 'leaf$i.png'),
    ];
  }

  @override
  Future<CropDiagnosis> diagnose(
    List<CropPhoto> photos, {
    String language = 'en',
    String crop = '',
    String stage = '',
    String days = '',
    String notes = '',
  }) async {
    requests.add((
      photos: photos.length,
      language: language,
      crop: crop,
      stage: stage,
      days: days,
      notes: notes,
    ));
    if (failure != null) throw failure!;
    return answer;
  }
}

Future<void> _open(
  WidgetTester tester,
  _FakeDoctor doctor, {
  AppLanguage language = AppLanguage.en,
  ScanHistory? history,
}) async {
  // Tall enough to show the whole page, diagnosis included.
  await tester.binding.setSurfaceSize(const Size(480, 2800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final settings = AppSettings()..setLanguage(language);
  final urdu = language == AppLanguage.ur;
  await tester.pumpWidget(AppSettingsScope(
    settings: settings,
    child: MaterialApp(
      locale: settings.language.materialLocale,
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildAppTheme(Brightness.light, cursive: urdu),
      home: CropDoctorScreen(
        service: doctor,
        history: history ?? ScanHistory(),
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

Future<void> _takePhoto(WidgetTester tester) => _tap(tester, '📷 Take Photo');

Future<void> _diagnose(WidgetTester tester) =>
    _tap(tester, '🔍 Diagnose My Crop');

void main() {
  testWidgets('the page is laid out as in the design', (tester) async {
    await _open(tester, _FakeDoctor());

    expect(find.text('\u{1FA7A} Crop Doctor'), findsOneWidget);
    for (final step in ['Photos', 'Details', 'Diagnosis']) {
      expect(find.text(step), findsOneWidget);
    }
    expect(find.text('🍅 Tomato'), findsOneWidget);
    expect(find.text('Which crop?'), findsOneWidget);
    expect(find.text('Growth stage?'), findsOneWidget);
    expect(find.text('Since how many days? (optional)'), findsOneWidget);
    expect(find.text('Recent sprays, irrigation, weather… (optional)'),
        findsOneWidget);
    for (final slot in ['Affected leaf', 'Underside', 'Whole plant']) {
      expect(find.text(slot), findsOneWidget);
    }
    expect(find.text('📷 Take Photo'), findsOneWidget);
    expect(find.text('🖼️ Choose from Gallery'), findsOneWidget);
    expect(find.text('🔍 Diagnose My Crop'), findsOneWidget);
    expect(find.textContaining('AI advice is a guide, not a lab test.'),
        findsOneWidget);
    // Nothing has been scanned yet.
    expect(find.text('Recent scans'), findsNothing);
  });

  testWidgets('Diagnose My Crop waits for a photo', (tester) async {
    final doctor = _FakeDoctor();
    await _open(tester, doctor);

    await _diagnose(tester);
    expect(doctor.requests, isEmpty);

    await _takePhoto(tester);
    await _diagnose(tester);
    expect(doctor.requests, hasLength(1));
  });

  testWidgets('the photo goes with the details the farmer filled in',
      (tester) async {
    final doctor = _FakeDoctor();
    await _open(tester, doctor);

    await _tap(tester, '🌿 Okra');
    // The chip fills in the "Which crop?" list.
    expect(find.text('Which crop?'), findsNothing);
    expect(find.text('Okra'), findsOneWidget);

    await _tap(tester, 'Growth stage?');
    await tester.tap(find.text('Flowering').last);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextField, 'Since how many days? (optional)'),
        '5');
    await tester.enterText(
        find.widgetWithText(
            TextField, 'Recent sprays, irrigation, weather… (optional)'),
        '  Sprayed last week ');

    await _takePhoto(tester);
    await _diagnose(tester);

    expect(doctor.requests.single, (
      photos: 1,
      language: 'en',
      crop: 'Okra',
      stage: 'Flowering',
      days: '5',
      notes: '  Sprayed last week ',
    ));
  });

  testWidgets('the details are optional', (tester) async {
    final doctor = _FakeDoctor();
    await _open(tester, doctor);

    await _takePhoto(tester);
    await _diagnose(tester);

    expect(doctor.requests.single, (
      photos: 1,
      language: 'en',
      crop: '',
      stage: '',
      days: '',
      notes: '',
    ));
  });

  testWidgets('a crop can be chosen from the list, and un-chosen',
      (tester) async {
    final doctor = _FakeDoctor();
    await _open(tester, doctor);

    await _tap(tester, 'Which crop?');
    await tester.tap(find.text('Paddy / Rice').last);
    await tester.pumpAndSettle();
    await _takePhoto(tester);
    await _diagnose(tester);
    expect(doctor.requests.last.crop, 'Paddy / Rice');

    await _tap(tester, 'Paddy / Rice');
    await tester.tap(find.text('Which crop?').last);
    await tester.pumpAndSettle();
    await _diagnose(tester);
    expect(doctor.requests.last.crop, '');
  });

  testWidgets('the days box takes digits only', (tester) async {
    final doctor = _FakeDoctor();
    await _open(tester, doctor);

    await tester.enterText(
        find.widgetWithText(TextField, 'Since how many days? (optional)'),
        'about 12 days');
    await _takePhoto(tester);
    await _diagnose(tester);

    expect(doctor.requests.single.days, '12');
  });

  testWidgets('the diagnosis is shown as the design\'s cards', (tester) async {
    await _open(tester, _FakeDoctor());
    await _takePhoto(tester);
    await _diagnose(tester);

    expect(find.text('👁️ What I see'), findsOneWidget);
    expect(find.text('Brown rings on the lower leaves.'), findsOneWidget);
    expect(find.text('🎯 Most likely problem'), findsOneWidget);
    expect(
        find.text('Early blight\nConfidence: 70%\n'
            'Target-like spots are typical of it.'),
        findsOneWidget);
    expect(find.text('🔀 Other possibilities'), findsOneWidget);
    expect(find.text('🧪 What is lacking / the cause'), findsOneWidget);
    expect(find.text('💊 Treatment steps'), findsOneWidget);
    expect(
        find.text('1. Remove affected leaves\n'
            '2. Ask a dealer for a fungicide'),
        findsOneWidget);
    expect(find.text('🛡️ Prevention for next time'), findsOneWidget);
    // The photos were clear, so no extra photo is asked for.
    expect(find.text('📸 For a surer diagnosis'), findsNothing);
    expect(find.text('📋 Copy'), findsOneWidget);
    expect(find.text('💬 Ask follow-up'), findsOneWidget);
  });

  testWidgets('the gallery fills the empty slots — three photos at most',
      (tester) async {
    final doctor = _FakeDoctor();
    await _open(tester, doctor);

    await _takePhoto(tester);
    expect(find.text('Affected leaf'), findsNothing);
    expect(find.text('Underside'), findsOneWidget);

    await _tap(tester, '🖼️ Choose from Gallery');
    expect(doctor.galleryLimits, [2]); // only the two empty slots
    expect(find.text('Underside'), findsNothing);
    expect(find.text('Whole plant'), findsNothing);
    expect(find.byTooltip('Remove photo'), findsNWidgets(3));

    // A fourth photo is turned away.
    await _takePhoto(tester);
    expect(find.text('You can add up to 3 photos.'), findsOneWidget);
    expect(find.byTooltip('Remove photo'), findsNWidgets(3));

    await _diagnose(tester);
    expect(doctor.requests.single.photos, 3);
  });

  testWidgets('a photo can be removed again', (tester) async {
    final doctor = _FakeDoctor();
    await _open(tester, doctor);
    await _takePhoto(tester);

    await tester.tap(find.byTooltip('Remove photo'));
    await tester.pumpAndSettle();

    expect(find.text('Affected leaf'), findsOneWidget);
    await _diagnose(tester);
    expect(doctor.requests, isEmpty); // no photo, so nothing to diagnose
  });

  testWidgets('tapping an empty slot takes a photo for it', (tester) async {
    await _open(tester, _FakeDoctor());

    await _tap(tester, 'Underside');

    expect(find.byTooltip('Remove photo'), findsOneWidget);
  });

  testWidgets('a scan is listed under Recent scans, and kept', (tester) async {
    final store = MemoryStore();
    await _open(tester, _FakeDoctor(), history: ScanHistory(store: store));
    await _tap(tester, '🍅 Tomato');
    await _takePhoto(tester);
    await _diagnose(tester);

    expect(find.text('Recent scans'), findsOneWidget);
    expect(find.text('Brown spots point to early blight.'), findsOneWidget);

    // Opened afresh, the page still lists it.
    await tester.pumpWidget(const SizedBox());
    await _open(tester, _FakeDoctor(), history: ScanHistory(store: store));
    expect(find.text('Recent scans'), findsOneWidget);
    expect(find.text('Brown spots point to early blight.'), findsOneWidget);
  });

  testWidgets('Copy puts the whole diagnosis on the clipboard',
      (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await _open(tester, _FakeDoctor());
    await _takePhoto(tester);
    await _diagnose(tester);
    await _tap(tester, '📋 Copy');

    expect(copied, startsWith('1) What I see:\nBrown rings'));
    expect(copied, contains('2) Most likely problem:\nEarly blight'));
    expect(copied, contains('5) Treatment steps:\n1. Remove affected leaves'));
    expect(find.text('Diagnosis copied'), findsOneWidget);
  });

  testWidgets('Ask follow-up opens Ask Cassia on the diagnosis',
      (tester) async {
    await _open(tester, _FakeDoctor());
    await _takePhoto(tester);
    await _diagnose(tester);

    await _tap(tester, '💬 Ask follow-up');

    final chat =
        tester.widget<AskCassiaScreen>(find.byType(AskCassiaScreen));
    expect(chat.initialMessages, hasLength(2));
    expect(chat.initialMessages.first.isUser, isTrue);
    expect(
        chat.initialMessages.first.text,
        startsWith('My crop diagnosis from Crop Doctor:\n'
            '1) What I see:\nBrown rings'));
    expect(chat.initialMessages.last.text,
        'Understood. What would you like to know?');
  });

  testWidgets('a photo that is not a crop gets one card, and is not kept',
      (tester) async {
    const notACrop = CropDiagnosis(
      isPlant: false,
      summary: 'This looks like a bicycle, not a plant.',
    );
    await _open(tester, _FakeDoctor(answer: notACrop));
    await _takePhoto(tester);
    await _diagnose(tester);

    expect(find.text('🚫 That doesn\'t look like a crop'), findsOneWidget);
    expect(find.text('This looks like a bicycle, not a plant.'),
        findsOneWidget);
    expect(find.text('🎯 Most likely problem'), findsNothing);
    expect(find.text('📋 Copy'), findsNothing);
    expect(find.text('Recent scans'), findsNothing);
  });

  testWidgets('when Crop Doctor is not switched on, the page says so',
      (tester) async {
    final doctor =
        _FakeDoctor(failure: const AiFailure(AiFailureKind.notSetUp));
    await _open(tester, doctor);
    await _takePhoto(tester);
    await _diagnose(tester);

    expect(find.text('⚠️ Crop Doctor not set up yet'), findsOneWidget);
    expect(find.text('Recent scans'), findsNothing);

    // The photo is still there, so the farmer can simply try again.
    await _diagnose(tester);
    expect(doctor.requests, hasLength(2));
  });

  testWidgets('in Urdu the page is in Urdu, and so is the diagnosis asked for',
      (tester) async {
    final doctor = _FakeDoctor();
    await _open(tester, doctor, language: AppLanguage.ur);

    expect(find.text('کون سی فصل؟'), findsOneWidget);
    expect(find.text('Which crop?'), findsNothing);
    expect(find.text('متاثرہ پتا'), findsOneWidget);

    await _tap(tester, '🍅 ٹماٹر');
    await _tap(tester, '📷 تصویر کھینچیں');
    await _tap(tester, '🔍 میری فصل کی تشخیص کریں');

    // The crop is sent by its English name whatever the language.
    expect(doctor.requests.single.crop, 'Tomato');
    expect(doctor.requests.single.language, 'ur');
    expect(find.text('🎯 سب سے ممکنہ مسئلہ'), findsOneWidget);
  });

  group('CropDiagnosis.fromMap', () {
    test('reads every part of the server\'s answer', () {
      final d = CropDiagnosis.fromMap({
        'isPlant': true,
        'cropGuess': 'Okra',
        'healthy': false,
        'observed': ' Yellow veins ',
        'problem': 'Yellow vein mosaic',
        'confidencePercent': 82.4,
        'reason': 'Vein clearing is typical.',
        'alternatives': ['Iron deficiency', '', 'Mites', 'A third one'],
        'cause': 'A virus carried by whitefly.',
        'treatment': ['Remove infected plants'],
        'prevention': ['Control whitefly early'],
        'needMore': '',
        'summary': 'Likely yellow vein mosaic.',
      });

      expect(d.isPlant, isTrue);
      expect(d.observed, 'Yellow veins');
      expect(d.confidencePercent, 82);
      expect(d.alternatives, ['Iron deficiency', 'Mites']); // two at most
      expect(d.cause, 'A virus carried by whitefly.');
      expect(d.treatment, ['Remove infected plants']);
    });

    test('copes with missing and odd values', () {
      final d = CropDiagnosis.fromMap({
        'isPlant': 'yes',
        'confidencePercent': 250,
        'treatment': 'spray',
      });

      expect(d.isPlant, isFalse);
      expect(d.confidencePercent, 100);
      expect(d.treatment, isEmpty);
      expect(d.problem, '');
    });

    test('still reads an older server\'s answer', () {
      final d = CropDiagnosis.fromMap({
        'isPlant': true,
        'deficiency': 'Nitrogen',
        'confidence': 'high',
      });

      expect(d.cause, 'Nitrogen');
      expect(d.confidencePercent, 85);
    });
  });

  test('the request carries up to three photos and the details', () {
    final photo = CropPhoto(bytes: _png, mimeType: 'image/png');
    final payload = CropDoctorService.buildPayload(
      [photo, photo, photo, photo],
      language: 'ur',
      crop: ' Okra ',
      stage: 'Fruiting',
      days: '3',
      notes: 'Rain',
    );

    final images = payload['images'] as List;
    expect(images, hasLength(3));
    expect(images.first, {'base64': base64Encode(_png), 'mimeType': 'image/png'});
    expect(payload['language'], 'ur');
    expect(payload['crop'], 'Okra');
    expect(payload['stage'], 'Fruiting');
    expect(payload['days'], '3');
    expect(payload['notes'], 'Rain');
  });

  test('only the last five scans are kept, newest first', () async {
    final history = ScanHistory(store: MemoryStore());
    for (var i = 1; i <= 7; i++) {
      await history.add(crop: 'Okra', summary: 'Scan $i');
    }

    expect(history.recent.map((r) => r.summary),
        ['Scan 7', 'Scan 6', 'Scan 5', 'Scan 4', 'Scan 3']);

    // A long one is cut short, and says so.
    await history.add(crop: '', summary: 'x' * 200);
    expect(history.recent.first.summary, '${'x' * 90}…');
  });
}
