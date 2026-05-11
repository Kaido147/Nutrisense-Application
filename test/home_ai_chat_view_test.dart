import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrisense/pages/home_ai_chat_view.dart';
import 'package:nutrisense/providers/firebase_providers.dart';
import 'package:nutrisense/services/groq_ai_service.dart';

void main() {
  testWidgets('AI chat shows greeting, input, send, and disclaimer', (
    tester,
  ) async {
    await tester.pumpWidget(
      _chatTestApp(
        GroqAiService(
          apiKey: 'test-key',
          client: MockClient((_) async => http.Response('{}', 200)),
        ),
      ),
    );

    expect(find.textContaining("Hello! I'm here to help"), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('Send message'), findsOneWidget);
    expect(
      find.text('AI responses may occasionally be inaccurate.'),
      findsOneWidget,
    );
  });

  testWidgets('empty input does not send a message', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      _chatTestApp(
        GroqAiService(
          apiKey: 'test-key',
          client: MockClient((_) async {
            calls++;
            return http.Response('{}', 200);
          }),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();

    expect(calls, 0);
    expect(find.text('You'), findsNothing);
  });

  testWidgets('sending shows loading state and prevents duplicate sends', (
    tester,
  ) async {
    final completer = Completer<http.Response>();
    var calls = 0;

    await tester.pumpWidget(
      _chatTestApp(
        GroqAiService(
          apiKey: 'test-key',
          client: MockClient((_) {
            calls++;
            return completer.future;
          }),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'I need a reset.');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();

    expect(calls, 1);
    expect(find.text('You'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);

    completer.complete(
      http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {'content': 'Try a ten-minute walk and water.'},
            },
          ],
        }),
        200,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Try a ten-minute walk and water.'), findsOneWidget);
  });
}

Widget _chatTestApp(GroqAiService service) {
  return ProviderScope(
    overrides: [groqAiServiceProvider.overrideWithValue(service)],
    child: const MaterialApp(
      home: Scaffold(body: SizedBox(height: 700, child: HomeAiChatView())),
    ),
  );
}
