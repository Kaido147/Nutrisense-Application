import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrisense/models/ai_chat_message.dart';
import 'package:nutrisense/models/ai_user_context.dart';
import 'package:nutrisense/services/groq_ai_service.dart';

void main() {
  group('GroqAiService', () {
    test(
      'sends chat messages with app context and returns assistant content',
      () async {
        late Map<String, dynamic> requestBody;
        final service = GroqAiService(
          apiKey: 'test-key',
          model: 'test-model',
          client: MockClient((request) async {
            requestBody = jsonDecode(request.body) as Map<String, dynamic>;
            expect(request.method, 'POST');
            expect(
              request.url.toString(),
              'https://api.groq.com/openai/v1/chat/completions',
            );
            expect(request.headers['Authorization'], 'Bearer test-key');

            return http.Response(
              jsonEncode({
                'choices': [
                  {
                    'message': {'content': 'Take a short stretch break.'},
                  },
                ],
              }),
              200,
            );
          }),
        );

        final response = await service.sendMessage([
          AiChatMessage.user('I feel tired.'),
        ], context: _emptyContext);

        expect(response, 'Take a short stretch break.');
        expect(requestBody['model'], 'test-model');
        expect(requestBody['messages'], isA<List>());
        expect((requestBody['messages'] as List).first['role'], 'system');
        expect(
          (requestBody['messages'] as List)[1]['content'],
          contains('No logged meals'),
        );
        expect(
          (requestBody['messages'] as List)[1]['content'],
          contains('Allowed in-app workout catalog'),
        );
        expect(
          (requestBody['messages'] as List).last['content'],
          'I feel tired.',
        );
      },
    );

    test('prefers dotenv config over dart-define fallback values', () async {
      late http.BaseRequest capturedRequest;
      late Map<String, dynamic> requestBody;
      final service = GroqAiService(
        apiKey: 'define-key',
        model: 'define-model',
        dotenvValues: const {
          'GROQ_API_KEY': 'env-key',
          'GROQ_MODEL': 'env-model',
        },
        client: MockClient((request) async {
          capturedRequest = request;
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': 'Done.'},
                },
              ],
            }),
            200,
          );
        }),
      );

      await service.sendMessage([
        AiChatMessage.user('Hello'),
      ], context: _emptyContext);

      expect(capturedRequest.headers['Authorization'], 'Bearer env-key');
      expect(requestBody['model'], 'env-model');
    });

    test('throws when the Groq API key is missing', () async {
      final service = GroqAiService(
        apiKey: '',
        dotenvValues: const {},
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(
        () => service.sendMessage([
          AiChatMessage.user('Hello'),
        ], context: _emptyContext),
        throwsA(isA<MissingGroqApiKeyException>()),
      );
    });

    test('throws a friendly service exception on API errors', () async {
      final service = GroqAiService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response('server error', 500)),
      );

      expect(
        () => service.sendMessage([
          AiChatMessage.user('Hello'),
        ], context: _emptyContext),
        throwsA(isA<GroqAiException>()),
      );
    });

    test(
      'throws a friendly service exception on malformed responses',
      () async {
        final service = GroqAiService(
          apiKey: 'test-key',
          client: MockClient((_) async => http.Response('not-json', 200)),
        );

        expect(
          () => service.sendMessage([
            AiChatMessage.user('Hello'),
          ], context: _emptyContext),
          throwsA(isA<GroqAiException>()),
        );
      },
    );
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
