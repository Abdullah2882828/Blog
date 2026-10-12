/// lib/services/ai_analysis_service.dart
/// ------------------------------------------------------------
/// Service responsible for communicating with a large‑language‑model (LLM)
/// provider (Google Gemini or OpenAI) to analyse, debug and improve source
/// code. The service abstracts the HTTP calls, builds the appropriate prompt
/// (Arabic explanation + corrected code) and converts the raw JSON response
/// into the app‑level model `AiResponse` (defined in `lib/models/ai_response.dart`).
///
/// The implementation follows a singleton pattern so that the same HTTP
/// client and configuration are reused throughout the app.
/// ------------------------------------------------------------

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../models/ai_response.dart';

/// Enum representing the supported LLM providers.
enum LlmProvider { gemini, openAi }

/// Configuration class that holds API‑specific settings. In a real project
/// you would load the values from a secure source (e.g. .env, flutter_dotenv
/// or Firebase Remote Config). For the purpose of this example the values are
/// hard‑coded but marked as `@visibleForTesting` so they can be overridden in
/// unit tests.
@visibleForTesting
class LlmConfig {
  final LlmProvider provider;
  final String apiKey;
  final String endpoint; // Base URL without trailing slash.

  const LlmConfig({
    required this.provider,
    required this.apiKey,
    required this.endpoint,
  });
}

/// Service that sends a piece of source code to the selected LLM and returns
/// an [AiResponse] containing:
///   * `originalCode` – the code that was sent.
///   * `fixedCode` – the corrected version suggested by the model.
///   * `explanationAr` – Arabic description of the problem(s) and the fix.
///   * `explanationEn` – (optional) English description for debugging.
class AiAnalysisService {
  // ---------------------------------------------------------------------
  // Singleton boilerplate
  // ---------------------------------------------------------------------
  static final AiAnalysisService _instance = AiAnalysisService._internal();
  factory AiAnalysisService({LlmConfig? config}) {
    if (config != null) _instance._config = config;
    return _instance;
  }
  AiAnalysisService._internal();

  // ---------------------------------------------------------------------
  // Private fields
  // ---------------------------------------------------------------------
  late LlmConfig _config = const LlmConfig(
    provider: LlmProvider.gemini,
    apiKey: 'YOUR_API_KEY_HERE', // <-- replace with real key or load securely
    endpoint: 'https://generativelanguage.googleapis.com/v1',
  );

  final http.Client _httpClient = http.Client();

  // ---------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------
  /// Analyse the supplied [code] written in the given [language] (e.g. "dart",
  /// "python", "javascript"). Returns an [AiResponse] with the corrected code
  /// and an Arabic explanation.
  ///
  /// Throws a [AiServiceException] on network or parsing errors.
  Future<AiResponse> analyzeAndFix({
    required String code,
    required String language,
  }) async {
    final prompt = _buildPrompt(code: code, language: language);
    final rawResponse = await _postPrompt(prompt);
    return _parseResponse(rawResponse, originalCode: code);
  }

