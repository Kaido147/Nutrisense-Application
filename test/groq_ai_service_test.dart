import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutrisense/models/ai_chat_message.dart';
import 'package:nutrisense/services/groq_ai_service.dart';

void main() {
  group('GroqAiService', () {
    test('sends chat messages and returns assistant content', () async {
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
      ]);

      expect(response, 'Take a short stretch break.');
      expect(requestBody['model'], 'test-model');
      expect(requestBody['messages'], isA<List>());
      expect((requestBody['messages'] as List).first['role'], 'system');
      expect(
        (requestBody['messages'] as List).last['content'],
        'I feel tired.',
      );
    });

    test('throws when the Groq API key is missing', () async {
      final service = GroqAiService(
        apiKey: '',
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      expect(
        () => service.sendMessage([AiChatMessage.user('Hello')]),
        throwsA(isA<MissingGroqApiKeyException>()),
      );
    });

    test('throws a friendly service exception on API errors', () async {
      final service = GroqAiService(
        apiKey: 'test-key',
        client: MockClient((_) async => http.Response('server error', 500)),
      );

      expect(
        () => service.sendMessage([AiChatMessage.user('Hello')]),
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
          () => service.sendMessage([AiChatMessage.user('Hello')]),
          throwsA(isA<GroqAiException>()),
        );
      },
    );
  });
}
