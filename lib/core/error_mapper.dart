import 'package:http/http.dart' as http;
import 'magento_exception.dart';

/// Maps HTTP and GraphQL errors to Magento exceptions
class ErrorMapper {
  /// Map HTTP response to appropriate exception
  static MagentoException mapHttpError(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode == 401 || statusCode == 403) {
      return MagentoAuthenticationException(
        'Authentication failed',
        code: statusCode.toString(),
        originalError: body,
      );
    }

    if (statusCode >= 500) {
      return MagentoNetworkException(
        'Server error: $statusCode',
        code: statusCode.toString(),
        originalError: body,
      );
    }

    return MagentoNetworkException(
      'Request failed with status $statusCode',
      code: statusCode.toString(),
      originalError: body,
    );
  }

  /// Map GraphQL response errors to exception
  static MagentoGraphQLException mapGraphQLError(
    Map<String, dynamic> response,
  ) {
    final errors = response['errors'] as List<dynamic>?;
    
    if (errors == null || errors.isEmpty) {
      return MagentoGraphQLException(
        'Unknown GraphQL error',
        originalError: response,
      );
    }

    final graphQLErrors = errors
        .map((e) => GraphQLError.fromJson(e as Map<String, dynamic>))
        .toList();

    final errorMessages = graphQLErrors.map((e) => e.message).join(', ');

    return MagentoGraphQLException(
      errorMessages,
      errors: graphQLErrors,
      originalError: response,
    );
  }

  /// Map network exceptions (timeout, connection errors, etc.)
  static MagentoNetworkException mapNetworkException(dynamic error) {
    if (error is http.ClientException) {
      return MagentoNetworkException(
        'Network error: ${error.message}',
        originalError: error,
      );
    }

    return MagentoNetworkException(
      'Network error: ${error.toString()}',
      originalError: error,
    );
  }
}
