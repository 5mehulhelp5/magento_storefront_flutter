/// Interceptor for GraphQL requests and responses
/// Allows modification of queries and responses before/after execution
class GraphQLInterceptor {
  /// Intercept and modify GraphQL query before execution
  /// 
  /// Returns the modified query string, or null to use original
  String? interceptQuery(String query, Map<String, dynamic>? variables) {
    return null; // Default: no modification
  }

  /// Intercept and modify GraphQL variables before execution
  /// 
  /// Returns the modified variables map, or null to use original
  Map<String, dynamic>? interceptVariables(
    String query,
    Map<String, dynamic>? variables,
  ) {
    return null; // Default: no modification
  }

  /// Intercept and modify request headers before execution
  /// 
  /// Returns the modified headers map, or null to use original
  Map<String, String>? interceptHeaders(
    String query,
    Map<String, dynamic>? variables,
    Map<String, String> headers,
  ) {
    return null; // Default: no modification
  }

  /// Intercept response after execution
  /// 
  /// Returns the modified response, or null to use original
  Map<String, dynamic>? interceptResponse(Map<String, dynamic> response) {
    return null; // Default: no modification
  }

  /// Called when an error occurs during request execution
  void onError(dynamic error) {
    // Default: no action
  }
}

/// Default interceptor that does nothing
class DefaultGraphQLInterceptor extends GraphQLInterceptor {
  // Inherits all default behavior
}