  /// Simple chat‑style interaction – send a user message and receive the raw
  /// LLM reply. This method is used by the AI chat screen where the user may
  /// ask for algorithm generation, concept explanation, etc.
  Future<String> chat({required String message}) async {
    final prompt = _buildChatPrompt(message);
    final rawResponse = await _postPrompt(prompt);
    // The chat endpoint usually returns a "candidates" list with a single
    // "content" field. We extract the first text block.
    try {
      final candidates = rawResponse['candidates'] as List<dynamic>;
      final content = candidates.first['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;
      final text = parts.first['text'] as String;
      return text.trim();
    } catch (e) {
      throw AiServiceException('Failed to parse chat response: $e');
    }
  }

  // ---------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------
  /// Build the prompt that asks the model to:
  ///   1. Identify syntax / logical errors.
  ///   2. Provide a corrected version of the code.
  ///   3. Explain the problem and the fix in Arabic (simple language).
  /// The prompt is deliberately concise to keep token usage low.
  String _buildPrompt({required String code, required String language}) {
    return '''
أنت مساعد برمجة ذكي يتحدث العربية. مهمتك هي تحليل الشيفرة التالية المكتوبة بلغة $language،
تحديد الأخطاء (نحوية أو منطقية)، ثم إعطاء نسخة مصححة من الشيفرة مع شرح مفصل باللغة العربية
للخطأ/الأخطاء وكيفية إصلاحها.

--- الشيفرة الأصلية ---
$code
--- النهاية ---

الرجاء إرجاع النتيجة بصيغة JSON على النحو التالي:
{
  "fixed_code": "<الشيفرة المصححة>",
  "explanation_ar": "<شرح مفصل باللغة العربية>"
}
''';
  }

  /// Build a minimal chat prompt – just the user message. Gemini expects a
  /// JSON payload with a `contents` array.
  String _buildChatPrompt(String message) {
    return message;
  }

  /// Send the built prompt to the appropriate endpoint based on [_config].
  /// Returns the decoded JSON response.
  Future<Map<String, dynamic>> _postPrompt(String prompt) async {
    final uri = _buildUri();
    final headers = {
      'Content-Type': 'application/json',
      if (_config.provider == LlmProvider.openAi) 'Authorization': 'Bearer ${_config.apiKey}',
    };

    final body = jsonEncode(_buildRequestBody(prompt));

    try {
      final response = await _httpClient.post(uri, headers: headers, body: body);
      if (response.statusCode != 200) {
        throw AiServiceException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}\n${response.body}',
        );
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } on http.ClientException catch (e) {
      throw AiServiceException('Network error: $e');
    } catch (e) {
      throw AiServiceException('Unexpected error: $e');
    }
  }

  /// Construct the full request URI, adding the API‑key as a query parameter
  /// for Gemini (OpenAI uses an Authorization header instead).
  Uri _buildUri() {
    switch (_config.provider) {
      case LlmProvider.gemini:
        // Example: https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=API_KEY
        return Uri.parse(
          '${_config.endpoint}/models/gemini-pro:generateContent?key=${_config.apiKey}',
        );
      case LlmProvider.openAi:
        // Example: https://api.openai.com/v1/chat/completions
        return Uri.parse('${_config.endpoint}/chat/completions');
    }
  }

  /// Build the request payload according to the provider's schema.
  Map<String, dynamic> _buildRequestBody(String prompt) {
    switch (_config.provider) {
      case LlmProvider.gemini:
        return {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        };
      case LlmProvider.openAi:
        return {
          'model': 'gpt-4o-mini', // adjust as needed
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.2,
        };
    }
  }

  /// Convert the raw JSON returned by the LLM into an [AiResponse] instance.
  AiResponse _parseResponse(Map<String, dynamic> raw, {required String originalCode}) {
    try {
      // Gemini returns a `candidates` list with a `content.parts[0].text` field.
      // OpenAI returns `choices[0].message.content`.
      String text;
      if (_config.provider == LlmProvider.gemini) {
        final candidates = raw['candidates'] as List<dynamic>;
        final content = candidates.first['content'] as Map<String, dynamic>;
        final parts = content['parts'] as List<dynamic>;
        text = parts.first['text'] as String;
      } else {
        final choices = raw['choices'] as List<dynamic>;
        final message = choices.first['message'] as Map<String, dynamic>;
        text = message['content'] as String;
      }

      // The model is instructed to return a JSON block. We attempt to extract
      // it using a RegExp that finds the first `{ ... }` substring.
      final jsonMatch = RegExp(r'\{[\s\S]*?\}').firstMatch(text);
      if (jsonMatch == null) {
        throw FormatException('No JSON block found in LLM response');
      }
      final jsonString = jsonMatch.group(0)!;
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;

      final fixedCode = decoded['fixed_code'] as String? ?? '';
      final explanationAr = decoded['explanation_ar'] as String? ?? '';
      final explanationEn = decoded['explanation_en'] as String? ?? '';

      return AiResponse(
        originalCode: originalCode,
        fixedCode: fixedCode,
        explanationAr: explanationAr,
        explanationEn: explanationEn,
      );
    } on FormatException catch (e) {
      throw AiServiceException('Failed to decode LLM JSON: $e');
    } catch (e) {
      throw AiServiceException('Unexpected parsing error: $e');
    }
  }

  /// Dispose the HTTP client when the app shuts down (optional).
  void dispose() {
    _httpClient.close();
  }
}

/// Custom exception type for the service – makes error handling in UI code
/// more expressive.
class AiServiceException implements Exception {
  final String message;
  AiServiceException(this.message);
  @override
  String toString() => 'AiServiceException: $message';
}
