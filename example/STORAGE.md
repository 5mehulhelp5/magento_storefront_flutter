# Hive Storage Implementation

This document describes the Hive storage implementation in the Magento Storefront Flutter example app.

## Overview

The example app uses [Hive Flutter](https://pub.dev/packages/hive_flutter) for local persistence of:
- Store configuration (base URL, store code, debug logging)
- User session (authentication token)
- Cart IDs (guest cart and customer cart)

## Implementation Details

### Storage Service (`lib/services/storage_service.dart`)

The `StorageService` class provides a centralized interface for managing local storage using Hive boxes:

#### Boxes
- **Preferences Box**: Stores app configuration and preferences
- **Session Box**: Stores user session data and cart IDs

#### Stored Data

**Preferences:**
- `base_url`: Magento store base URL
- `store_code`: Store code (optional)
- `enable_debug_logging`: Debug logging preference

**Session:**
- `auth_token`: User authentication token
- `guest_cart_id`: Guest cart ID (before authentication)
- `customer_cart_id`: Customer cart ID (after authentication)
- `is_authenticated`: Authentication status flag

### Integration Points

#### 1. App Initialization (`lib/main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive storage
  await StorageService.initialize();
  
  // Load saved configuration and restore session
  final baseUrl = StorageService.getBaseUrl();
  if (baseUrl != null && baseUrl.isNotEmpty) {
    // Initialize SDK with saved config
    MagentoService.initialize(...);
    
    // Restore authentication token
    final authToken = StorageService.getAuthToken();
    if (authToken != null) {
      MagentoService.sdk?.client.setAuthToken(authToken);
    }
    
    // Restore cart
    await CartService.initialize();
  }
  
  runApp(const MyApp());
}
```

#### 2. Configuration Screen (`lib/screens/config_screen.dart`)

- Loads saved configuration on initialization
- Saves configuration when SDK is initialized
- Includes debug logging toggle

#### 3. Authentication (`lib/screens/auth_screen.dart`)

- Saves authentication token after successful login/registration
- Clears authentication token on logout

#### 4. Cart Service (`lib/services/cart_service.dart`)

- Saves cart IDs (guest or customer) to storage
- Loads saved cart on app initialization
- Automatically switches between guest and customer cart storage based on authentication status

## Usage Examples

### Saving Store Configuration

```dart
// Automatically saved when initializing SDK
MagentoService.initialize(
  baseUrl: 'https://yourstore.com',
  storeCode: 'default',
  enableDebugLogging: true,
);
```

### Saving Authentication Token

```dart
// Automatically saved after login/register
final result = await sdk.auth.login('user@example.com', 'password');
// Token is automatically saved to storage
```

### Saving Cart ID

```dart
// Automatically saved when cart is created or updated
final cart = await sdk.cart.createCart();
// Cart ID is automatically saved to storage
```

### Clearing Session Data

```dart
// Clear all session data (logout)
await StorageService.clearSession();
```

### Clearing All Data

```dart
// Clear all stored data
await StorageService.clearAll();
```

## Data Persistence

All data is persisted locally using Hive, which means:
- Data persists across app restarts
- Data is stored in device storage
- No network required for accessing stored data
- Fast read/write operations

## Storage Location

Hive stores data in platform-specific locations:
- **Android**: `/data/data/<package_name>/app_flutter/`
- **iOS**: App's Documents directory
- **Web**: Browser's IndexedDB
- **Desktop**: Platform-specific data directory

## Best Practices

1. **Always initialize storage before use**: Call `StorageService.initialize()` in `main()` before accessing any storage methods.

2. **Handle null values**: Storage methods return `null` if data doesn't exist. Always check for null before using stored values.

3. **Clear sensitive data on logout**: Use `StorageService.clearSession()` to remove authentication tokens and session data.

4. **Save cart IDs automatically**: The cart service automatically saves cart IDs, but you can manually save them if needed.

5. **Use async/await**: All storage operations are async, so use `await` when calling storage methods.

## Troubleshooting

### Data Not Persisting

- Ensure `StorageService.initialize()` is called before accessing storage
- Check that `WidgetsFlutterBinding.ensureInitialized()` is called in `main()`

### Storage Errors

- Verify Hive dependencies are installed: `flutter pub get`
- Check device storage permissions (especially on Android)
- Clear app data and reinitialize if storage becomes corrupted

### Cart Not Restoring

- Verify cart ID is saved after cart operations
- Check authentication status (guest vs customer cart)
- Ensure `CartService.initialize()` is called in `main()`

## API Reference

### StorageService Methods

#### Preferences
- `saveBaseUrl(String baseUrl)`: Save base URL
- `getBaseUrl()`: Get saved base URL
- `saveStoreCode(String? storeCode)`: Save store code
- `getStoreCode()`: Get saved store code
- `saveEnableDebugLogging(bool enabled)`: Save debug logging preference
- `getEnableDebugLogging()`: Get debug logging preference

#### Session
- `saveAuthToken(String? token)`: Save authentication token
- `getAuthToken()`: Get saved authentication token
- `isAuthenticated()`: Check if user is authenticated
- `saveGuestCartId(String? cartId)`: Save guest cart ID
- `getGuestCartId()`: Get saved guest cart ID
- `saveCustomerCartId(String? cartId)`: Save customer cart ID
- `getCustomerCartId()`: Get saved customer cart ID

#### Utility
- `clearSession()`: Clear all session data
- `clearPreferences()`: Clear all preferences
- `clearAll()`: Clear all stored data
- `close()`: Close storage boxes (call on app dispose)
