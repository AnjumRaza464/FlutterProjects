// Tests for Ask Cassia: the request the app sends to the Cloud Function, and
// the chat screen driven by a fake service (so no Firebase is needed).

import 'package:cassia_grower/main.dart';
import 'package:cassia_grower/models/chat_message.dart';
import 'package:cassia_grower/models/product.dart';
import 'package:cassia_grower/screens/ask_cassia_screen.dart';
import 'package:cassia_grower/services/ai_failure.dart';
import 'package:cassia_grower/services/ask_cassia_service.dart';
import 'package:cassia_grower/state/app_settings.dart';
import 'package:cassia_grower/state/cart_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Records what the screen asks for and answers (or fails) on demand.
class _FakeService extends AskCassiaService {
  final List<List<ChatMessage>> histories = [];
  String? language;
  Product? product;
  AiFailure? failWith;

  @override
  Future<String> ask(
    List<ChatMessage> history, {
    String language = 'en',
    Product? product,
  }) async {
    histories.add(history);
    this.language = language;
    this.product = product;
    final failure = failWith;
    if (failure != null) throw failure;
    return 'Sow in early spring.';
  }
}

const _notAvailable = Product(
  id: 'soon',
  name: 'Soon F1',
  crop: 'Tomato',
  cropKey: 'tomato',
  available: false,
);

Future<void> _ask(WidgetTester tester, String question) async {
  await tester.enterText(find.byType(TextField), question);
  await tester.tap(find.byIcon(Icons.send));
  await tester.pumpAndSettle();
}

