import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Shared (bundled) AI configuration from `.env`.
///
/// Paste the single OpenRouter key all users share into `.env`:
/// ```env
/// OPENROUTER_API_KEY=sk-or-v1-...
/// OPENROUTER_CHAT_MODEL=openrouter/free
/// OPENROUTER_IMAGE_MODEL=bytedance-seed/seedream-4.5
/// ```
/// `.env` is gitignored; `.env.example` documents the shape.
/// Missing/empty values simply mean "no shared key" — the app then falls
/// back to the user's own key (Profile → AI Setup) and the server backend.
class EnvConfig {
  EnvConfig._();

  static String get sharedOpenRouterKey {
    try {
      return (dotenv.env['OPENROUTER_API_KEY'] ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  static String get sharedChatModel {
    try {
      return (dotenv.env['OPENROUTER_CHAT_MODEL'] ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  static String get sharedImageModel {
    try {
      return (dotenv.env['OPENROUTER_IMAGE_MODEL'] ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  static bool get hasSharedKey => sharedOpenRouterKey.isNotEmpty;
}
