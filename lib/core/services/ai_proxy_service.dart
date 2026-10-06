import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'providers.dart' show firebaseReady;

class AiProxyException implements Exception {
  final String message;
  const AiProxyException(this.message);
  @override
  String toString() => message;
}

class AiProxyService {
  static const _timeout = Duration(seconds: 90);

  bool get isAvailable =>
      firebaseReady && FirebaseAuth.instance.currentUser != null;

  Future<String> chat(List<Map<String, Object>> messages) async {
    final result = await _call('aiChat', {'messages': messages});
    final content = (result as Map?)?['content'];
    if (content is! String || content.trim().isEmpty) {
      throw const AiProxyException('The AI returned an empty answer.');
    }
    return content;
  }

  Future<String> generateDesign({
    required String imageDataUrl,
    required String prompt,
    required String style,
    required String roomType,
  }) async {
    final result = await _call('generateDesign', {
      'imageUrls': [imageDataUrl],
      'prompt': prompt,
      'style': style,
      'roomType': roomType,
    });
    final designs = (result as Map?)?['designs'];
    Object? url;
    if (designs is List && designs.isNotEmpty && designs.first is Map) {
      url = (designs.first as Map)['imageUrl'];
    }
    if (url is! String || url.isEmpty) {
      throw const AiProxyException('No design was generated.');
    }
    return url;
  }

  Future<Object?> _call(String name, Map<String, Object> data) async {
    final user = firebaseReady ? FirebaseAuth.instance.currentUser : null;
    if (user == null) {
      throw const AiProxyException('Sign in to use the AI designer.');
    }
    final token = await user.getIdToken();
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('${ApiConfig.functionsBaseUrl}/$name'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'data': data}),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const AiProxyException('The AI took too long. Please try again.');
    } catch (_) {
      throw const AiProxyException(
          'Could not reach the AI service. Check your connection.');
    }

    Map<String, dynamic>? body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {}
    if (response.statusCode == 200 && body != null && body.containsKey('result')) {
      return body['result'];
    }
    final error = body?['error'];
    final status = error is Map ? error['status'] : null;
    switch (status) {
      case 'RESOURCE_EXHAUSTED':
        throw AiProxyException(error is Map && error['message'] is String
            ? error['message'] as String
            : 'Daily AI limit reached. Try again tomorrow.');
      case 'UNAUTHENTICATED':
        throw const AiProxyException('Please sign in again.');
      case 'INVALID_ARGUMENT':
        throw const AiProxyException('That request was too large.');
      default:
        throw const AiProxyException(
            'The AI service is unavailable right now. Please try again.');
    }
  }
}
