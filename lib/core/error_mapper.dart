import 'package:http/http.dart' as http;
import 'magento_exception.dart';

/// Maps HTTP and GraphQL errors to Magento exceptions
class ErrorMapper {
  /// Map HTTP response to appropriate exception
  static MagentoException mapHttpError(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    print('[ErrorMapper] Mapping HTTP error: Status $statusCode');
    print('[ErrorMapper] Response body: $body');

    if (statusCode == 401 || statusCode == 403) {
      final exception = MagentoAuthenticationException(
        'Authentication failed',
        code: statusCode.toString(),
        originalError: body,
      );
      print('[ErrorMapper] Authentication error: ${exception.toString()}');
      return exception;
    }

    if (statusCode >= 500) {
      final exception = MagentoNetworkException(
        'Server error: $statusCode',
        code: statusCode.toString(),
        originalError: body,
      );
      print('[ErrorMapper] Server error: ${exception.toString()}');
      return exception;
    }

    final exception = MagentoNetworkException(
      'Request failed with status $statusCode',
      code: statusCode.toString(),
      originalError: body,
    );
    print('[ErrorMapper] Request failed: ${exception.toString()}');
    return exception;
  }

  /// Map GraphQL response errors to exception
  static MagentoGraphQLException mapGraphQLError(
    Map<String, dynamic> response,
  ) {
    final errors = response['errors'] as List<dynamic>?;
    
    print('[ErrorMapper] Mapping GraphQL error');
    print('[ErrorMapper] Response: $response');
    
    if (errors == null || errors.isEmpty) {
      final exception = MagentoGraphQLException(
        'Unknown GraphQL error',
        originalError: response,
      );
      print('[ErrorMapper] Unknown GraphQL error: ${exception.toString()}');
      return exception;
    }

    final graphQLErrors = errors
        .map((e) => GraphQLError.fromJson(e as Map<String, dynamic>))
        .toList();

    final errorMessages = graphQLErrors.map((e) => e.message).join(', ');

    print('[ErrorMapper] GraphQL errors found: ${graphQLErrors.length}');
    for (var error in graphQLErrors) {
      print('[ErrorMapper] GraphQL Error: ${error.message}');
      if (error.locations != null && error.locations!.isNotEmpty) {
        print('[ErrorMapper]   Locations: ${error.locations!.map((l) => l.toString()).join(', ')}');
      }
      if (error.path != null && error.path!.isNotEmpty) {
        print('[ErrorMapper]   Path: ${error.path!.join(' -> ')}');
      }
      if (error.extensions != null) {
        print('[ErrorMapper]   Extensions: ${error.extensions}');
      }
    }

    final exception = MagentoGraphQLException(
      errorMessages,
      errors: graphQLErrors,
      originalError: response,
    );
    print('[ErrorMapper] GraphQL exception: ${exception.toString()}');
    return exception;
  }

  /// Map network exceptions (timeout, connection errors, etc.)
  static MagentoNetworkException mapNetworkException(dynamic error) {
    print('[ErrorMapper] Mapping network exception: ${error.toString()}');
    
    if (error is http.ClientException) {
      final exception = MagentoNetworkException(
        'Network error: ${error.message}',
        originalError: error,
      );
      print('[ErrorMapper] ClientException: ${exception.toString()}');
      return exception;
    }

    final exception = MagentoNetworkException(
      'Network error: ${error.toString()}',
      originalError: error,
    );
    print('[ErrorMapper] Network exception: ${exception.toString()}');
    return exception;
  }
}
