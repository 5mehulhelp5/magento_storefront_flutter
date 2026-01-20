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
      final sdk = MagentoService.sdk;
      final isAuthenticated = sdk?.auth.isAuthenticated == true;

      // If authenticated, NEVER fall back to guest/current cart id (that causes 403)
      if (isAuthenticated) {
        final customerCartId = MagentoStorage.instance.loadCustomerCartId();
        if (customerCartId != null && customerCartId.isNotEmpty) {
          _cartId = customerCartId;
        }
        return;
      }

      // Guest mode: use current cart id
      final currentCartId = MagentoStorage.instance.loadCurrentCartId();
      if (currentCartId != null && currentCartId.isNotEmpty) {
        _cartId = currentCartId;
      }
    } catch (e) {
      // Storage might not be initialized, ignore
    }
  }

  /// Ensure the SDK is aware of the guest cart **before** login.
  ///
  /// This is critical because the SDK merges carts based on its internal
  /// `sdk.cart.guestCartId`, which is set when calling `createCart()`/`getCart()`
  /// while unauthenticated.
  static Future<void> prepareGuestCartForLogin() async {
    final sdk = MagentoService.sdk;
    if (sdk == null) throw Exception('SDK not initialized');
    if (sdk.auth.isAuthenticated) return;

    // Make sure we have a guest cart id and the SDK has touched it (getCart sets guestCartId internally)
    final cartId = await getOrCreateCart();
    try {
      await sdk.cart.getCart(cartId);
    } catch (_) {
      // Ignore; if cart is invalid it will be recreated by getOrCreateCart() on next call.
    }

    // Persist guest/current cart id for app-side tracking
    try {
      await MagentoStorage.instance.saveCurrentCartId(cartId);
      await MagentoStorage.instance.saveGuestCartId(cartId);
    } catch (_) {
      // ignore
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

    // If authenticated, prefer the customer cart over any stored id
    if (sdk.auth.isAuthenticated) {
      try {
        final customerCart = await sdk.cart.getCustomerCart();
        if (customerCart != null) {
          _cartId = customerCart.id;
          _currentCart = customerCart;
          try {
            await MagentoStorage.instance.saveCustomerCartId(customerCart.id);
          } catch (_) {}
          return _cartId!;
        }
      } catch (_) {
        // continue to createCart()
      }
    }

    final cart = await sdk.cart.createCart();
    _cartId = cart.id;
    _currentCart = cart;

    // Save to storage
    try {
      if (sdk.auth.isAuthenticated) {
        await MagentoStorage.instance.saveCustomerCartId(cart.id);
        await MagentoStorage.instance.clearCurrentCartId();
        await MagentoStorage.instance.clearGuestCartId();
      } else {
        await MagentoStorage.instance.saveCurrentCartId(cart.id);
        await MagentoStorage.instance.saveGuestCartId(cart.id);
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
      if (sdk.auth.isAuthenticated) {
        // Authenticated users should use customerCart, not cart(cart_id: ...)
        final customerCart = await sdk.cart.getCustomerCart();
        _currentCart = customerCart;
        if (customerCart != null) {
          _cartId = customerCart.id;
          try {
            await MagentoStorage.instance.saveCustomerCartId(customerCart.id);
            await MagentoStorage.instance.clearCurrentCartId();
            await MagentoStorage.instance.clearGuestCartId();
          } catch (_) {}
        }
      } else {
        final cart = await sdk.cart.getCart(_cartId!);
        _currentCart = cart;
        if (cart != null) {
          _cartId = cart.id;
          try {
            await MagentoStorage.instance.saveCurrentCartId(cart.id);
            await MagentoStorage.instance.saveGuestCartId(cart.id);
          } catch (_) {}
        }
      }
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

  /// Call this immediately after successful login/register.
  ///
  /// It switches the example app from guest cart id → customer cart id, and
  /// clears any guest/current ids to prevent 403s.
  static Future<void> syncAfterLogin() async {
    final sdk = MagentoService.sdk;
    if (sdk == null) return;
    if (!sdk.auth.isAuthenticated) return;

    try {
      var customerCart = await sdk.cart.getCustomerCart();
      customerCart ??= await sdk.cart.createCart();

      _currentCart = customerCart;
      _cartId = customerCart.id;

      try {
        await MagentoStorage.instance.saveCustomerCartId(customerCart.id);
        await MagentoStorage.instance.clearCurrentCartId();
        await MagentoStorage.instance.clearGuestCartId();
      } catch (_) {}
    } catch (e) {
      print('[CartService] syncAfterLogin failed: ${e.toString()}');
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
