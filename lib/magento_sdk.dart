import 'package:http/http.dart' as http;
import 'core/magento_client.dart';
import 'core/magento_config.dart';
import 'core/graphql_interceptor.dart';
import 'auth/magento_auth.dart';
import 'store/magento_store.dart';
import 'catalog/magento_categories.dart';
import 'catalog/magento_products.dart';
import 'catalog/magento_search.dart';
import 'cart/magento_cart.dart';
import 'custom/magento_custom_query.dart';

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

  /// Create a new MagentoSDK instance
  /// 
  /// [config] - Configuration for the Magento store
  /// [interceptor] - Optional GraphQL interceptor for request/response modification
  /// [httpClient] - Optional custom HTTP client (useful for testing)
  MagentoSDK({
    required this.config,
    GraphQLInterceptor? interceptor,
    http.Client? httpClient,
  }) : _client = MagentoClient(
          config: config,
          interceptor: interceptor,
          httpClient: httpClient,
        ) {
    // Initialize modules
    auth = MagentoAuth(_client);
    store = MagentoStoreModule(_client);
    categories = MagentoCategories(_client);
    products = MagentoProducts(_client);
    search = MagentoSearch(_client);
    cart = MagentoCartModule(_client);
    custom = MagentoCustomQuery(_client);
  }

  /// Get the underlying client (for advanced use cases)
  MagentoClient get client => _client;

  /// Dispose resources
  void dispose() {
    _client.dispose();
  }
}
