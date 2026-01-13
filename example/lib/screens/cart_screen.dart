import 'package:flutter/material.dart';
import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';
import '../services/magento_service.dart';
import '../services/cart_service.dart';
import 'product_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;
  MagentoCart? _cart;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cartId = CartService.cartId;
      if (cartId == null || cartId.isEmpty) {
        setState(() {
          _cart = null;
          _isLoading = false;
        });
        return;
      }

      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      final cart = await sdk.cart.getCart(cartId);
      CartService.updateCart(cart);

      setState(() {
        _cart = cart;
      });
    } catch (e, stackTrace) {
      print('[CartScreen] Error loading cart: ${e.toString()}');
      print('[CartScreen] Stack trace: $stackTrace');
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshCart() async {
    setState(() {
      _isRefreshing = true;
    });

    await CartService.refreshCart();
    await _loadCart();

    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _updateQuantity(MagentoCartItem item, int newQuantity) async {
    if (newQuantity < 1) {
      await _removeItem(item);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      final cartId = CartService.cartId;
      if (cartId == null) {
        throw Exception('Cart ID not found');
      }

      final updatedCart = await sdk.cart.updateCartItem(
        cartId: cartId,
        itemId: item.id,
        quantity: newQuantity,
      );

      CartService.updateCart(updatedCart);

      setState(() {
        _cart = updatedCart;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart updated'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('[CartScreen] Error updating quantity: ${e.toString()}');
      print('[CartScreen] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeItem(MagentoCartItem item) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      final cartId = CartService.cartId;
      if (cartId == null) {
        throw Exception('Cart ID not found');
      }

      final updatedCart = await sdk.cart.removeCartItem(
        cartId: cartId,
        itemId: item.id,
      );

      CartService.updateCart(updatedCart);

      setState(() {
        _cart = updatedCart;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.product.name} removed from cart'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('[CartScreen] Error removing item: ${e.toString()}');
      print('[CartScreen] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: const Text('Shopping Cart'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshCart,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading && _cart == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _cart == null
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
                        onPressed: _loadCart,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _cart == null || _cart!.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Your cart is empty',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _cart!.items.length,
                            itemBuilder: (context, index) {
                              return _buildCartItemCard(_cart!.items[index]);
                            },
                          ),
                        ),
                        _buildCartSummary(),
                      ],
                    ),
    );
  }

  Widget _buildCartItemCard(MagentoCartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.product.images.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.product.images.first.url,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(product: item.product),
                            ),
                          );
                        },
                        child: Text(
                          item.product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${item.product.sku}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      if (item.prices?.price != null)
                        Text(
                          '${item.prices!.price!.currency} ${item.prices!.price!.value.toStringAsFixed(2)} each',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (item.prices?.rowTotal != null)
                        Text(
                          'Total: ${item.prices!.rowTotal!.currency} ${item.prices!.rowTotal!.value.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _isLoading
                      ? null
                      : () => _removeItem(item),
                  tooltip: 'Remove',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Quantity: '),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _isLoading || item.quantity <= 1
                      ? null
                      : () => _updateQuantity(item, item.quantity - 1),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.quantity.toString(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _isLoading
                      ? null
                      : () => _updateQuantity(item, item.quantity + 1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    if (_cart == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_cart!.prices?.subtotalExcludingTax != null)
            _buildSummaryRow(
              'Subtotal',
              '${_cart!.prices!.subtotalExcludingTax!.currency} ${_cart!.prices!.subtotalExcludingTax!.value.toStringAsFixed(2)}',
            ),
          if (_cart!.prices?.subtotalIncludingTax != null &&
              _cart!.prices!.subtotalIncludingTax!.value !=
                  _cart!.prices!.subtotalExcludingTax?.value)
            _buildSummaryRow(
              'Tax',
              '${_cart!.prices!.subtotalIncludingTax!.currency} ${(_cart!.prices!.subtotalIncludingTax!.value - (_cart!.prices!.subtotalExcludingTax?.value ?? 0)).toStringAsFixed(2)}',
            ),
          const Divider(),
          if (_cart!.prices?.grandTotal != null)
            _buildSummaryRow(
              'Grand Total',
              '${_cart!.prices!.grandTotal!.currency} ${_cart!.prices!.grandTotal!.value.toStringAsFixed(2)}',
              isTotal: true,
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Checkout functionality not implemented in Phase 1'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Proceed to Checkout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}
