import '../core/magento_client.dart';
import '../core/magento_exception.dart';
import '../models/product/product.dart';
import 'magento_products.dart';

/// Search module for Magento Storefront
class MagentoSearch {
  final MagentoClient _client;

  MagentoSearch(this._client);

  /// Search products by query string
  /// 
  /// Example:
  /// ```dart
  /// final results = await MagentoSearch.searchProducts(
  ///   query: 'shirt',
  ///   pageSize: 20,
  ///   currentPage: 1,
  /// );
  /// ```
  Future<MagentoProductListResult> searchProducts({
    required String query,
    int pageSize = 20,
    int currentPage = 1,
    String? sortBy,
  }) async {
    final sortField = sortBy ?? 'relevance';
    
    final graphqlQuery = '''
      query SearchProducts(
        \$search: String!,
        \$pageSize: Int!,
        \$currentPage: Int!,
        \$sort: ProductAttributeSortInput
      ) {
        products(
          search: \$search,
          pageSize: \$pageSize,
          currentPage: \$currentPage,
          sort: \$sort
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
      final sortInput = _getSortInput(sortField);
      
      final response = await _client.query(
        graphqlQuery,
        variables: {
          'search': query,
          'pageSize': pageSize,
          'currentPage': currentPage,
          if (sortInput != null) 'sort': sortInput,
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
        'Failed to search products: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get sort input for GraphQL query
  Map<String, dynamic>? _getSortInput(String sortField) {
    switch (sortField.toLowerCase()) {
      case 'relevance':
        return {'relevance': 'DESC'};
      case 'price_asc':
        return {'price': 'ASC'};
      case 'price_desc':
        return {'price': 'DESC'};
      case 'name_asc':
        return {'name': 'ASC'};
      case 'name_desc':
        return {'name': 'DESC'};
      case 'created_at':
        return {'created_at': 'DESC'};
      default:
        return null;
    }
  }
}
