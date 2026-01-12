import '../core/magento_client.dart';
import '../core/magento_exception.dart';

/// Custom query module for executing arbitrary GraphQL queries
/// 
/// This provides an escape hatch for custom GraphQL queries that aren't
/// covered by the standard SDK methods.
class MagentoCustomQuery {
  final MagentoClient _client;

  MagentoCustomQuery(this._client);

  /// Execute a custom GraphQL query
  /// 
  /// Example:
  /// ```dart
  /// final result = await MagentoCustomQuery.query(
  ///   '''
  ///     query GetCustomData {
  ///       customField {
  ///         value
  ///       }
  ///     }
  ///   ''',
  ///   variables: {'id': '123'},
  /// );
  /// ```
  Future<Map<String, dynamic>> query(
    String query, {
    Map<String, dynamic>? variables,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      return await _client.query(
        query,
        variables: variables,
        additionalHeaders: additionalHeaders,
      );
    } on MagentoException {
      rethrow;
    } catch (e) {
      throw MagentoException(
        'Custom query failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Execute a custom GraphQL mutation
  /// 
  /// Example:
  /// ```dart
  /// final result = await MagentoCustomQuery.mutate(
  ///   '''
  ///     mutation UpdateCustomData($id: String!, $value: String!) {
  ///       updateCustomData(id: $id, value: $value) {
  ///         success
  ///       }
  ///     }
  ///   ''',
  ///   variables: {'id': '123', 'value': 'new value'},
  /// );
  /// ```
  Future<Map<String, dynamic>> mutate(
    String mutation, {
    Map<String, dynamic>? variables,
    Map<String, String>? additionalHeaders,
  }) async {
    try {
      return await _client.mutate(
        mutation,
        variables: variables,
        additionalHeaders: additionalHeaders,
      );
    } on MagentoException {
      rethrow;
    } catch (e) {
      throw MagentoException(
        'Custom mutation failed: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
