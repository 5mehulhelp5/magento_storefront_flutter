import 'package:http/http.dart' as http;
import 'core/magento_client.dart';
import 'core/magento_config.dart';
import 'core/graphql_interceptor.dart';
import 'core/magento_storage.dart';
import 'auth/magento_auth.dart';
import 'store/magento_store.dart';
import 'catalog/magento_categories.dart';
import 'catalog/magento_products.dart';
import 'catalog/magento_search.dart';
import 'cart/magento_cart.dart';
import 'custom/magento_custom_query.dart';
import 'profile/magento_profile.dart';

/// Main SDK class for Magento Storefront Flutter
/// 
/// This is the primary entry point for using the Magento Storefront SDK.
/// 
/// Example:
/// ```dart
/// final sdk = MagentoSDK(
///   config: MagentoConfig(
///     baseUrl: 'https://yourstore.com',
///     storeCode: 'default',
///   ),
/// );
/// 
/// // Use authentication
/// final auth = sdk.auth;
/// await auth.login('user@example.com', 'password');
/// 
/// // Browse catalog
/// final products = sdk.products;
/// final product = await products.getProductBySku('product-sku');
/// 
/// // Search
/// final search = sdk.search;
/// final results = await search.searchProducts(query: 'shirt');
/// ```
class MagentoSDK {
  final MagentoConfig config;
  final MagentoClient _client;

  late final MagentoAuth auth;
  late final MagentoStoreModule store;
  late final MagentoCategories categories;
  late final MagentoProducts products;
  late final MagentoSearch search;
  late final MagentoCartModule cart;
  late final MagentoCustomQuery custom;
  late final MagentoProfile profile;

  /// Create a new MagentoSDK instance
  /// 
  /// [config] - Configuration for the Magento store
  /// [interceptor] - Optional GraphQL interceptor for request/response modification
  /// [httpClient] - Optional custom HTTP client (useful for testing)
  /// [useStorage] - Whether to use local storage for persistence (default: true)
  MagentoSDK({
    required this.config,
    GraphQLInterceptor? interceptor,
    http.Client? httpClient,
    bool useStorage = true,
  }) : _client = MagentoClient(
          config: config,
          interceptor: interceptor,
          httpClient: httpClient,
          onAuthFailure: () {
            // Automatically clear auth data from storage on failure
            if (useStorage) {
              MagentoStorage.instance.clearAuthToken();
              MagentoStorage.instance.clearCustomerCartId();
            }
          },
          onCartFailure: () {
            // Automatically clear cart ID from storage on failure
            if (useStorage) {
              MagentoStorage.instance.clearCustomerCartId();
            }
          },
        ) {
    // Save config to storage if enabled
    if (useStorage) {
      _saveConfig();
      _loadAuthToken();
    }
    
    // Initialize modules
    cart = MagentoCartModule(_client);
    auth = MagentoAuth(_client, cart);
    store = MagentoStoreModule(_client);
    categories = MagentoCategories(_client);
    products = MagentoProducts(_client);
    search = MagentoSearch(_client);
    custom = MagentoCustomQuery(_client);
    profile = MagentoProfile(_client);
  }

  /// Save configuration to storage
  Future<void> _saveConfig() async {
    try {
      await MagentoStorage.instance.saveConfig(config);
    } catch (e) {
      // Storage might not be initialized, ignore silently
    }
  }

  /// Load authentication token from storage
  void _loadAuthToken() {
    try {
      final token = MagentoStorage.instance.loadAuthToken();
      if (token != null) {
        _client.setAuthToken(token);
      }
    } catch (e) {
      // Storage might not be initialized, ignore silently
    }
  }

  /// Get the underlying client (for advanced use cases)
  MagentoClient get client => _client;

  /// Load configuration from storage
  /// 
  /// Returns the saved configuration if available, null otherwise.
  static MagentoConfig? loadConfigFromStorage() {
    try {
      return MagentoStorage.instance.loadConfig();
    } catch (e) {
      return null;
    }
  }

  /// Dispose resources
  void dispose() {
    _client.dispose();
  }
}
