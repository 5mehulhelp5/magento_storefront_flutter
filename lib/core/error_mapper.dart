import 'package:http/http.dart' as http;
import 'magento_exception.dart';
import 'magento_logger.dart';

/// Maps HTTP and GraphQL errors to Magento exceptions
class ErrorMapper {
  /// Map HTTP response to appropriate exception
  static MagentoException mapHttpError(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    MagentoLogger.warning('[ErrorMapper] Mapping HTTP error: Status $statusCode');
    MagentoLogger.debug('[ErrorMapper] Response body: $body');

    if (statusCode == 401 || statusCode == 403) {
      final exception = MagentoAuthenticationException(
        'Authentication failed',
        code: statusCode.toString(),
        originalError: body,
      );
      MagentoLogger.error('[ErrorMapper] Authentication error: ${exception.toString()}');
      return exception;
    }

    if (statusCode >= 500) {
      final exception = MagentoNetworkException(
        'Server error: $statusCode',
        code: statusCode.toString(),
        originalError: body,
      );
      MagentoLogger.error('[ErrorMapper] Server error: ${exception.toString()}');
      return exception;
    }

    final exception = MagentoNetworkException(
      'Request failed with status $statusCode',
      code: statusCode.toString(),
      originalError: body,
    );
    MagentoLogger.error('[ErrorMapper] Request failed: ${exception.toString()}');
    return exception;
  }

  /// Map GraphQL response errors to exception
  static MagentoGraphQLException mapGraphQLError(
    Map<String, dynamic> response,
  ) {
    final errors = response['errors'] as List<dynamic>?;
    
    MagentoLogger.warning('[ErrorMapper] Mapping GraphQL error');
    MagentoLogger.debug('[ErrorMapper] Response: $response');
    
    if (errors == null || errors.isEmpty) {
      final exception = MagentoGraphQLException(
        'Unknown GraphQL error',
        originalError: response,
      );
      MagentoLogger.error('[ErrorMapper] Unknown GraphQL error: ${exception.toString()}');
      return exception;
    }

    final graphQLErrors = errors
        .map((e) => GraphQLError.fromJson(e as Map<String, dynamic>))
        .toList();

    final errorMessages = graphQLErrors.map((e) => e.message).join(', ');

    MagentoLogger.warning('[ErrorMapper] GraphQL errors found: ${graphQLErrors.length}');
    for (var error in graphQLErrors) {
      MagentoLogger.error('[ErrorMapper] GraphQL Error: ${error.message}');
      if (error.locations != null && error.locations!.isNotEmpty) {
        MagentoLogger.error('[ErrorMapper]   Locations: ${error.locations!.map((l) => l.toString()).join(', ')}');
      }
      if (error.path != null && error.path!.isNotEmpty) {
        MagentoLogger.error('[ErrorMapper]   Path: ${error.path!.join(' -> ')}');
      }
      if (error.extensions != null) {
        MagentoLogger.error('[ErrorMapper]   Extensions: ${error.extensions}');
      }
    }

    final exception = MagentoGraphQLException(
      errorMessages,
      errors: graphQLErrors,
      originalError: response,
    );
    MagentoLogger.error('[ErrorMapper] GraphQL exception: ${exception.toString()}');
    return exception;
  }

  /// Map network exceptions (timeout, connection errors, etc.)
  static MagentoNetworkException mapNetworkException(dynamic error) {
    MagentoLogger.warning('[ErrorMapper] Mapping network exception: ${error.toString()}');
    
    if (error is http.ClientException) {
      final exception = MagentoNetworkException(
        'Network error: ${error.message}',
        originalError: error,
      );
      MagentoLogger.error('[ErrorMapper] ClientException: ${exception.toString()}', error);
      return exception;
    }

    final exception = MagentoNetworkException(
      'Network error: ${error.toString()}',
      originalError: error,
    );
    MagentoLogger.error('[ErrorMapper] Network exception: ${exception.toString()}', error);
    return exception;
  }
}
