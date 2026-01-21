import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';
import '../../services/magento_service.dart';
import '../../services/cart_service.dart';
import '../products/product_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  final Set<String> _addingToCartSkus =
      {}; // Track products being added to cart
  String? _error;
  MagentoProductListResult? _searchResults;
  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchProducts({bool loadMore = false}) async {
    if (_searchController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter a search query';
      });
      return;
    }

    if (loadMore) {
      _currentPage++;
    } else {
      _currentPage = 1;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      if (!loadMore) {
        _searchResults = null;
      }
    });

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      final results = await sdk.search.searchProducts(
        query: _searchController.text.trim(),
        pageSize: _pageSize,
        currentPage: _currentPage,
      );

      setState(() {
        if (loadMore && _searchResults != null) {
          _searchResults = MagentoProductListResult(
            products: [..._searchResults!.products, ...results.products],
            totalCount: results.totalCount,
            currentPage: results.currentPage,
            pageSize: results.pageSize,
            totalPages: results.totalPages,
          );
        } else {
          _searchResults = results;
        }
        if (results.products.isEmpty) {
          _error = 'No products found';
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
        title: const Text('Search'),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Search products',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _searchProducts(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _searchProducts(),
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          if (_isLoading && _searchResults == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null && _searchResults == null)
            Expanded(
              child: Center(
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
                      onPressed: () => _searchProducts(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else if (_searchResults != null)
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Found ${_searchResults!.totalCount} products',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (_searchResults!.totalPages > 1)
                          Text(
                            'Page ${_searchResults!.currentPage} of ${_searchResults!.totalPages}',
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          _searchResults!.products.length +
                          (_searchResults!.currentPage <
                                  _searchResults!.totalPages
                              ? 1
                              : 0),
                      itemBuilder: (context, index) {
                        if (index == _searchResults!.products.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator()
                                  : ElevatedButton(
                                      onPressed: () =>
                                          _searchProducts(loadMore: true),
                                      child: const Text('Load More'),
                                    ),
                            ),
                          );
                        }
                        return _buildProductCard(
                          _searchResults!.products[index],
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          else
            const Expanded(
              child: Center(
                child: Text('Enter a search query to find products'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductCard(MagentoProduct product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.images.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.images.first.url,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            width: 80,
                            height: 80,
                            child: Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${product.sku}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        if (product.priceRange?.minimumPrice?.finalPrice !=
                            null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${product.priceRange!.minimumPrice!.finalPrice!.currency} ${product.priceRange!.minimumPrice!.finalPrice!.value.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              // Add to Cart Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      (_isLoading || _addingToCartSkus.contains(product.sku))
                      ? null
                      : () => _addToCart(product),
                  icon: _addingToCartSkus.contains(product.sku)
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.shopping_cart, size: 18),
                  label: Text(
                    _addingToCartSkus.contains(product.sku)
                        ? 'Adding...'
                        : 'Add to Cart',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
      await CartService.addToCart(sku: product.sku, quantity: 1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
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
