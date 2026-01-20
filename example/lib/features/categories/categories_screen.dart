import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';
import '../../services/magento_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isLoading = false;
  String? _error;
  List<MagentoCategory>? _categories;

  @override
  void initState() {
    super.initState();
    _loadCategoryTree();
  }

  Future<void> _loadCategoryTree() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      final categories = await sdk.categories.getCategoryTree();

      setState(() {
        _categories = categories;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCategoryById(String categoryId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      final category = await sdk.categories.getCategoryById(categoryId);

      if (mounted) {
        if (category == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category not found')),
          );
          return;
        }
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(category.name),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('ID: ${category.id}'),
                  Text('UID: ${category.uid}'),
                  if (category.urlKey != null) Text('URL Key: ${category.urlKey}'),
                  if (category.description != null) Text('Description: ${category.description}'),
                  if (category.productCount != null) Text('Products: ${category.productCount}'),
                ],
              ),
            ),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => context.push('/cart'),
            tooltip: 'Cart',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategoryTree,
            tooltip: 'Refresh',
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCategoryTree,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _categories == null || _categories!.isEmpty
          ? const Center(child: Text('No categories found'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories!.length,
                    itemBuilder: (context, index) {
                      return _buildCategoryCard(_categories![index]);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryCard(MagentoCategory category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.category),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: category.productCount != null
            ? Text('${category.productCount} products')
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (category.description != null) ...[
                  Text(
                    category.description!,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (category.id.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () => context.push('/products'),
                        icon: const Icon(Icons.shopping_bag),
                        label: const Text('View Products'),
                      ),
                    if (category.id.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () => _getCategoryById(category.id),
                        icon: const Icon(Icons.info),
                        label: const Text('Details'),
                      ),
                  ],
                ),
                if (category.children != null &&
                    category.children!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Subcategories:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...category.children!.map((child) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: _buildCategoryCard(child),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
