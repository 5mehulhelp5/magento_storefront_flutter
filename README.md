# Magento Storefront Flutter

A production-ready Flutter SDK for Magento 2 Storefront GraphQL API.

## Features

- ✅ **Storefront Browsing** - Browse products, categories, and store information
- ✅ **Authentication** - Customer login, registration, password reset
- ✅ **Customer Profile** - Fetch and update authenticated customer profile
- ✅ **Address Management** - Create, update, and delete customer addresses
- ✅ **Read-only Catalog** - Products, categories, and search functionality
- ✅ **Cart (Guest + Customer)** - Create cart, add/update/remove items, fetch customer cart
- ✅ **Guest → Customer Cart Merge** - Automatically merges guest cart items after login
- ✅ **Local Persistence (Hive)** - Persist config, auth token, and cart IDs (optional)
- ✅ **Custom GraphQL Queries** - Escape hatch for custom queries

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  magento_storefront_flutter: ^0.0.1
```

## Getting Started

### Basic Setup

```dart
import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';

Future<void> main() async {
  // Recommended if you use storage (default: enabled in MagentoSDK)
  WidgetsFlutterBinding.ensureInitialized(); // in Flutter apps
  await MagentoStorage.init();

  // Initialize the SDK
final sdk = MagentoSDK(
  config: MagentoConfig(
    baseUrl: 'https://yourstore.com',
    storeCode: 'default', // Optional
  ),
);
}
```

### Authentication

```dart
// Login
final auth = sdk.auth;
final result = await auth.login('user@example.com', 'password');
// Token is automatically set in the client

// Register
await auth.register(
  email: 'user@example.com',
  password: 'password',
  firstName: 'John',
  lastName: 'Doe',
);

// Forgot Password
await auth.forgotPassword('user@example.com');

// Logout (client-side only)
await auth.logout();
```

### Browse Catalog

```dart
// Get product by SKU
final products = sdk.products;
final product = await products.getProductBySku('product-sku');

// Get product by URL key
final product = await products.getProductByUrlKey('product-url-key');

// Get products by category
final result = await products.getProductsByCategoryId(
  categoryId: '2',
  pageSize: 20,
  currentPage: 1,
);

// Search products
final search = sdk.search;
final results = await search.searchProducts(
  query: 'shirt',
  pageSize: 20,
  currentPage: 1,
);
```

### Categories

```dart
final categories = sdk.categories;

// Get category by ID
final category = await categories.getCategoryById('2');

// Get category tree
final categoryTree = await categories.getCategoryTree();
```

### Cart

```dart
final cart = sdk.cart;

// Guest cart: create or reuse a cart id you store yourself
final guestCart = await cart.createCart();

// Add items
final updated = await cart.addProductToCart(
  cartId: guestCart.id,
  sku: 'product-sku',
  quantity: 1,
);

// Update / remove
await cart.updateCartItem(cartId: updated.id, itemId: updated.items.first.id, quantity: 2);
await cart.removeCartItem(cartId: updated.id, itemId: updated.items.first.id);

// Authenticated users: fetch customer cart via customerCart query
final customerCart = await cart.getCustomerCart();
```

### Customer Profile

> **Auth required:** this module requires an authenticated customer token. The SDK injects
> `Authorization: Bearer <token>` automatically after `sdk.auth.login(...)`.

```dart
final profile = sdk.profile;

// Get customer profile
final customer = await profile.getProfile();

// Optional helper: addresses are included on the customer object
final addresses = customer.addresses ?? [];

// Update customer profile
// Note: Email cannot be updated via this method (requires separate mutation)
final updatedCustomer = await profile.updateProfile(
  firstname: 'John',
  lastname: 'Doe',
  gender: 1, // 1 = Male, 2 = Female
  dateOfBirth: '1990-05-15', // Format: YYYY-MM-DD
  isSubscribed: true,
);

