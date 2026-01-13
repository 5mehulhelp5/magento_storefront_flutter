import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';
import 'magento_service.dart';

/// Service class to manage cart state
class CartService {
  static String? _cartId;
  static MagentoCart? _currentCart;

  /// Get current cart ID
  static String? get cartId => _cartId;

  /// Get current cart
  static MagentoCart? get currentCart => _currentCart;

  /// Get cart item count
  static int get itemCount => _currentCart?.totalQuantity ?? 0;

  /// Initialize or get cart
  static Future<String> getOrCreateCart() async {
    if (_cartId != null && _cartId!.isNotEmpty) {
      return _cartId!;
    }

    final sdk = MagentoService.sdk;
    if (sdk == null) {
      throw Exception('SDK not initialized');
    }

    final cart = await sdk.cart.createCart();
    _cartId = cart.id;
    _currentCart = cart;
    return _cartId!;
  }

  /// Add product to cart
  static Future<MagentoCart> addToCart({
    required String sku,
    int quantity = 1,
  }) async {
    final sdk = MagentoService.sdk;
    if (sdk == null) {
      throw Exception('SDK not initialized');
    }

    final cartId = await getOrCreateCart();
    final updatedCart = await sdk.cart.addProductToCart(
      cartId: cartId,
      sku: sku,
      quantity: quantity,
    );

    _currentCart = updatedCart;
    return updatedCart;
  }

  /// Refresh cart
  static Future<void> refreshCart() async {
    if (_cartId == null || _cartId!.isEmpty) {
      return;
    }

    final sdk = MagentoService.sdk;
    if (sdk == null) {
      return;
    }

    try {
      final cart = await sdk.cart.getCart(_cartId!);
      _currentCart = cart;
    } catch (e, stackTrace) {
      print('[CartService] Error refreshing cart: ${e.toString()}');
      print('[CartService] Stack trace: $stackTrace');
      // Cart might have been deleted, reset
      _cartId = null;
      _currentCart = null;
    }
  }

  /// Update cart state (internal use)
  static void updateCart(MagentoCart? cart) {
    _currentCart = cart;
    if (cart != null) {
      _cartId = cart.id;
    }
  }

  /// Clear cart
  static void clearCart() {
    _cartId = null;
    _currentCart = null;
  }
}
