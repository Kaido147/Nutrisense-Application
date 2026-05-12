import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrisense/models/ai_user_context.dart';
import 'package:nutrisense/models/prototype_data.dart';
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
    expect(find.byTooltip('Add'), findsNothing);
    expect(_owlImageFinder(), findsOneWidget);
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

  testWidgets('initial all-loading context shows temporary loading message', (
    tester,
  ) async {
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
        contextValue: _allLoadingContext,
      ),
    );

    await tester.enterText(find.byType(TextField), 'What class is today?');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();

    expect(calls, 0);
    expect(find.textContaining('still loading'), findsOneWidget);
  });

  testWidgets('context timeout allows limited context to be sent', (
    tester,
  ) async {
    late Map<String, dynamic> requestBody;
    await tester.pumpWidget(
      _chatTestApp(
        GroqAiService(
          apiKey: 'test-key',
          client: MockClient((request) async {
            requestBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {'content': 'I can help with limited data.'},
                  },
                ],
              }),
              200,
            );
          }),
        ),
        contextValue: _allLoadingContext,
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.enterText(find.byType(TextField), 'Can you help?');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();

    expect(find.text('I can help with limited data.'), findsOneWidget);
    expect(
      (requestBody['messages'] as List)[1]['content'],
      contains('timed out while loading'),
    );
  });

  testWidgets('later real context replaces timed-out context', (tester) async {
    final requestBodies = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiUserContextProvider.overrideWith(
            (ref) => ref.watch(_testContextProvider),
          ),
          groqAiServiceProvider.overrideWithValue(
            GroqAiService(
              apiKey: 'test-key',
              client: MockClient((request) async {
                requestBodies.add(
                  jsonDecode(request.body) as Map<String, dynamic>,
                );
                return http.Response(
                  jsonEncode({
                    'choices': [
                      {
                        'message': {'content': 'Updated context used.'},
                      },
                    ],
                  }),
                  200,
                );
              }),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SizedBox(height: 700, child: HomeAiChatView())),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.enterText(find.byType(TextField), 'First');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeAiChatView)),
    );
    container.read(_testContextProvider.notifier).setContext(_realQuestContext);
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Second');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();

    expect(requestBodies, hasLength(2));
    expect(
      (requestBodies.first['messages'] as List)[1]['content'],
      contains('timed out'),
    );
    expect(
      (requestBodies.last['messages'] as List)[1]['content'],
      contains('Hydrate today'),
    );
  });
}

Widget _chatTestApp(GroqAiService service, {AiUserContext? contextValue}) {
  return ProviderScope(
    overrides: [
      groqAiServiceProvider.overrideWithValue(service),
      aiUserContextProvider.overrideWithValue(contextValue ?? _emptyContext),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SizedBox(height: 700, child: HomeAiChatView())),
    ),
  );
}

Finder _owlImageFinder() {
  return find.byWidgetPredicate((widget) {
    if (widget is! Image || widget.image is! AssetImage) return false;
    return (widget.image as AssetImage).assetName == 'assets/imgs/owl.png';
  });
}

final _emptyContext = AiUserContext(
  generatedAt: DateTime(2026, 5, 12),
  quests: const [],
  studyTasks: const [],
  schedules: const [],
  mealLogs: const [],
  workoutPlans: const [],
  workoutActivities: const [],
);

final _allLoadingContext = AiUserContext.empty(
  generatedAt: DateTime(2026, 5, 12),
  sources: const {
    'quests': AiContextSourceState(
      label: 'Daily quests',
      status: AiContextSourceStatus.loading,
    ),
    'studyTasks': AiContextSourceState(
      label: 'Study tasks',
      status: AiContextSourceStatus.loading,
    ),
    'schedules': AiContextSourceState(
      label: 'Class schedule',
      status: AiContextSourceStatus.loading,
    ),
    'mealLogs': AiContextSourceState(
      label: 'Meal logs',
      status: AiContextSourceStatus.loading,
    ),
    'workoutPlans': AiContextSourceState(
      label: 'Workout plans',
      status: AiContextSourceStatus.loading,
    ),
    'workoutActivities': AiContextSourceState(
      label: 'Workout history',
      status: AiContextSourceStatus.loading,
    ),
  },
);

final _realQuestContext = AiUserContext(
  generatedAt: DateTime(2026, 5, 12),
  quests: const [
    DailyQuest(
      id: 'quest-1',
      dateKey: '2026-05-12',
      type: 'hydration',
      title: 'Hydrate today',
      description: 'Drink water.',
      targetValue: 1,
      currentValue: 0,
      completed: false,
      completedAt: null,
    ),
  ],
  studyTasks: const [],
  schedules: const [],
  mealLogs: const [],
  workoutPlans: const [],
  workoutActivities: const [],
  sources: const {
    'quests': AiContextSourceState(
      label: 'Daily quests',
      status: AiContextSourceStatus.loaded,
    ),
  },
);

final _testContextProvider =
    NotifierProvider<_TestContextNotifier, AiUserContext>(
      _TestContextNotifier.new,
    );

class _TestContextNotifier extends Notifier<AiUserContext> {
  @override
  AiUserContext build() => _allLoadingContext;

  void setContext(AiUserContext context) {
    state = context;
  }
}
