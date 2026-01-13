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
        final exception = ErrorMapper.mapHttpError(response);
        print('[MagentoClient] HTTP Error: ${exception.toString()}');
        print('[MagentoClient] Response Status: ${response.statusCode}');
        print('[MagentoClient] Response Body: ${response.body}');
        throw exception;
      }

      // Check for GraphQL errors
      if (finalResponse.containsKey('errors')) {
        final exception = ErrorMapper.mapGraphQLError(finalResponse);
        print('[MagentoClient] GraphQL Error: ${exception.toString()}');
        if (exception.errors != null) {
          for (var error in exception.errors!) {
            print('[MagentoClient] GraphQL Error Detail: ${error.message}');
            if (error.locations != null) {
              print('[MagentoClient] Error Locations: ${error.locations}');
            }
            if (error.path != null) {
              print('[MagentoClient] Error Path: ${error.path}');
            }
          }
        }
        interceptor?.onError(exception);
        throw exception;
      }

      return finalResponse;
    } on http.ClientException catch (e) {
      final exception = ErrorMapper.mapNetworkException(e);
      print('[MagentoClient] Network Exception: ${exception.toString()}');
      print('[MagentoClient] Original Error: ${e.toString()}');
      interceptor?.onError(exception);
      throw exception;
    } on MagentoException catch (e) {
      print('[MagentoClient] MagentoException: ${e.toString()}');
      if (e.originalError != null) {
        print('[MagentoClient] Original Error: ${e.originalError}');
      }
      rethrow;
    } catch (e, stackTrace) {
      final exception = ErrorMapper.mapNetworkException(e);
      print('[MagentoClient] Unexpected Error: ${exception.toString()}');
      print('[MagentoClient] Original Error: ${e.toString()}');
      print('[MagentoClient] Stack Trace: $stackTrace');
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
