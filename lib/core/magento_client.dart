import 'dart:convert';
import 'package:http/http.dart' as http;
import 'magento_config.dart';
import 'magento_exception.dart';
import 'error_mapper.dart';
import 'graphql_interceptor.dart';

/// Core HTTP client for Magento GraphQL API
class MagentoClient {
  final MagentoConfig config;
  final GraphQLInterceptor? interceptor;
  final http.Client _httpClient;

  /// Authentication token for authenticated requests
  String? _authToken;

  MagentoClient({
    required this.config,
    this.interceptor,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Set authentication token
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Get current authentication token
  String? get authToken => _authToken;

  /// Execute a GraphQL query
  Future<Map<String, dynamic>> query(
    String query, {
    Map<String, dynamic>? variables,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      // Apply interceptor to query and variables
      final finalQuery = interceptor?.interceptQuery(query, variables) ?? query;
      final finalVariables = interceptor?.interceptVariables(query, variables) ?? variables;

      // Prepare headers
      var headers = Map<String, String>.from(config.headers);
      if (_authToken != null) {
        headers['Authorization'] = 'Bearer $_authToken';
      }
      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }

      // Apply interceptor to headers
      final finalHeaders = interceptor?.interceptHeaders(finalQuery, finalVariables, headers) ?? headers;

      // Prepare request body
      final body = jsonEncode({
        'query': finalQuery,
        if (finalVariables != null) 'variables': finalVariables,
      });

      if (config.enableDebugLogging) {
        print('[MagentoClient] Query: $finalQuery');
        print('[MagentoClient] Variables: $finalVariables');
        print('[MagentoClient] Headers: $finalHeaders');
      }

      // Make request
      final response = await _httpClient
          .post(
            Uri.parse(config.graphqlEndpoint),
            headers: finalHeaders,
            body: body,
          )
          .timeout(Duration(seconds: config.timeoutSeconds));

      // Parse response
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      // Apply interceptor to response
      final finalResponse = interceptor?.interceptResponse(responseData) ?? responseData;

      // Check for HTTP errors
      if (response.statusCode != 200) {
        throw ErrorMapper.mapHttpError(response);
      }

      // Check for GraphQL errors
      if (finalResponse.containsKey('errors')) {
        final exception = ErrorMapper.mapGraphQLError(finalResponse);
        interceptor?.onError(exception);
        throw exception;
      }

      return finalResponse;
    } on http.ClientException catch (e) {
      final exception = ErrorMapper.mapNetworkException(e);
      interceptor?.onError(exception);
      throw exception;
    } on MagentoException {
      rethrow;
    } catch (e) {
      final exception = ErrorMapper.mapNetworkException(e);
      interceptor?.onError(exception);
      throw exception;
    }
  }

  /// Execute a GraphQL mutation
  Future<Map<String, dynamic>> mutate(
    String mutation, {
    Map<String, dynamic>? variables,
    Map<String, String>? additionalHeaders,
  }) async {
    return query(mutation, variables: variables, additionalHeaders: additionalHeaders);
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}
