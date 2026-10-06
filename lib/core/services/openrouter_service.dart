import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/env_config.dart';

/// Shared-key OpenRouter configuration (with per-user BYOK override).
///
/// One key pasted into `.env` (`OPENROUTER_API_KEY`) is bundled with the app
/// and used by ALL users, so nobody has to paste their own key.
/// A user key saved in Profile → AI Setup still wins when present.
/// Server backends (Firebase functions) and free fallbacks remain as backup.
class OpenRouterService {
  OpenRouterService(this._ref);

  final Ref _ref;

  static const _storage = FlutterSecureStorage();
  static const _kApiKey = 'openrouter_api_key';
  static const _kChatModel = 'openrouter_chat_model';
  static const _kImageModel = 'openrouter_image_model';

  /// Default chat model: auto-routes to a free model that fits the request
  /// (including image understanding). Free tier: 50 req/day, no card needed.
  static const defaultChatModel = 'openrouter/free';

  /// Default image model. NOTE: OpenRouter has no `:free` image models —
  /// image generation always draws on credit balance (needs > $1 balance,
  /// costs ~1-5c per image). Low-cost default below.
  static const defaultImageModel = 'bytedance-seed/seedream-4.5';

  /// Curated free chat models (text + vision where noted). Model slugs change
  /// over time — any slug can also be typed as custom.
  static const List<OpenRouterModelOption> chatModels = [
    OpenRouterModelOption(
      id: 'openrouter/free',
      label: 'Auto (free)',
      hint: 'Routes to a free model that fits — vision included',
    ),
    OpenRouterModelOption(
      id: 'meta-llama/llama-3.3-70b-instruct:free',
      label: 'Llama 3.3 70B (free)',
      hint: 'Strong general chat, text-focused',
    ),
    OpenRouterModelOption(
      id: 'google/gemma-3-27b-it:free',
      label: 'Gemma 3 27B (free)',
      hint: 'Fast, good instruction following',
    ),
    OpenRouterModelOption(
      id: 'mistralai/mistral-small-3.1-24b-instruct:free',
      label: 'Mistral Small 3.1 (free)',
      hint: 'Fast + vision capable',
    ),
  ];

  /// Image-capable models for `POST /api/v1/images`. ALL are paid
  /// (no free tier) — they need OpenRouter credits.
  static const List<OpenRouterModelOption> imageModels = [
    OpenRouterModelOption(
      id: 'bytedance-seed/seedream-4.5',
      label: 'Seedream 4.5',
      hint: '~\$0.04/image · text-to-image + reference edit',
    ),
    OpenRouterModelOption(
      id: 'openai/gpt-image-1-mini',
      label: 'GPT Image 1 Mini',
      hint: 'Cheaper OpenAI image model',
    ),
    OpenRouterModelOption(
      id: 'google/gemini-2.5-flash-image',
      label: 'Gemini Flash Image',
      hint: 'Fast multimodal image model',
    ),
    OpenRouterModelOption(
      id: 'black-forest-labs/flux-2-dev',
      label: 'FLUX 2 Dev',
      hint: 'Open-weight quality, cheap per MP',
    ),
  ];

  /// User's own key (Profile → AI Setup). Empty when not set.
  String get userApiKey => _ref.read(openRouterApiKeyProvider).trim();

  /// Backwards-compatible: the user's own key.
  String get apiKey => userApiKey;

  /// Effective key for all AI calls: user override wins, else shared `.env`.
  String get effectiveApiKey =>
      userApiKey.isNotEmpty ? userApiKey : EnvConfig.sharedOpenRouterKey;

  /// True when *any* key is available — shared `.env` counts, so this is
  /// true for all users once you paste the key into `.env`.
  bool get isReady => effectiveApiKey.isNotEmpty;

  /// True when the bundled shared key (not a per-user key) is doing the work.
  bool get usingSharedKey =>
      userApiKey.isEmpty && EnvConfig.hasSharedKey;

  String get chatModel => effectiveChatModel;
  String get imageModel => effectiveImageModel;

  /// User override wins; else `.env` default; else built-in default.
  String get effectiveChatModel {
    final user = _ref.read(openRouterChatModelProvider).trim();
    if (user.isNotEmpty && user != defaultChatModel) return user;
    if (EnvConfig.sharedChatModel.isNotEmpty) return EnvConfig.sharedChatModel;
    return user.isNotEmpty ? user : defaultChatModel;
  }

  String get effectiveImageModel {
    final user = _ref.read(openRouterImageModelProvider).trim();
    if (user.isNotEmpty && user != defaultImageModel) return user;
    if (EnvConfig.sharedImageModel.isNotEmpty) {
      return EnvConfig.sharedImageModel;
    }
    return user.isNotEmpty ? user : defaultImageModel;
  }

