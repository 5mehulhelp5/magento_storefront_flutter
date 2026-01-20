import '../core/magento_client.dart';
import '../core/magento_exception.dart';
import '../core/magento_logger.dart';
import '../core/magento_storage.dart';
import '../models/cart/cart.dart' as models;

/// Cart module for Magento Storefront
class MagentoCartModule {
  final MagentoClient _client;

  MagentoCartModule(this._client);

  /// Create a new cart
  ///
  /// Example:
  /// ```dart
  /// final cart = await MagentoCartModule.createCart();
  /// ```
  Future<models.MagentoCart> createCart() async {
    final query = '''
      mutation CreateCart {
        createEmptyCart
      }
    ''';

    try {
      final response = await _client.mutate(query);

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final cartId = data['createEmptyCart'] as String?;
      if (cartId == null || cartId.isEmpty) {
        throw MagentoException('Failed to create cart');
      }

      // Save cart ID to storage (only if user is not authenticated)
      try {
        final isAuthenticated = _client.authToken != null;
        if (!isAuthenticated) {
          await MagentoStorage.instance.saveCurrentCartId(cartId);
        }
      } catch (e) {
        // Storage might not be initialized, ignore silently
      }

      // Return cart with the new ID
      return models.MagentoCart(
        id: cartId,
        items: [],
        totalQuantity: 0,
        isEmpty: true,
      );
    } on MagentoException catch (e) {
      MagentoLogger.error(
        '[MagentoCart] Create cart error: ${e.toString()}',
        e,
      );
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoCart] Failed to create cart: ${e.toString()}',
        e,
        stackTrace,
      );
      throw MagentoException(
        'Failed to create cart: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Add product to cart
  ///
  /// Example:
  /// ```dart
  /// final cart = await MagentoCartModule.addProductToCart(
  ///   cartId: 'cart-id',
  ///   sku: 'product-sku',
  ///   quantity: 1,
  /// );
  /// ```
  Future<models.MagentoCart> addProductToCart({
    required String cartId,
    required String sku,
    int quantity = 1,
  }) async {
    final query = '''
      mutation AddProductToCart(
        \$cartId: String!,
        \$sku: String!,
        \$quantity: Float!
      ) {
        addProductsToCart(
          cartId: \$cartId,
          cartItems: [
            {
              sku: \$sku,
              quantity: \$quantity
            }
          ]
        ) {
          cart {
            id
            items {
              id
              quantity
              product {
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
              prices {
                price {
                  value
                  currency
                }
                row_total {
                  value
                  currency
                }
              }
            }
            prices {
              grand_total {
                value
                currency
              }
              subtotal_excluding_tax {
                value
                currency
              }
              subtotal_including_tax {
                value
                currency
              }
            }
            total_quantity
          }
        }
      }
    ''';

    try {
      final response = await _client.mutate(
        query,
        variables: {
          'cartId': cartId,
          'sku': sku,
          'quantity': quantity.toDouble(),
        },
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final addProductsData =
          data['addProductsToCart'] as Map<String, dynamic>?;
      if (addProductsData == null) {
        throw MagentoException('Failed to add product to cart');
      }

      final cartData = addProductsData['cart'] as Map<String, dynamic>?;
      if (cartData == null) {
        throw MagentoException('Cart data not found in response');
      }

      final updatedCart = models.MagentoCart.fromJson(cartData);

      // Save cart ID to storage (only if user is not authenticated)
      try {
        final isAuthenticated = _client.authToken != null;
        if (!isAuthenticated) {
          await MagentoStorage.instance.saveCurrentCartId(cartId);
        }
      } catch (e) {
        // Storage might not be initialized, ignore silently
      }

      return updatedCart;
    } on MagentoException catch (e) {
      MagentoLogger.error(
        '[MagentoCart] Add product to cart error: ${e.toString()}',
        e,
      );
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoCart] Failed to add product to cart: ${e.toString()}',
        e,
        stackTrace,
      );
      throw MagentoException(
        'Failed to add product to cart: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get cart by ID
  ///
  /// Example:
  /// ```dart
  /// final cart = await MagentoCartModule.getCart('cart-id');
  /// ```
  Future<models.MagentoCart?> getCart(String cartId) async {
    final query = '''
      query GetCart(\$cartId: String!) {
        cart(cart_id: \$cartId) {
          id
          items {
            id
            quantity
            product {
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
            prices {
              price {
                value
                currency
              }
              row_total {
                value
                currency
              }
            }
          }
          prices {
            grand_total {
              value
              currency
            }
            subtotal_excluding_tax {
              value
              currency
            }
            subtotal_including_tax {
              value
              currency
            }
          }
          total_quantity
        }
      }
    ''';

    try {
      final response = await _client.query(
        query,
        variables: {'cartId': cartId},
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final cartData = data['cart'] as Map<String, dynamic>?;
      if (cartData == null) {
        return null;
      }

      return models.MagentoCart.fromJson(cartData);
    } on MagentoException catch (e) {
      MagentoLogger.error('[MagentoCart] Get cart error: ${e.toString()}', e);
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoCart] Failed to get cart: ${e.toString()}',
        e,
        stackTrace,
      );
      throw MagentoException(
        'Failed to get cart: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Update cart item quantity
  ///
  /// Example:
  /// ```dart
  /// final cart = await MagentoCartModule.updateCartItem(
  ///   cartId: 'cart-id',
  ///   itemId: 'item-id',
  ///   quantity: 2,
  /// );
  /// ```
  Future<models.MagentoCart> updateCartItem({
    required String cartId,
    required String itemId,
    required int quantity,
  }) async {
    // Convert itemId to int as Magento expects Int type
    final itemIdInt = int.tryParse(itemId);
    if (itemIdInt == null) {
      throw MagentoException('Invalid cart item ID: $itemId');
    }

    final query = '''
      mutation UpdateCartItem(
        \$cartId: String!,
        \$itemId: Int!,
        \$quantity: Float!
      ) {
        updateCartItems(
          input: {
            cart_id: \$cartId,
            cart_items: [
              {
                cart_item_id: \$itemId,
                quantity: \$quantity
              }
            ]
          }
        ) {
          cart {
            id
            items {
              id
              quantity
              product {
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
              prices {
                price {
                  value
                  currency
                }
                row_total {
                  value
                  currency
                }
              }
            }
            prices {
              grand_total {
                value
                currency
              }
              subtotal_excluding_tax {
                value
                currency
              }
              subtotal_including_tax {
                value
                currency
              }
            }
            total_quantity
          }
        }
      }
    ''';

    try {
      final response = await _client.mutate(
        query,
        variables: {
          'cartId': cartId,
          'itemId': itemIdInt,
          'quantity': quantity.toDouble(),
        },
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final updateCartData = data['updateCartItems'] as Map<String, dynamic>?;
      if (updateCartData == null) {
        throw MagentoException('Failed to update cart item');
      }

      final cartData = updateCartData['cart'] as Map<String, dynamic>?;
      if (cartData == null) {
        throw MagentoException('Cart data not found in response');
      }

      return models.MagentoCart.fromJson(cartData);
    } on MagentoException catch (e) {
      MagentoLogger.error(
        '[MagentoCart] Update cart item error: ${e.toString()}',
        e,
      );
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoCart] Failed to update cart item: ${e.toString()}',
        e,
        stackTrace,
      );
      throw MagentoException(
        'Failed to update cart item: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Remove item from cart
  ///
  /// Example:
  /// ```dart
  /// final cart = await MagentoCartModule.removeCartItem(
  ///   cartId: 'cart-id',
  ///   itemId: 'item-id',
  /// );
  /// ```
  Future<models.MagentoCart> removeCartItem({
    required String cartId,
    required String itemId,
  }) async {
    // Convert itemId to int as Magento expects Int type
    final itemIdInt = int.tryParse(itemId);
    if (itemIdInt == null) {
      throw MagentoException('Invalid cart item ID: $itemId');
    }

    final query = '''
      mutation RemoveCartItem(
        \$cartId: String!,
        \$itemId: Int!
      ) {
        removeItemFromCart(
          input: {
            cart_id: \$cartId,
            cart_item_id: \$itemId
          }
        ) {
          cart {
            id
            items {
              id
              quantity
              product {
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
              prices {
                price {
                  value
                  currency
                }
                row_total {
                  value
                  currency
                }
              }
            }
            prices {
              grand_total {
                value
                currency
              }
              subtotal_excluding_tax {
                value
                currency
              }
              subtotal_including_tax {
                value
                currency
              }
            }
            total_quantity
          }
        }
      }
    ''';

    try {
      final response = await _client.mutate(
        query,
        variables: {'cartId': cartId, 'itemId': itemIdInt},
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final removeItemData =
          data['removeItemFromCart'] as Map<String, dynamic>?;
      if (removeItemData == null) {
        throw MagentoException('Failed to remove cart item');
      }

      final cartData = removeItemData['cart'] as Map<String, dynamic>?;
      if (cartData == null) {
        throw MagentoException('Cart data not found in response');
      }

      return models.MagentoCart.fromJson(cartData);
    } on MagentoException catch (e) {
      MagentoLogger.error(
        '[MagentoCart] Remove cart item error: ${e.toString()}',
        e,
      );
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoCart] Failed to remove cart item: ${e.toString()}',
        e,
        stackTrace,
      );
      throw MagentoException(
        'Failed to remove cart item: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Merge items from source cart into destination cart
  ///
  /// This method retrieves items from the source cart and adds them to the destination cart.
  /// If an item with the same SKU already exists in the destination cart, the quantities are combined.
  ///
  /// Note: This method requires access to the source cart. If the source cart is a guest cart
  /// and the user is now authenticated, use [mergeCartItems] instead.
  ///
  /// Example:
  /// ```dart
  /// final mergedCart = await MagentoCartModule.mergeCarts(
  ///   sourceCartId: 'guest-cart-id',
  ///   destinationCartId: 'customer-cart-id',
  /// );
  /// ```
  Future<models.MagentoCart> mergeCarts({
    required String sourceCartId,
    required String destinationCartId,
  }) async {
    try {
      // Get source cart items
      final sourceCart = await getCart(sourceCartId);
      if (sourceCart == null || sourceCart.items.isEmpty) {
        // No items to merge, return destination cart
        final destCart = await getCart(destinationCartId);
        if (destCart == null) {
          throw MagentoException('Destination cart not found');
        }
        return destCart;
      }

      // Use the items to merge
      return await mergeCartItems(
        cartItems: sourceCart.items,
        destinationCartId: destinationCartId,
      );
    } on MagentoException catch (e) {
      MagentoLogger.error(
        '[MagentoCart] Merge carts error: ${e.toString()}',
        e,
      );
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoCart] Failed to merge carts: ${e.toString()}',
        e,
        stackTrace,
      );
      throw MagentoException(
        'Failed to merge carts: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Merge cart items directly into destination cart
  ///
  /// This method adds the provided cart items to the destination cart.
  /// If an item with the same SKU already exists in the destination cart, the quantities are combined.
  ///
  /// This is useful when you already have the cart items (e.g., from a guest cart retrieved before login)
  /// and want to merge them after authentication without needing to access the source cart again.
  ///
  /// Example:
  /// ```dart
  /// final mergedCart = await MagentoCartModule.mergeCartItems(
  ///   cartItems: guestCart.items,
  ///   destinationCartId: 'customer-cart-id',
  /// );
  /// ```
  Future<models.MagentoCart> mergeCartItems({
    required List<models.MagentoCartItem> cartItems,
    required String destinationCartId,
  }) async {
    try {
      if (cartItems.isEmpty) {
        // No items to merge, return destination cart
        final destCart = await getCart(destinationCartId);
        if (destCart == null) {
          throw MagentoException('Destination cart not found');
        }
        return destCart;
      }

      // Add each item to destination cart
      // Magento will automatically combine quantities for items with the same SKU
      for (final item in cartItems) {
        try {
          await addProductToCart(
            cartId: destinationCartId,
            sku: item.product.sku,
            quantity: item.quantity,
          );
        } catch (e) {
          // Log error but continue with other items
          MagentoLogger.error(
            '[MagentoCart] Failed to merge item ${item.product.sku}: ${e.toString()}',
            e,
          );
        }
      }

      // Return the updated destination cart
      final mergedCart = await getCart(destinationCartId);
      if (mergedCart == null) {
        throw MagentoException('Failed to retrieve merged cart');
      }

      return mergedCart;
    } on MagentoException catch (e) {
      MagentoLogger.error(
        '[MagentoCart] Merge cart items error: ${e.toString()}',
        e,
      );
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoCart] Failed to merge cart items: ${e.toString()}',
        e,
        stackTrace,
      );
      throw MagentoException(
        'Failed to merge cart items: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
