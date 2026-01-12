/// Configuration class for Magento Storefront SDK
class MagentoConfig {
  /// Base URL of the Magento store (e.g., 'https://yourstore.com')
  final String baseUrl;

  /// Store code (optional, defaults to 'default')
  final String? storeCode;

  /// Custom headers to include in all requests
  final Map<String, String>? customHeaders;

  /// Timeout duration for requests in seconds (default: 30)
  final int timeoutSeconds;

  /// Whether to enable debug logging
  final bool enableDebugLogging;

  MagentoConfig({
    required this.baseUrl,
    this.storeCode,
    this.customHeaders,
    this.timeoutSeconds = 30,
    this.enableDebugLogging = false,
  }) : assert(baseUrl.isNotEmpty, 'Base URL cannot be empty');

  /// Get the GraphQL endpoint URL
  String get graphqlEndpoint {
    final url = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    if (storeCode != null && storeCode!.isNotEmpty) {
      return '${url}graphql';
    }
    return '${url}graphql';
  }

  /// Get headers for requests
  Map<String, String> get headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (storeCode != null && storeCode!.isNotEmpty) {
      headers['Store'] = storeCode!;
    }

    if (customHeaders != null) {
      headers.addAll(customHeaders!);
    }

    return headers;
  }

  /// Create a copy with modified fields
  MagentoConfig copyWith({
    String? baseUrl,
    String? storeCode,
    Map<String, String>? customHeaders,
    int? timeoutSeconds,
    bool? enableDebugLogging,
  }) {
    return MagentoConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      storeCode: storeCode ?? this.storeCode,
      customHeaders: customHeaders ?? this.customHeaders,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
    );
  }
}
