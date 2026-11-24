class AppConfig {
  AppConfig._();

  /// Default model identifier.
  /// Current supported models: 'gemini-3.5-flash-lite' (low latency) or 'gemini-3.8-flash' (higher reasoning).
  /// Deprecated models (gemini-2.5-*, gemini-1.5-*) are strictly prohibited.
  static const String defaultModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.5-flash-lite',
  );

  /// Base URL for proxying requests, or standard Gemini REST endpoint.
  /// For production, routes through a proxy to keep keys off-device.
  static const String proxyBaseUrl = String.fromEnvironment(
    'PROXY_BASE_URL',
    defaultValue: '',
  );

  /// Direct API Key via dart-define for local development builds.
  /// Never hardcode or bundle keys in source or assets.
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Default official Gemini REST base URL.
  static const String defaultGeminiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Maximum messages sent in outbound context window to protect latency and cost.
  static const int maxContextMessages = 20;

  /// Network timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration streamTimeout = Duration(seconds: 45);

  /// Default system instruction
  static const String systemInstruction =
      'You are cloneGPT, an expert, concise, and helpful enterprise AI assistant. '
      'Provide clear, direct, and well-structured answers using clean Markdown. '
      'For code blocks, always specify the language identifier.';

  /// Resolves the streaming endpoint URI for the current configuration.
  static Uri getStreamGenerateContentUri({String? model}) {
    final activeModel = model ?? defaultModel;
    if (proxyBaseUrl.isNotEmpty) {
      final base = proxyBaseUrl.endsWith('/')
          ? proxyBaseUrl.substring(0, proxyBaseUrl.length - 1)
          : proxyBaseUrl;
      return Uri.parse('$base/models/$activeModel:streamGenerateContent?alt=sse');
    }

    return Uri.parse(
      '$defaultGeminiEndpoint/models/$activeModel:streamGenerateContent?alt=sse&key=$geminiApiKey',
    );
  }
}
