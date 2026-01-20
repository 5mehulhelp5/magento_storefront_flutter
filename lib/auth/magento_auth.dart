import '../core/magento_client.dart';
import '../core/magento_exception.dart';
import '../core/magento_logger.dart';
import '../core/magento_storage.dart';
import '../cart/magento_cart.dart';
import '../models/cart/cart.dart' as models;

/// Authentication result containing the token
class MagentoAuthResult {
  final String token;
  final String? customerCartId;

  MagentoAuthResult({required this.token, this.customerCartId});
}

/// Authentication module for Magento Storefront
class MagentoAuth {
  final MagentoClient _client;
  final MagentoCartModule? _cartModule;

  MagentoAuth(this._client, [this._cartModule]);

  /// Login with email and password
  ///
  /// Returns a token that can be used for authenticated requests.
  /// If a guest cart with items exists, it will be merged into the customer cart after login.
  ///
  /// Example:
  /// ```dart
  /// final result = await MagentoAuth.login('user@example.com', 'password');
  /// client.setAuthToken(result.token);
  /// ```
  Future<MagentoAuthResult> login(String email, String password) async {
    // Check for existing cart before login
    String? guestCartId;
    models.MagentoCart? guestCart;

    if (_cartModule != null) {
      try {
        // First, check if there's a current cart ID (active cart before login)
        String? currentCartId = MagentoStorage.instance.loadCurrentCartId();

        // If we have a current cart ID, check if it has items
        if (currentCartId != null && currentCartId.isNotEmpty) {
          guestCart = await _cartModule.getCart(currentCartId);

          // If cart has items, save it as guest cart ID for merging
          if (guestCart != null && guestCart.items.isNotEmpty) {
            guestCartId = currentCartId;
            await MagentoStorage.instance.saveGuestCartId(guestCartId);
            MagentoLogger.debug(
              '[MagentoAuth] Found guest cart with ${guestCart.items.length} items',
            );
          } else {
            // Cart is empty or doesn't exist, clear it
            await MagentoStorage.instance.clearCurrentCartId();
          }
        } else {
          // Fallback: check if there's already a saved guest cart ID
          guestCartId = MagentoStorage.instance.loadGuestCartId();

          if (guestCartId != null && guestCartId.isNotEmpty) {
            guestCart = await _cartModule.getCart(guestCartId);

            // If cart is empty or doesn't exist, clear the stored ID
            if (guestCart == null || guestCart.items.isEmpty) {
              guestCartId = null;
              await MagentoStorage.instance.clearGuestCartId();
            }
          }
        }
      } catch (e) {
        // If we can't retrieve the cart, continue without merging
        MagentoLogger.error(
          '[MagentoAuth] Error checking cart before login: ${e.toString()}',
          e,
        );
        guestCartId = null;
      }
    }

    final query = '''
      mutation GenerateCustomerToken(\$email: String!, \$password: String!) {
        generateCustomerToken(email: \$email, password: \$password) {
          token
        }
      }
    ''';

    try {
      final response = await _client.mutate(
        query,
        variables: {'email': email, 'password': password},
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoAuthenticationException('Invalid response from server');
      }

      final tokenData = data['generateCustomerToken'] as Map<String, dynamic>?;
      if (tokenData == null) {
        throw MagentoAuthenticationException('Failed to generate token');
      }

      final token = tokenData['token'] as String?;
      if (token == null || token.isEmpty) {
        throw MagentoAuthenticationException('Token is empty');
      }

      // Set token in client
      _client.setAuthToken(token);

      // Save token to storage
      try {
        await MagentoStorage.instance.saveAuthToken(token);
      } catch (e) {
        // Storage might not be initialized, ignore silently
      }

      // Handle cart merge if guest cart exists with items
      String? customerCartId;
      if (_cartModule != null &&
          guestCartId != null &&
          guestCart != null &&
          guestCart.items.isNotEmpty) {
        try {
          // Create a new customer cart
          final customerCart = await _cartModule.createCart();
          customerCartId = customerCart.id;

          // Merge guest cart items into customer cart
          // Use mergeCartItems instead of mergeCarts to avoid accessing guest cart after auth
          await _cartModule.mergeCartItems(
            cartItems: guestCart.items,
            destinationCartId: customerCartId,
          );

          // After successful merge:
          // 1. Save new customer cart ID to storage (this becomes the current cart)
          await MagentoStorage.instance.saveCustomerCartId(customerCartId);
          await MagentoStorage.instance.saveCurrentCartId(customerCartId);

          // 2. Remove guest cart ID from storage (no longer needed)
          await MagentoStorage.instance.clearGuestCartId();

          MagentoLogger.debug(
            '[MagentoAuth] Successfully merged guest cart into customer cart',
          );
        } catch (e, stackTrace) {
          // Log error but don't fail login
          MagentoLogger.error(
            '[MagentoAuth] Failed to merge carts: ${e.toString()}',
            e,
            stackTrace,
          );
          // Still create customer cart even if merge fails
          try {
            final customerCart = await _cartModule.createCart();
            customerCartId = customerCart.id;
            await MagentoStorage.instance.saveCustomerCartId(customerCartId);
            await MagentoStorage.instance.saveCurrentCartId(customerCartId);
          } catch (createError) {
            // Ignore cart creation errors
            MagentoLogger.error(
              '[MagentoAuth] Failed to create customer cart: ${createError.toString()}',
              createError,
            );
          }
        }
      } else if (_cartModule != null) {
        // Create customer cart even if no guest cart to merge
        try {
          final customerCart = await _cartModule.createCart();
          customerCartId = customerCart.id;
          await MagentoStorage.instance.saveCustomerCartId(customerCartId);
          await MagentoStorage.instance.saveCurrentCartId(customerCartId);
        } catch (e) {
          // Ignore cart creation errors
          MagentoLogger.error(
            '[MagentoAuth] Failed to create customer cart: ${e.toString()}',
            e,
          );
        }
      }

      return MagentoAuthResult(token: token, customerCartId: customerCartId);
    } on MagentoException catch (e) {
      MagentoLogger.error('[MagentoAuth] Login error: ${e.toString()}', e);
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoAuth] Login failed: ${e.toString()}',
        e,
        stackTrace,
      );
      throw MagentoAuthenticationException(
        'Login failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Register a new customer
  ///
  /// Example:
  /// ```dart
  /// await MagentoAuth.register(
  ///   email: 'user@example.com',
  ///   password: 'password',
  ///   firstName: 'John',
  ///   lastName: 'Doe',
  /// );
  /// ```
  Future<MagentoAuthResult> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final query = '''
      mutation CreateCustomer(
        \$email: String!,
        \$password: String!,
        \$firstName: String!,
        \$lastName: String!
      ) {
        createCustomer(
          input: {
            email: \$email,
            password: \$password,
            firstname: \$firstName,
            lastname: \$lastName
          }
        ) {
          customer {
            email
            firstname
            lastname
          }
        }
      }
    ''';

    try {
      final response = await _client.mutate(
        query,
        variables: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
        },
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoAuthenticationException('Invalid response from server');
      }

      final createCustomerData =
          data['createCustomer'] as Map<String, dynamic>?;
      if (createCustomerData == null) {
        throw MagentoAuthenticationException('Failed to create customer');
      }

      // After successful registration, automatically login
      return await login(email, password);
    } on MagentoException catch (e) {
      MagentoLogger.error(
        '[MagentoAuth] Registration error: ${e.toString()}',
        e,
      );
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoAuth] Registration failed: ${e.toString()}',
        e,
        stackTrace,
      );
      throw MagentoAuthenticationException(
        'Registration failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Request password reset email
  ///
  /// Example:
  /// ```dart
  /// await MagentoAuth.forgotPassword('user@example.com');
  /// ```
  Future<void> forgotPassword(String email) async {
    final query = '''
      mutation RequestPasswordResetEmail(\$email: String!) {
        requestPasswordResetEmail(email: \$email)
      }
    ''';

    try {
      final response = await _client.mutate(query, variables: {'email': email});

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoAuthenticationException('Invalid response from server');
      }

      final success = data['requestPasswordResetEmail'] as bool?;
      if (success != true) {
        throw MagentoAuthenticationException(
          'Failed to send password reset email',
        );
      }
    } on MagentoException catch (e) {
      MagentoLogger.error(
        '[MagentoAuth] Forgot password error: ${e.toString()}',
        e,
      );
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoAuth] Forgot password failed: ${e.toString()}',
        e,
        stackTrace,
      );
      throw MagentoAuthenticationException(
        'Forgot password request failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Logout (client-side token clear only)
  ///
  /// This only clears the token from the client.
  /// The token remains valid on the server until it expires.
  ///
  /// Example:
  /// ```dart
  /// MagentoAuth.logout();
  /// ```
  Future<void> logout() async {
    _client.setAuthToken(null);

    // Clear token and customer cart from storage
    try {
      await MagentoStorage.instance.clearAuthToken();
      await MagentoStorage.instance.clearCustomerCartId();
      // Note: We keep currentCartId in case user wants to continue as guest
    } catch (e) {
      // Storage might not be initialized, ignore silently
    }
  }

  /// Check if user is currently authenticated
  bool get isAuthenticated => _client.authToken != null;
}