  static const _timeout = Duration(seconds: 90);

  Map<String, String> _headers(String key) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $key',
        'HTTP-Referer': 'https://itfits-ai.app',
        'X-Title': 'ItFits AI Interior Design',
      };

  Never _throwForStatus(int status, String body) {
    String detail = '';
    try {
      final parsed = jsonDecode(body) as Map<String, dynamic>?;
      final err = parsed?['error'];
      if (err is Map && err['message'] is String) {
        detail = (err['message'] as String).split('\n').first;
      }
    } catch (_) {}
    switch (status) {
      case 401:
        throw OpenRouterException(
            'Invalid OpenRouter key. Check Profile → AI Setup.${detail.isNotEmpty ? ' ($detail)' : ''}');
      case 402:
        throw const OpenRouterException(
            'OpenRouter credits needed for this model (image models are never free — top up past \$1 at openrouter.ai).');
      case 429:
        throw const OpenRouterException(
            'OpenRouter rate limit hit (free: 20/min). Wait a minute and retry.');
      default:
        throw OpenRouterException(
            'OpenRouter error ($status).${detail.isNotEmpty ? ' $detail' : ''}');
    }
  }

  /// Direct chat completions via the shared key (or user override).
  /// Messages use the OpenAI shape: {'role': ..., 'content': String | parts}.
  /// Supports multimodal parts: {'type':'text','text':...} and
  /// {'type':'image_url','image_url':{'url': dataUrl}} for vision models.
  Future<String> chat(List<Map<String, Object>> messages) async {
    final key = effectiveApiKey;
    if (key.isEmpty) {
      throw const OpenRouterException(
          'No AI key configured. Paste OPENROUTER_API_KEY into .env '
          'or add your own in Profile → AI Setup.');
    }
    final model =
        effectiveChatModel.isNotEmpty ? effectiveChatModel : defaultChatModel;
    late final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: _headers(key),
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'max_tokens': 1024,
            }),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const OpenRouterException('The AI took too long. Try again.');
    } catch (_) {
      throw const OpenRouterException(
          'Could not reach OpenRouter. Check your connection.');
    }
    if (res.statusCode != 200) _throwForStatus(res.statusCode, res.body);
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final choices = body['choices'];
      if (choices is List && choices.isNotEmpty) {
        final msg = (choices.first as Map)['message'];
        final content = msg is Map ? msg['content'] : null;
        if (content is String && content.trim().isNotEmpty) return content;
        // Some image-capable models return content parts.
        if (content is List) {
          final text = content
              .whereType<Map>()
              .where((p) => p['type'] == 'text' && p['text'] is String)
              .map((p) => p['text'] as String)
              .join('\n')
              .trim();
          if (text.isNotEmpty) return text;
        }
      }
    } catch (_) {}
    throw const OpenRouterException('The AI returned an empty answer.');
  }

  /// Image generation via `POST /api/v1/images`. Returns a data URL.
  /// [referenceDataUrl] enables image-to-image when the model supports it.
  /// Used for the 360 equirectangular redesign (`aspectRatio '2:1'`).
  Future<String> generateImage({
    required String prompt,
    String? referenceDataUrl,
    String aspectRatio = '2:1',
  }) async {
    final key = effectiveApiKey;
    if (key.isEmpty) {
      throw const OpenRouterException(
          'No AI key configured. Paste OPENROUTER_API_KEY into .env '
          'or add your own in Profile → AI Setup.');
    }
    final model =
        effectiveImageModel.isNotEmpty ? effectiveImageModel : defaultImageModel;
    final payload = <String, Object>{
      'model': model,
      'prompt': prompt,
      'aspect_ratio': aspectRatio,
      'output_format': 'jpeg',
    };
    if (referenceDataUrl != null && referenceDataUrl.startsWith('data:image')) {
      payload['input_references'] = [
        {
          'type': 'image_url',
          'image_url': {'url': referenceDataUrl},
        },
      ];
    }
    late final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('https://openrouter.ai/api/v1/images'),
            headers: _headers(key),
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 180));
    } on TimeoutException {
      throw const OpenRouterException('Image generation timed out. Try again.');
    } catch (_) {
      throw const OpenRouterException(
          'Could not reach OpenRouter. Check your connection.');
    }
    if (res.statusCode != 200) _throwForStatus(res.statusCode, res.body);
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final data = body['data'];
      if (data is List && data.isNotEmpty) {
        final first = data.first as Map;
        final b64 = first['b64_json'];
        if (b64 is String && b64.isNotEmpty) {
          final media = first['media_type'];
          final mime = media is String && media.startsWith('image/')
              ? media
              : 'image/jpeg';
          return 'data:$mime;base64,$b64';
        }
        final url = first['url'];
        if (url is String && url.startsWith('http')) {
          final img = await http.get(Uri.parse(url)).timeout(_timeout);
          if (img.statusCode == 200) {
            return 'data:image/jpeg;base64,${base64Encode(img.bodyBytes)}';
          }
        }
      }
    } catch (_) {}
    throw const OpenRouterException('No image was returned. Try another model.');
  }

  /// Lightweight key check: lists models; 401 means bad key.
  Future<void> testConnection(String key) async {
    final k = key.trim();
    if (k.isEmpty) throw const OpenRouterException('Paste a key first.');
    late final http.Response res;
    try {
      res = await http
          .get(
            Uri.parse('https://openrouter.ai/api/v1/models'),
            headers: _headers(k),
          )
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const OpenRouterException(
          'Could not reach OpenRouter. Check your connection.');
    }
    if (res.statusCode != 200) _throwForStatus(res.statusCode, res.body);
  }

  Future<void> loadPersisted() async {
    try {
      final stored = await Future.wait([
        _storage.read(key: _kApiKey),
        _storage.read(key: _kChatModel),
        _storage.read(key: _kImageModel),
      ]);
      if (stored[0] != null) {
        _ref.read(openRouterApiKeyProvider.notifier).state = stored[0]!;
      }
      _ref.read(openRouterChatModelProvider.notifier).state =
          (stored[1] == null || stored[1]!.trim().isEmpty)
              ? defaultChatModel
              : stored[1]!;
      _ref.read(openRouterImageModelProvider.notifier).state =
          (stored[2] == null || stored[2]!.trim().isEmpty)
              ? defaultImageModel
              : stored[2]!;
    } catch (_) {
      // Secure storage unavailable (e.g. tests) — keep in-memory state.
    }
  }

  Future<void> saveApiKey(String key) async {
    _ref.read(openRouterApiKeyProvider.notifier).state = key.trim();
    try {
      if (key.trim().isEmpty) {
        await _storage.delete(key: _kApiKey);
      } else {
        await _storage.write(key: _kApiKey, value: key.trim());
      }
    } catch (_) {}
  }

  Future<void> saveModels({required String chat, required String image}) async {
    final c = chat.trim().isEmpty ? defaultChatModel : chat.trim();
    final i = image.trim().isEmpty ? defaultImageModel : image.trim();
    _ref.read(openRouterChatModelProvider.notifier).state = c;
    _ref.read(openRouterImageModelProvider.notifier).state = i;
    try {
      await Future.wait([
        _storage.write(key: _kChatModel, value: c),
        _storage.write(key: _kImageModel, value: i),
      ]);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    _ref.read(openRouterApiKeyProvider.notifier).state = '';
    try {
      await Future.wait([
        _storage.delete(key: _kApiKey),
        _storage.delete(key: _kChatModel),
        _storage.delete(key: _kImageModel),
      ]);
    } catch (_) {}
    _ref.read(openRouterChatModelProvider.notifier).state = defaultChatModel;
    _ref.read(openRouterImageModelProvider.notifier).state = defaultImageModel;
  }
}

