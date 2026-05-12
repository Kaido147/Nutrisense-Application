import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:nutrisense/models/ai_chat_message.dart';
import 'package:nutrisense/models/ai_user_context.dart';

class MissingGroqApiKeyException implements Exception {
  const MissingGroqApiKeyException();

  @override
  String toString() => 'Missing GROQ_API_KEY configuration.';
}

class GroqAiException implements Exception {
  const GroqAiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GroqAiService {
  GroqAiService({
    required http.Client client,
    String? apiKey,
    String? model,
    Map<String, String>? dotenvValues,
    String dartDefineApiKey = _environmentApiKey,
    String dartDefineModel = _environmentModel,
    Uri? endpoint,
  }) : _client = client,
       _apiKey = _resolveConfigValue(
         _dotenvValue(dotenvValues, 'GROQ_API_KEY'),
         apiKey ?? dartDefineApiKey,
       ),
       _model = _resolveConfigValue(
         _dotenvValue(dotenvValues, 'GROQ_MODEL'),
         model ?? dartDefineModel,
         fallback: 'llama-3.3-70b-versatile',
       ),
       _endpoint =
           endpoint ??
           Uri.parse('https://api.groq.com/openai/v1/chat/completions');

  static const String _environmentApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
  );
  static const String _environmentModel = String.fromEnvironment(
    'GROQ_MODEL',
    defaultValue: 'llama-3.3-70b-versatile',
  );

  static const String _systemPrompt =
      'You are Wellness Owl, Nutrisense\'s supportive wellness assistant. '
      'Answer as part of the Nutrisense app using the supplied live app '
      'context when relevant. Be honest when data is missing, empty, or not '
      'provided. Do not claim access to data outside the supplied context. '
      'For workouts, only recommend exercises, categories, or plans listed in '
      'the supplied in-app workout catalog. If a requested workout is not '
      'available, suggest the closest available in-app option. Help students '
      'balance nutrition, workouts, study, rest, and daily habits. Keep '
      'replies concise, practical, encouraging, and app-focused. '
      'Do not diagnose medical conditions; recommend professional help for '
      'urgent, medical, mental health, or nutrition-specific concerns.';

  final http.Client _client;
  final String _apiKey;
  final String _model;
  final Uri _endpoint;

  static String? _dotenvValue(Map<String, String>? dotenvValues, String key) {
    if (dotenvValues != null) return dotenvValues[key];
    try {
      return dotenv.env[key];
    } catch (_) {
      return null;
    }
  }

  static String _resolveConfigValue(
    String? primary,
    String? secondary, {
    String fallback = '',
  }) {
    final primaryValue = primary?.trim() ?? '';
    if (primaryValue.isNotEmpty) return primaryValue;
    final secondaryValue = secondary?.trim() ?? '';
    if (secondaryValue.isNotEmpty) return secondaryValue;
    return fallback;
  }

  Future<String> sendMessage(
    List<AiChatMessage> messages, {
    required AiUserContext context,
  }) async {
    final key = _apiKey.trim();
    if (key.isEmpty) {
      throw const MissingGroqApiKeyException();
    }

    final conversation = messages
        .where((message) => message.content.trim().isNotEmpty)
        .map(
          (message) => {
            'role': message.groqRole,
            'content': message.content.trim(),
          },
        )
        .toList(growable: false);

    if (conversation.isEmpty) {
      throw const GroqAiException('No chat message to send.');
    }

    final response = await _client.post(
      _endpoint,
      headers: {
        'Authorization': 'Bearer $key',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'system', 'content': context.toPromptContext()},
          ...conversation,
        ],
        'temperature': 0.7,
        'max_tokens': 512,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GroqAiException('Groq request failed (${response.statusCode}).');
    }

    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = body['choices'] as List?;
      final firstChoice = choices?.isNotEmpty == true
          ? choices!.first as Map<String, dynamic>?
          : null;
      final message = firstChoice?['message'] as Map<String, dynamic>?;
      final content = message?['content']?.toString().trim();

      if (content == null || content.isEmpty) {
        throw const GroqAiException('Groq response did not include a message.');
      }

      return content;
    } on FormatException {
      throw const GroqAiException('Groq returned an invalid response.');
    } on TypeError {
      throw const GroqAiException('Groq returned an unexpected response.');
    }
  }
}
