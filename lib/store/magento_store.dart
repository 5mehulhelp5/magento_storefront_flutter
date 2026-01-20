import '../core/magento_client.dart';
import '../core/magento_exception.dart';
import '../core/magento_logger.dart';
import '../core/magento_storage.dart';
import '../models/store/store.dart' as models;
import '../models/store/country.dart';
import 'graphql/countries_query.dart';

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

      final storeConfig = models.MagentoStoreConfig.fromJson(storeConfigData);
      
      // Save store config to storage
      try {
        await MagentoStorage.instance.saveStoreConfig(storeConfig);
      } catch (e) {
        // Storage might not be initialized, ignore silently
      }

      return storeConfig;
    } on MagentoException catch (e) {
      MagentoLogger.error('[MagentoStore] Get store config error: ${e.toString()}', e);
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoStore] Failed to get store config: ${e.toString()}',
        e,
        stackTrace,
      );
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
    } on MagentoException catch (e) {
      MagentoLogger.error('[MagentoStore] Get stores error: ${e.toString()}', e);
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoStore] Failed to get stores: ${e.toString()}',
        e,
        stackTrace,
      );
      throw MagentoException(
        'Failed to get stores: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get available countries with regions and cities
  /// 
  /// This method fetches all countries available in the store along with
  /// their regions (states/provinces) and cities. This is useful for building
  /// address forms with country/region/city dropdowns.
  /// 
  /// Example:
  /// ```dart
  /// final countries = await store.getCountries();
  /// for (final country in countries) {
  ///   print('${country.fullNameEnglish} (${country.twoLetterAbbreviation})');
  ///   if (country.availableRegions != null) {
  ///     for (final region in country.availableRegions!) {
  ///       print('  - ${region.name} (${region.code})');
  ///     }
  ///   }
  /// }
  /// ```
  Future<List<MagentoCountry>> getCountries() async {
    try {
      final response = await _client.query(countriesQuery);

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final countriesData = data['countries'] as List<dynamic>?;
      if (countriesData == null) {
        return [];
      }

      return countriesData
          .map((c) {
            try {
              return MagentoCountry.fromJson(c as Map<String, dynamic>);
            } catch (e) {
              MagentoLogger.error(
                '[MagentoStore] Failed to parse country: ${e.toString()}',
                e,
              );
              return null;
            }
          })
          .whereType<MagentoCountry>()
          .toList();
    } on MagentoException catch (e) {
      MagentoLogger.error('[MagentoStore] Get countries error: ${e.toString()}', e);
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoStore] Failed to get countries: ${e.toString()}',
        e,
        stackTrace,
      );
      throw MagentoException(
        'Failed to get countries: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Load store configuration from storage
  /// 
  /// Returns the saved store configuration if available, null otherwise.
  /// 
  /// Example:
  /// ```dart
  /// final cachedConfig = await MagentoStoreModule.loadStoreConfigFromStorage();
  /// ```
  static models.MagentoStoreConfig? loadStoreConfigFromStorage() {
    try {
      return MagentoStorage.instance.loadStoreConfig();
    } catch (e) {
      return null;
    }
  }
}
