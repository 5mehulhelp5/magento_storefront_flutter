import '../core/magento_client.dart';
import '../core/magento_exception.dart';
import '../models/category/category.dart';

/// Categories module for Magento Storefront
class MagentoCategories {
  final MagentoClient _client;

  MagentoCategories(this._client);

  /// Get category by ID
  /// 
  /// Example:
  /// ```dart
  /// final category = await MagentoCategories.getCategoryById('2');
  /// ```
  Future<MagentoCategory?> getCategoryById(String categoryId) async {
    final query = '''
      query GetCategory(\$id: String!) {
        category(id: \$id) {
          id
          uid
          name
          url_path
          url_key
          description
          image
          position
          level
          path
          product_count
          children {
            id
            uid
            name
            url_path
            url_key
            description
            image
            position
            level
            path
            product_count
          }
        }
      }
    ''';

    try {
      final response = await _client.query(
        query,
        variables: {'id': categoryId},
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final categoryData = data['category'] as Map<String, dynamic>?;
      if (categoryData == null) {
        return null;
      }

      return MagentoCategory.fromJson(categoryData);
    } on MagentoException catch (e) {
      print('[MagentoCategories] Get category by ID error: ${e.toString()}');
      rethrow;
    } catch (e, stackTrace) {
      print('[MagentoCategories] Failed to get category: ${e.toString()}');
      print('[MagentoCategories] Stack trace: $stackTrace');
      throw MagentoException(
        'Failed to get category: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get category tree
  /// 
  /// Example:
  /// ```dart
  /// final categories = await MagentoCategories.getCategoryTree();
  /// ```
  Future<List<MagentoCategory>> getCategoryTree() async {
    const query = '''
      query GetCategoryTree {
        categoryList {
          id
          uid
          name
          url_path
          url_key
          description
          image
          position
          level
          path
          product_count
          children {
            id
            uid
            name
            url_path
            url_key
            description
            image
            position
            level
            path
            product_count
            children {
              id
              uid
              name
              url_path
              url_key
              description
              image
              position
              level
              path
              product_count
            }
          }
        }
      }
    ''';

    try {
      final response = await _client.query(query);

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final categoryListData = data['categoryList'] as List<dynamic>?;
      if (categoryListData == null) {
        return [];
      }

      return categoryListData
          .map((c) => MagentoCategory.fromJson(c as Map<String, dynamic>))
          .toList();
    } on MagentoException catch (e) {
      print('[MagentoCategories] Get category tree error: ${e.toString()}');
      rethrow;
    } catch (e, stackTrace) {
      print('[MagentoCategories] Failed to get category tree: ${e.toString()}');
      print('[MagentoCategories] Stack trace: $stackTrace');
      throw MagentoException(
        'Failed to get category tree: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
