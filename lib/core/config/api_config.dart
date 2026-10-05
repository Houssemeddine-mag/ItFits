class ApiConfig {
  ApiConfig._();

  static const String functionsBaseUrl = String.fromEnvironment(
    'FUNCTIONS_BASE_URL',
    defaultValue: 'https://us-central1-itfits-ai.cloudfunctions.net',
  );
}
