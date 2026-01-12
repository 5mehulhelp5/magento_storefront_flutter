/// Base exception class for all Magento-related errors
class MagentoException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  MagentoException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'MagentoException: $message${code != null ? ' (code: $code)' : ''}';
}

/// Exception thrown when authentication fails
class MagentoAuthenticationException extends MagentoException {
  MagentoAuthenticationException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'MagentoAuthenticationException: $message';
}

/// Exception thrown when a GraphQL query fails
class MagentoGraphQLException extends MagentoException {
  final List<GraphQLError>? errors;

  MagentoGraphQLException(String message, {this.errors, String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      return 'MagentoGraphQLException: $message\nErrors: ${errors!.map((e) => e.message).join(', ')}';
    }
    return 'MagentoGraphQLException: $message';
  }
}

/// Exception thrown when network requests fail
class MagentoNetworkException extends MagentoException {
  MagentoNetworkException(String message, {String? code, dynamic originalError})
      : super(message, code: code, originalError: originalError);

  @override
  String toString() => 'MagentoNetworkException: $message';
}

/// GraphQL error structure
class GraphQLError {
  final String message;
  final List<String>? locations;
  final List<String>? path;
  final Map<String, dynamic>? extensions;

  GraphQLError({
    required this.message,
    this.locations,
    this.path,
    this.extensions,
  });

  factory GraphQLError.fromJson(Map<String, dynamic> json) {
    return GraphQLError(
      message: json['message'] as String,
      locations: json['locations'] != null
          ? (json['locations'] as List).cast<String>()
          : null,
      path: json['path'] != null ? (json['path'] as List).cast<String>() : null,
      extensions: json['extensions'] != null
          ? Map<String, dynamic>.from(json['extensions'])
          : null,
    );
  }
}