// Create a new address
final newAddress = await profile.createAddress(
  firstname: 'John',
  lastname: 'Doe',
  street: ['123 Main St', 'Apt 4B'],
  city: 'Phoenix',
  postcode: '85001',
  countryCode: 'US',
  telephone: '555-1234',
  region: MagentoCustomerAddressRegion(
    region: 'Arizona',
    regionCode: 'AZ',
  ),
  defaultShipping: true,
  defaultBilling: false,
);

// Update an existing address
final updatedAddress = await profile.updateAddress(
  id: '123',
  city: 'New City',
  postcode: '85002',
);

// Delete an address
// Note: Cannot delete default shipping/billing addresses
final deleted = await profile.deleteAddress('123');
```

### Store Information

```dart
final store = sdk.store;

// Get store configuration
final config = await store.getStoreConfig();

// Get available stores
final stores = await store.getStores();

// Get countries with regions and cities (for address forms)
final countries = await store.getCountries();
for (final country in countries) {
  print('${country.fullNameEnglish} (${country.twoLetterAbbreviation})');
  if (country.availableRegions != null) {
    for (final region in country.availableRegions!) {
      print('  - ${region.name} (${region.code})');
      if (region.cities != null) {
        for (final city in region.cities!) {
          print('    - ${city.name}');
        }
      }
    }
  }
}
```

### Custom GraphQL Queries

```dart
final custom = sdk.custom;

// Execute custom query
final result = await custom.query(
  '''
    query GetCustomData {
      customField {
        value
      }
    }
  ''',
  variables: {'id': '123'},
);

// Execute custom mutation
final result = await custom.mutate(
  '''
    mutation UpdateCustomData(\$id: String!, \$value: String!) {
      updateCustomData(id: \$id, value: \$value) {
        success
      }
    }
  ''',
  variables: {'id': '123', 'value': 'new value'},
);
```

## Architecture

The SDK follows a clean, modular architecture:

```text
lib/
 ├── magento_storefront_flutter.dart  # Main export
 ├── magento_sdk.dart                 # Main SDK class
 ├── core/                            # Core components
 │   ├── magento_client.dart
 │   ├── magento_config.dart
 │   ├── magento_exception.dart
 │   ├── graphql_interceptor.dart
 │   └── error_mapper.dart
 ├── auth/                            # Authentication
 │   └── magento_auth.dart
 ├── store/                           # Store information
 │   └── magento_store.dart
 ├── catalog/                         # Catalog operations
 │   ├── magento_categories.dart
 │   ├── magento_products.dart
 │   └── magento_search.dart
 ├── custom/                          # Custom queries
 │   └── magento_custom_query.dart
 └── models/                          # Data models
     ├── product/
     ├── category/
     └── store/
```

## Error Handling

The SDK provides specific exception types:

```dart
try {
  await sdk.auth.login('email', 'password');
} on MagentoAuthenticationException catch (e) {
  // Handle authentication errors
} on MagentoGraphQLException catch (e) {
  // Handle GraphQL errors
} on MagentoNetworkException catch (e) {
  // Handle network errors
} on MagentoException catch (e) {
  // Handle other Magento errors
}
```

## Advanced Usage

### Custom HTTP Client

```dart
import 'package:http/http.dart' as http;

final customClient = http.Client();
final sdk = MagentoSDK(
  config: config,
  httpClient: customClient,
);
```

### GraphQL Interceptor

```dart
class MyInterceptor extends GraphQLInterceptor {
  @override
  Map<String, String>? interceptHeaders(
    String query,
    Map<String, dynamic>? variables,
    Map<String, String> headers,
  ) {
    headers['X-Custom-Header'] = 'value';
    return headers;
  }
}

final sdk = MagentoSDK(
  config: config,
  interceptor: MyInterceptor(),
);
```

### Cleanup

```dart
// Dispose resources when done
sdk.dispose();
```

## Notes

- **Storage**: `MagentoSDK` uses storage by default (`useStorage: true`). Call `MagentoStorage.init()` before creating the SDK (recommended). If you don’t want persistence, pass `useStorage: false`.
- **Cart & auth**: On login, if a guest cart with items exists, the SDK will try to **merge items into a customer cart** and persist the resulting cart id.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Issues and PRs are welcome.
