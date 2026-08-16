class ApiConfig {
  ApiConfig._();

  static const String openRouterApiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '',
  );
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const String openRouterFreeModel = 'openrouter/free';
  static const String openRouterChatModel = 'openrouter/free';

  static bool get hasApiKey => openRouterApiKey.isNotEmpty;
}
