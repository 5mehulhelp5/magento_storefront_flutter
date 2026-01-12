import '../core/magento_client.dart';
import '../core/magento_exception.dart';
import '../models/store/store.dart' as models;

/// Store module for Magento Storefront
class MagentoStoreModule {
  final MagentoClient _client;

  MagentoStoreModule(this._client);

  /// Get store configuration
  /// 
  /// Example:
  /// ```dart
  /// final config = await MagentoStoreModule.getStoreConfig();
  /// ```
  Future<models.MagentoStoreConfig> getStoreConfig() async {
    const query = '''
      query GetStoreConfig {
        storeConfig {
          id
          code
          website_id
          locale
          base_currency_code
          default_display_currency_code
          timezone
          weight_unit
          base_url
          secure_base_url
          store_name
          catalog_search_enabled
          use_store_in_url
        }
      }
    ''';

    try {
      final response = await _client.query(query);

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final storeConfigData = data['storeConfig'] as Map<String, dynamic>?;
      if (storeConfigData == null) {
        throw MagentoException('Store config not found');
      }

      return models.MagentoStoreConfig.fromJson(storeConfigData);
    } on MagentoException {
      rethrow;
    } catch (e) {
      throw MagentoException(
        'Failed to get store config: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get available stores
  /// 
  /// Example:
  /// ```dart
  /// final stores = await MagentoStoreModule.getStores();
  /// ```
  Future<List<models.MagentoStore>> getStores() async {
    const query = '''
      query GetStores {
        stores {
          id
          code
          name
          website_id
          locale
          base_currency_code
          default_display_currency_code
          timezone
          weight_unit
          base_url
          secure_base_url
        }
      }
    ''';

    try {
      final response = await _client.query(query);

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final storesData = data['stores'] as List<dynamic>?;
      if (storesData == null) {
        return [];
      }

      return storesData
          .map((s) => models.MagentoStore.fromJson(s as Map<String, dynamic>))
          .toList();
    } on MagentoException {
      rethrow;
    } catch (e) {
      throw MagentoException(
        'Failed to get stores: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