class OpenRouterModelOption {
  final String id;
  final String label;
  final String hint;
  const OpenRouterModelOption({
    required this.id,
    required this.label,
    required this.hint,
  });
}

class OpenRouterException implements Exception {
  final String message;
  const OpenRouterException(this.message);
  @override
  String toString() => message;
}

/// In-memory BYOK config (persisted in secure storage, loaded at startup).
final openRouterApiKeyProvider = StateProvider<String>((ref) => '');
final openRouterChatModelProvider =
    StateProvider<String>((ref) => OpenRouterService.defaultChatModel);
final openRouterImageModelProvider =
    StateProvider<String>((ref) => OpenRouterService.defaultImageModel);

/// True when AI can run: user key OR shared `.env` key present.
/// After you paste `OPENROUTER_API_KEY` into `.env`, this is true for all
/// users with no per-user setup.
final openRouterReadyProvider = Provider<bool>((ref) {
  if (ref.watch(openRouterApiKeyProvider).trim().isNotEmpty) return true;
  return EnvConfig.hasSharedKey;
});

final openRouterServiceProvider =
    Provider<OpenRouterService>((ref) => OpenRouterService(ref));

/// Loads persisted key/models once at startup. UI watches this so the banner
/// and generation screens see the saved key after a restart.
final openRouterBootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(openRouterServiceProvider).loadPersisted();
});
