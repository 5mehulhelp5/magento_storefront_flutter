import '../core/magento_client.dart';
import '../core/magento_exception.dart';
import '../models/product/product.dart';

/// Products module for Magento Storefront
class MagentoProducts {
  final MagentoClient _client;

  MagentoProducts(this._client);

  /// Get product by SKU
  /// 
  /// Example:
  /// ```dart
  /// final product = await MagentoProducts.getProductBySku('product-sku');
  /// ```
  Future<MagentoProduct?> getProductBySku(String sku) async {
    final query = '''
      query GetProductBySku(\$sku: String!) {
        products(filter: { sku: { eq: \$sku } }) {
          items {
            id
            sku
            name
            url_key
            description {
              html
            }
            short_description {
              html
            }
            image {
              url
              label
              position
            }
            price_range {
              minimum_price {
                regular_price {
                  value
                  currency
                }
                final_price {
                  value
                  currency
                }
                discount {
                  value
                  currency
                }
              }
              maximum_price {
                regular_price {
                  value
                  currency
                }
                final_price {
                  value
                  currency
                }
              }
            }
            stock_status
          }
        }
      }
    ''';

    try {
      final response = await _client.query(
        query,
        variables: {'sku': sku},
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final productsData = data['products'] as Map<String, dynamic>?;
      if (productsData == null) {
        return null;
      }

      final items = productsData['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) {
        return null;
      }

      return MagentoProduct.fromJson(items.first as Map<String, dynamic>);
    } on MagentoException {
      rethrow;
    } catch (e) {
      throw MagentoException(
        'Failed to get product: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get product by URL key
  /// 
  /// Example:
  /// ```dart
  /// final product = await MagentoProducts.getProductByUrlKey('product-url-key');
  /// ```
  Future<MagentoProduct?> getProductByUrlKey(String urlKey) async {
    final query = '''
      query GetProductByUrlKey(\$urlKey: String!) {
        products(filter: { url_key: { eq: \$urlKey } }) {
          items {
            id
            sku
            name
            url_key
            description {
              html
            }
            short_description {
              html
            }
            image {
              url
              label
              position
            }
            price_range {
              minimum_price {
                regular_price {
                  value
                  currency
                }
                final_price {
                  value
                  currency
                }
                discount {
                  value
                  currency
                }
              }
              maximum_price {
                regular_price {
                  value
                  currency
                }
                final_price {
                  value
                  currency
                }
              }
            }
            stock_status
          }
        }
      }
    ''';

    try {
      final response = await _client.query(
        query,
        variables: {'urlKey': urlKey},
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final productsData = data['products'] as Map<String, dynamic>?;
      if (productsData == null) {
        return null;
      }

      final items = productsData['items'] as List<dynamic>?;
      if (items == null || items.isEmpty) {
        return null;
      }

      return MagentoProduct.fromJson(items.first as Map<String, dynamic>);
    } on MagentoException {
      rethrow;
    } catch (e) {
      throw MagentoException(
        'Failed to get product: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get products by category ID
  /// 
  /// Example:
  /// ```dart
  /// final products = await MagentoProducts.getProductsByCategoryId(
  ///   categoryId: '2',
  ///   pageSize: 20,
  ///   currentPage: 1,
  /// );
  /// ```
  Future<MagentoProductListResult> getProductsByCategoryId({
    required String categoryId,
    int pageSize = 20,
    int currentPage = 1,
  }) async {
    final query = '''
      query GetProductsByCategory(
        \$categoryId: String!,
        \$pageSize: Int!,
        \$currentPage: Int!
      ) {
        products(
          filter: { category_id: { eq: \$categoryId } },
          pageSize: \$pageSize,
          currentPage: \$currentPage
        ) {
          items {
            id
            sku
            name
            url_key
            description {
              html
            }
            short_description {
              html
            }
            image {
              url
              label
              position
            }
            price_range {
              minimum_price {
                regular_price {
                  value
                  currency
                }
                final_price {
                  value
                  currency
                }
                discount {
                  value
                  currency
                }
              }
              maximum_price {
                regular_price {
                  value
                  currency
                }
                final_price {
                  value
                  currency
                }
              }
            }
            stock_status
          }
          page_info {
            current_page
            page_size
            total_pages
          }
          total_count
        }
      }
    ''';

    try {
      final response = await _client.query(
        query,
        variables: {
          'categoryId': categoryId,
          'pageSize': pageSize,
          'currentPage': currentPage,
        },
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final productsData = data['products'] as Map<String, dynamic>?;
      if (productsData == null) {
        return MagentoProductListResult(
          products: [],
          totalCount: 0,
          currentPage: currentPage,
          pageSize: pageSize,
          totalPages: 0,
        );
      }

      final items = productsData['items'] as List<dynamic>? ?? [];
      final pageInfo = productsData['page_info'] as Map<String, dynamic>?;
      final totalCount = productsData['total_count'] as int? ?? 0;

      return MagentoProductListResult(
        products: items
            .map((p) => MagentoProduct.fromJson(p as Map<String, dynamic>))
            .toList(),
        totalCount: totalCount,
        currentPage: pageInfo?['current_page'] as int? ?? currentPage,
        pageSize: pageInfo?['page_size'] as int? ?? pageSize,
        totalPages: pageInfo?['total_pages'] as int? ?? 0,
      );
    } on MagentoException {
      rethrow;
    } catch (e) {
      throw MagentoException(
        'Failed to get products: ${e.toString()}',
        originalError: e,
      );
    }
  }
}

/// Product list result with pagination info
class MagentoProductListResult {
  final List<MagentoProduct> products;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final int totalPages;

  MagentoProductListResult({
    required this.products,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
  });
}
