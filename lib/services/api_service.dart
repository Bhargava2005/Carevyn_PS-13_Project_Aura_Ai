// lib/services/api_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/message_model.dart';
import '../models/ai_task_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException: $message';
}

class AiResult {
  final String? text;
  final Uint8List? imageBytes;
  bool get isImage => imageBytes != null;
  const AiResult.text(this.text) : imageBytes = null;
  const AiResult.image(this.imageBytes) : text = null;
}

enum ImageMode { generate, transform }

class ApiService {
  // --- CONFIG --------------------------------------------------------
  static String get _apiKey => dotenv.env['HUGGINGFACE_API_KEY'] ?? '';
  static const String _chatModel = 'Qwen/Qwen2.5-7B-Instruct';



  // -------------------------------------------------------------------

  final http.Client _http;

  ApiService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  // --- SHARED HEADERS ------------------------------------------------

  Map<String, String> get _jsonHeaders => {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      };



  // --- MAIN DISPATCH -------------------------------------------------

  Future<AiResult> runTask({
    required AiTask task,
    String? textInput,
  }) async {
    switch (task.type) {
      case AiTaskType.chat:
        if (textInput == null || textInput.trim().isEmpty) {
          throw ApiException('Please enter a message.');
        }
        final reply = await sendMessage([
          Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            role: MessageRole.user,
            content: textInput.trim(),
            timestamp: DateTime.now(),
          ),
        ]);
        return AiResult.text(reply);

      case AiTaskType.textToImage:
        if (textInput == null || textInput.trim().isEmpty) {
          throw ApiException('Please enter a prompt.');
        }
        final img = await textToImage(textInput.trim());
        return AiResult.image(img);
    }

  }

  Future<AiResult> handleImageRequest({
    required String prompt,
    Uint8List? imageBytes,
  }) async {
    // Text to image
    final img = await textToImage(prompt);
    return AiResult.image(img);
  }


  // --- CHAT ----------------------------------------------------------

  Future<String> sendMessage(List<Message> history) async {
    final body = jsonEncode({
      'model': _chatModel,
      'max_tokens': 600,
      'temperature': 0.7,
      'messages': [
        {
          'role': 'system',
          'content': 'You are Aura AI, a helpful, intelligent assistant. '
              'Be concise, professional, and use markdown when helpful.',
        },
        ...history.map((m) => {
              'role': m.role == MessageRole.user ? 'user' : 'assistant',
              'content': m.content,
            }),
      ],
    });

    try {
      final response = await _http
          .post(
            Uri.parse('https://router.huggingface.co/v1/chat/completions'),
            headers: _jsonHeaders,
            body: body,
          )
          .timeout(const Duration(seconds: 60));

      _checkStatus(response, 'Chat');

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final content = json['choices']?[0]?['message']?['content'] as String?;
      return content?.trim() ?? 'No response received.';
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Chat failed: $e');
    }
  }

  // --- TEXT -> IMAGE -------------------------------------------------

  Future<Uint8List> textToImage(String prompt) async {
    try {
      final response = await _http
          .post(
            Uri.parse('https://router.huggingface.co/hf-inference/models/black-forest-labs/FLUX.1-schnell'),
            headers: _jsonHeaders,
            body: jsonEncode({'inputs': prompt}),
          )
          .timeout(const Duration(seconds: 120));

      _checkStatus(response, 'Image generation');
      return response.bodyBytes;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Image generation failed: $e');
    }
  }



  void _checkStatus(http.Response response, String context) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(
      _friendlyError(response.statusCode, response.body),
      statusCode: response.statusCode,
    );
  }

  String _friendlyError(int code, String body) {
    switch (code) {
      case 401:
        return 'Unauthorized (401): Token invalid or expired. Re-check your HuggingFace API key.';
      case 403:
        return 'Forbidden (403): Your token does not have access to this model. Enable "Make calls to the serverless Inference API" in HuggingFace token settings.';
      case 429:
        return 'Rate limit reached. Please wait a moment and retry.';
      case 503:
        return 'Model is loading (cold start). Wait ~20s and try again.';
      default:
        return 'Request failed ($code): ${body.length > 120 ? body.substring(0, 120) : body}';
    }
  }

  void dispose() => _http.close();
}
