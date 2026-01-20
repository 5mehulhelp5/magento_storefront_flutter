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

  /// Load cart ID from storage
  /// This should be called after login to update the cart ID
  static Future<void> loadCartIdFromStorage() async {
    try {
      // Try to load customer cart ID first (if authenticated)
      final customerCartId = MagentoStorage.instance.loadCustomerCartId();
      if (customerCartId != null && customerCartId.isNotEmpty) {
        _cartId = customerCartId;
        return;
      }

      // Fallback to current cart ID
      final currentCartId = MagentoStorage.instance.loadCurrentCartId();
      if (currentCartId != null && currentCartId.isNotEmpty) {
        _cartId = currentCartId;
        return;
      }
    } catch (e) {
      // Storage might not be initialized, ignore
    }
  }

  /// Initialize or get cart
  static Future<String> getOrCreateCart() async {
    // First, try to load cart ID from storage
    await loadCartIdFromStorage();

    if (_cartId != null && _cartId!.isNotEmpty) {
      // Verify the cart still exists
      try {
        final sdk = MagentoService.sdk;
        if (sdk != null) {
          final cart = await sdk.cart.getCart(_cartId!);
          _currentCart = cart;
          return _cartId!;
        }
      } catch (e) {
        // Cart doesn't exist or can't be accessed, create a new one
        _cartId = null;
        _currentCart = null;
      }
    }

    final sdk = MagentoService.sdk;
    if (sdk == null) {
      throw Exception('SDK not initialized');
    }

    final cart = await sdk.cart.createCart();
    _cartId = cart.id;
    _currentCart = cart;

    // Save to storage if not authenticated
    try {
      final isAuthenticated = sdk.auth.isAuthenticated;
      if (!isAuthenticated) {
        await MagentoStorage.instance.saveCurrentCartId(cart.id);
      }
    } catch (e) {
      // Storage might not be initialized, ignore
    }

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
    // First, try to load cart ID from storage (in case it was updated after login)
    await loadCartIdFromStorage();

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
      // Cart might have been deleted or is inaccessible, try to load from storage
      await loadCartIdFromStorage();
      
      // If still no cart ID, reset
      if (_cartId == null || _cartId!.isEmpty) {
        _cartId = null;
        _currentCart = null;
      }
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