void main() {
  group('AskCassiaService.buildPayload', () {
    test('sends each message with its role and text', () {
      final payload = AskCassiaService.buildPayload(const [
        ChatMessage.user('Hello'),
        ChatMessage.assistant('Hi'),
        ChatMessage.user('When to sow?'),
      ]);

      expect(payload['messages'], [
        {'role': 'user', 'text': 'Hello'},
        {'role': 'assistant', 'text': 'Hi'},
        {'role': 'user', 'text': 'When to sow?'},
      ]);
      expect(payload['language'], 'en');
      expect(payload.containsKey('product'), isFalse);
    });

    test('keeps only the most recent messages, ending with the latest', () {
      final history = [
        for (var i = 0; i < 30; i++) ChatMessage.user('q$i'),
      ];

      final messages =
          AskCassiaService.buildPayload(history)['messages'] as List;

      expect(messages, hasLength(AskCassiaService.maxHistory));
      expect((messages.last as Map)['text'], 'q29');
    });

    test('identifies the product but does not send its availability', () {
      final payload = AskCassiaService.buildPayload(
        const [ChatMessage.user('Tell me more')],
        language: 'ur',
        product: _notAvailable,
      );

      expect(payload['language'], 'ur');
      expect(payload['product'],
          {'id': 'soon', 'name': 'Soon F1', 'crop': 'Tomato'});
    });
  });

  group('ChatMessage.isRtl', () {
    test('Urdu is right-to-left, English is not', () {
      expect(const ChatMessage.user('کاشت کب کریں؟').isRtl, isTrue);
      expect(const ChatMessage.user('When should I sow?').isRtl, isFalse);
    });

    test('one foreign word does not flip the direction', () {
      expect(
          const ChatMessage.assistant('ٹماٹر کی قسم Redo بہت اچھی ہے').isRtl,
          isTrue);
      expect(
          const ChatMessage.assistant('Tomato is called ٹماٹر in Urdu').isRtl,
          isFalse);
    });
  });

  group('AskCassiaScreen', () {
    testWidgets('a typed question and its answer both appear', (tester) async {
      final service = _FakeService();
      await tester
          .pumpWidget(MaterialApp(home: AskCassiaScreen(service: service)));

      await _ask(tester, 'When should I sow okra?');

      expect(find.text('When should I sow okra?'), findsOneWidget);
      expect(find.text('Sow in early spring.'), findsOneWidget);
      expect(service.histories.single.single.text, 'When should I sow okra?');
      expect(service.language, 'en');
    });

    testWidgets('a follow-up is sent with the earlier conversation',
        (tester) async {
      final service = _FakeService();
      await tester
          .pumpWidget(MaterialApp(home: AskCassiaScreen(service: service)));

      await _ask(tester, 'First question');
      await _ask(tester, 'Second question');

      expect(service.histories.last.map((m) => m.text), [
        'First question',
        'Sow in early spring.',
        'Second question',
      ]);
    });

    testWidgets('opens with Cassia\'s greeting and the ready-made questions',
        (tester) async {
      final service = _FakeService();
      await tester.pumpWidget(MaterialApp(
        home: AskCassiaScreen(service: service, embedded: true),
      ));

      expect(find.text('\u{1F4AC} Ask Cassia'), findsOneWidget);
      expect(
          find.text('Ask about sowing time, spacing, fertiliser, irrigation, '
              'pests, or our seeds.'),
          findsOneWidget);
      expect(find.text('Okra sowing time'), findsOneWidget);
      expect(find.text('Tomato cracking'), findsOneWidget);
      expect(find.text('Chilli leaf curl'), findsOneWidget);
      expect(
          find.text('Assalam o Alaikum! I am Cassia \u{1F331} Ask me anything '
              'about your crop.'),
          findsOneWidget);
      // The greeting is only shown; nothing has been asked yet.
      expect(service.histories, isEmpty);
    });

    testWidgets('tapping a suggestion asks its full question', (tester) async {
      final service = _FakeService();
      await tester
          .pumpWidget(MaterialApp(home: AskCassiaScreen(service: service)));

      await tester.tap(find.text('Okra sowing time'));
      await tester.pumpAndSettle();

      // The greeting is not part of the conversation sent to the server.
      expect(service.histories.single.single.text,
          'Best sowing time for okra in Sindh?');
      expect(find.text('Best sowing time for okra in Sindh?'), findsOneWidget);
      expect(find.text('Sow in early spring.'), findsOneWidget);
    });

    testWidgets('a chat about a variety greets with its name', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: AskCassiaScreen(product: _notAvailable, service: _FakeService()),
      ));

      expect(
          find.text('Assalam o Alaikum! I am Cassia \u{1F331} Ask me anything '
              'about Soon F1.'),
          findsOneWidget);
      expect(find.text('Sowing time'), findsOneWidget);
    });

    testWidgets('switching the app to Urdu asks for Urdu answers',
        (tester) async {
      final service = _FakeService();
      // The real app shell, so the language toggle has settings to change.
      await tester.pumpWidget(CassiaApp(
        settings: AppSettings(),
        cart: CartController(),
        home: AskCassiaScreen(service: service),
      ));

      await tester.tap(find.text('اردو'));
      await tester.pumpAndSettle();

      expect(find.text('بھنڈی کی بوائی کا وقت'), findsOneWidget);
      expect(
          find.text('السلام علیکم! میں کیسیا ہوں \u{1F331} اپنی فصل کے بارے '
              'میں کچھ بھی پوچھیں۔'),
          findsOneWidget);

      await _ask(tester, 'کاشت کب کریں؟');

      expect(service.language, 'ur');
    });

    testWidgets('a not-available variety is labelled and passed to the server',
        (tester) async {
      final service = _FakeService();
      await tester.pumpWidget(MaterialApp(
        home: AskCassiaScreen(product: _notAvailable, service: service),
      ));

      expect(find.text('Asking about Soon F1'), findsOneWidget);
      expect(find.text('Not available yet'), findsOneWidget);

      await _ask(tester, 'How do I grow it?');

      expect(service.product?.id, 'soon');
      // The label stays visible once the conversation has started.
      expect(find.text('Not available yet'), findsOneWidget);
    });

    testWidgets('a failure offers a retry that does not repeat the question',
        (tester) async {
      final service = _FakeService()
        ..failWith = const AiFailure(AiFailureKind.other,
            serverMessage: 'Server is busy.');
      await tester
          .pumpWidget(MaterialApp(home: AskCassiaScreen(service: service)));

      await _ask(tester, 'When should I sow okra?');

      expect(find.text('Could not get an answer'), findsOneWidget);
      expect(find.text('Server is busy.'), findsOneWidget);

      service.failWith = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Server is busy.'), findsNothing);
      expect(find.text('When should I sow okra?'), findsOneWidget);
      expect(find.text('Sow in early spring.'), findsOneWidget);
      expect(service.histories.last, hasLength(1));
    });

    testWidgets('an undeployed backend is explained as not set up yet',
        (tester) async {
      final service = _FakeService()
        ..failWith = const AiFailure(AiFailureKind.notSetUp);
      await tester
          .pumpWidget(MaterialApp(home: AskCassiaScreen(service: service)));

      await _ask(tester, 'Hello');

      expect(find.text('Ask Cassia not set up yet'), findsOneWidget);
    });

    testWidgets('being offline is explained as a connection problem',
        (tester) async {
      final service = _FakeService()
        ..failWith = const AiFailure(AiFailureKind.offline);
      await tester
          .pumpWidget(MaterialApp(home: AskCassiaScreen(service: service)));

      await _ask(tester, 'Hello');

      expect(find.text('No connection'), findsOneWidget);
      expect(find.text('Ask Cassia not set up yet'), findsNothing);
    });

    testWidgets('in Urdu, an English server message is not shown',
        (tester) async {
      final service = _FakeService()
        ..failWith = const AiFailure(AiFailureKind.other,
            serverMessage: 'Server is busy.');
      await tester.pumpWidget(CassiaApp(
        settings: AppSettings()..setLanguage(AppLanguage.ur),
        cart: CartController(),
        home: AskCassiaScreen(service: service),
      ));

      await _ask(tester, 'سلام');

      expect(find.text('جواب نہیں مل سکا'), findsOneWidget);
      expect(find.text('Server is busy.'), findsNothing);
    });
  });
}
