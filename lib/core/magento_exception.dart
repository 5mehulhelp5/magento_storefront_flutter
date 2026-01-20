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
  MagentoAuthenticationException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'MagentoAuthenticationException: $message';
}

/// Alias exception for SDK consumers who expect `AuthException`.
///
/// Kept for Phase-1 API stability: the SDK historically exposed
/// `MagentoAuthenticationException`, while the Profile module spec uses
/// `AuthException`.
class AuthException extends MagentoAuthenticationException {
  AuthException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'AuthException: $message';
}

/// Exception thrown when a GraphQL query fails
class MagentoGraphQLException extends MagentoException {
  final List<GraphQLError>? errors;

  MagentoGraphQLException(super.message, {this.errors, super.code, super.originalError});

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      return 'MagentoGraphQLException: $message\nErrors: ${errors!.map((e) => e.message).join(', ')}';
    }
    return 'MagentoGraphQLException: $message';
  }
}

/// Exception thrown when an unexpected/unknown Magento error occurs.
///
/// This maps to the Profile module spec's `UnknownMagentoException` name,
/// while staying compatible with the SDK's base [MagentoException] type.
class UnknownMagentoException extends MagentoException {
  UnknownMagentoException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'UnknownMagentoException: $message';
}

/// Exception thrown when network requests fail
class MagentoNetworkException extends MagentoException {
  MagentoNetworkException(super.message, {super.code, super.originalError});

  @override
  String toString() => 'MagentoNetworkException: $message';
}

/// GraphQL error location structure
class GraphQLErrorLocation {
  final int line;
  final int column;

  GraphQLErrorLocation({
    required this.line,
    required this.column,
  });

  factory GraphQLErrorLocation.fromJson(Map<String, dynamic> json) {
    return GraphQLErrorLocation(
      line: json['line'] as int,
      column: json['column'] as int,
    );
  }

  @override
  String toString() => 'line $line, column $column';
}

/// GraphQL error structure
class GraphQLError {
  final String message;
  final List<GraphQLErrorLocation>? locations;
  final List<dynamic>? path;
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
          ? (json['locations'] as List)
              .map((l) => GraphQLErrorLocation.fromJson(l as Map<String, dynamic>))
              .toList()
          : null,
      path: json['path'] != null ? (json['path'] as List) : null,
      extensions: json['extensions'] != null
          ? Map<String, dynamic>.from(json['extensions'])
          : null,
    );
  }
}
