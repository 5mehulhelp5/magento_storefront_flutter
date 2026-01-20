import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';
import '../../services/magento_service.dart';
import '../../services/cart_service.dart';
import 'product_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _skuController = TextEditingController();
  final _urlKeyController = TextEditingController();
  final _categoryIdController = TextEditingController();
  bool _isLoading = false;
  final Set<String> _addingToCartSkus = {}; // Track products being added to cart
  String? _error;
  List<MagentoProduct>? _products;
  MagentoProduct? _singleProduct;

  @override
  void dispose() {
    _skuController.dispose();
    _urlKeyController.dispose();
    _categoryIdController.dispose();
    super.dispose();
  }

  Future<void> _getProductBySku() async {
    if (_skuController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter a SKU';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _products = null;
      _singleProduct = null;
    });

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      final product = await sdk.products.getProductBySku(_skuController.text.trim());

      setState(() {
        _singleProduct = product;
        if (product == null) {
          _error = 'Product not found';
        }
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

  Future<void> _getProductByUrlKey() async {
    if (_urlKeyController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter a URL key';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _products = null;
      _singleProduct = null;
    });

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      final product = await sdk.products.getProductByUrlKey(_urlKeyController.text.trim());

      setState(() {
        _singleProduct = product;
        if (product == null) {
          _error = 'Product not found';
        }
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

  Future<void> _getProductsByCategory() async {
    if (_categoryIdController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter a category ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _singleProduct = null;
      _products = null;
    });

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      final result = await sdk.products.getProductsByCategoryId(
        categoryId: _categoryIdController.text.trim(),
        pageSize: 20,
        currentPage: 1,
      );

      setState(() {
        _products = result.products;
        if (result.products.isEmpty) {
          _error = 'No products found in this category';
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => context.push('/cart'),
            tooltip: 'Cart',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Get by SKU
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Get Product by SKU',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _skuController,
                            decoration: const InputDecoration(
                              labelText: 'SKU',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.tag),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _getProductBySku,
                            child: const Text('Get Product'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Get by URL Key
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Get Product by URL Key',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _urlKeyController,
                            decoration: const InputDecoration(
                              labelText: 'URL Key',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.link),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _getProductByUrlKey,
                            child: const Text('Get Product'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Get by Category
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Get Products by Category',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _categoryIdController,
                            decoration: const InputDecoration(
                              labelText: 'Category ID',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _getProductsByCategory,
                            child: const Text('Get Products'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_error != null)
                    Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ),
                  if (_singleProduct != null)
                    _buildProductCard(_singleProduct!),
                  if (_products != null && _products!.isNotEmpty)
                    ..._products!.map((p) => _buildProductCard(p)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(MagentoProduct product) {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (product.priceRange?.minimumPrice?.finalPrice != null)
                    Text(
                      '${product.priceRange!.minimumPrice!.finalPrice!.currency} ${product.priceRange!.minimumPrice!.finalPrice!.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text('SKU: ${product.sku}'),
              if (product.shortDescription != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    product.shortDescription!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (product.images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Image.network(
                    product.images.first.url,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported, size: 100);
                    },
                  ),
                ),
              const SizedBox(height: 12),
              // Add to Cart Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isLoading || _addingToCartSkus.contains(product.sku))
                      ? null
                      : () => _addToCart(product),
                  icon: _addingToCartSkus.contains(product.sku)
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.shopping_cart),
                  label: Text(
                    _addingToCartSkus.contains(product.sku)
                        ? 'Adding...'
                        : 'Add to Cart',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToCart(MagentoProduct product) async {
    // Prevent multiple concurrent requests for the same product
    if (_addingToCartSkus.contains(product.sku)) {
      return;
    }

    setState(() {
      _addingToCartSkus.add(product.sku);
    });

    try {
      await CartService.addToCart(
        sku: product.sku,
        quantity: 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Navigate to cart screen
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _addingToCartSkus.remove(product.sku);
        });
      }
    }
  }
}
