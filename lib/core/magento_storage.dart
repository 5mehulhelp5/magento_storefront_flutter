import 'package:hive_flutter/hive_flutter.dart';
import 'magento_config.dart';
import '../models/store/store.dart' as models;

/// Storage keys for Hive boxes
class _StorageKeys {
  static const String configBox = 'magento_config';
  static const String storeConfigBox = 'magento_store_config';
  static const String authBox = 'magento_auth';
  
  // Keys within boxes
  static const String baseUrl = 'base_url';
  static const String storeCode = 'store_code';
  static const String customHeaders = 'custom_headers';
  static const String timeoutSeconds = 'timeout_seconds';
  static const String enableDebugLogging = 'enable_debug_logging';
  static const String authToken = 'auth_token';
  static const String storeConfig = 'store_config';
  static const String guestCartId = 'guest_cart_id';
  static const String customerCartId = 'customer_cart_id';
  static const String currentCartId = 'current_cart_id';
}

/// Storage service for Magento SDK using Hive
/// 
/// Manages local storage for:
/// - Store configuration (base URL, store code, etc.)
/// - Authentication tokens
/// - Store config data
class MagentoStorage {
  static MagentoStorage? _instance;
  static MagentoStorage get instance {
    if (_instance == null) {
      throw StateError(
        'MagentoStorage not initialized. Call MagentoStorage.init() first.',
      );
    }
    return _instance!;
  }

  Box? _configBox;
  Box? _storeConfigBox;
  Box? _authBox;

  /// Initialize Hive storage
  /// 
  /// Must be called before using the storage service.
  /// Typically called in main() before runApp().
  /// 
  /// Example:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await MagentoStorage.init();
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> init() async {
    await Hive.initFlutter();
    _instance = MagentoStorage._();
    await _instance!._initBoxes();
  }

  MagentoStorage._();

  Future<void> _initBoxes() async {
    _configBox = await Hive.openBox(_StorageKeys.configBox);
    _storeConfigBox = await Hive.openBox(_StorageKeys.storeConfigBox);
    _authBox = await Hive.openBox(_StorageKeys.authBox);
  }

  /// Save Magento configuration
  Future<void> saveConfig(MagentoConfig config) async {
    await _configBox?.put(_StorageKeys.baseUrl, config.baseUrl);
    await _configBox?.put(_StorageKeys.storeCode, config.storeCode);
    await _configBox?.put(_StorageKeys.timeoutSeconds, config.timeoutSeconds);
    await _configBox?.put(_StorageKeys.enableDebugLogging, config.enableDebugLogging);
    
    if (config.customHeaders != null) {
      await _configBox?.put(_StorageKeys.customHeaders, config.customHeaders);
    } else {
      await _configBox?.delete(_StorageKeys.customHeaders);
    }
  }

  /// Load saved Magento configuration
  MagentoConfig? loadConfig() {
    final baseUrl = _configBox?.get(_StorageKeys.baseUrl) as String?;
    if (baseUrl == null) return null;

    return MagentoConfig(
      baseUrl: baseUrl,
      storeCode: _configBox?.get(_StorageKeys.storeCode) as String?,
      customHeaders: _configBox?.get(_StorageKeys.customHeaders) as Map<String, String>?,
      timeoutSeconds: _configBox?.get(_StorageKeys.timeoutSeconds, defaultValue: 30) as int,
      enableDebugLogging: _configBox?.get(_StorageKeys.enableDebugLogging, defaultValue: false) as bool,
    );
  }

  /// Clear saved configuration
  Future<void> clearConfig() async {
    await _configBox?.clear();
  }

  /// Save authentication token
  Future<void> saveAuthToken(String? token) async {
    if (token != null) {
      await _authBox?.put(_StorageKeys.authToken, token);
    } else {
      await _authBox?.delete(_StorageKeys.authToken);
    }
  }

  /// Load saved authentication token
  String? loadAuthToken() {
    return _authBox?.get(_StorageKeys.authToken) as String?;
  }

  /// Clear authentication token
  Future<void> clearAuthToken() async {
    await _authBox?.delete(_StorageKeys.authToken);
  }

  /// Save store configuration
  Future<void> saveStoreConfig(models.MagentoStoreConfig storeConfig) async {
    final json = {
      'id': storeConfig.id,
      'code': storeConfig.code,
      'website_id': storeConfig.websiteId,
      'locale': storeConfig.locale,
      'base_currency_code': storeConfig.baseCurrencyCode,
      'default_display_currency_code': storeConfig.defaultDisplayCurrencyCode,
      'timezone': storeConfig.timezone,
      'weight_unit': storeConfig.weightUnit,
      'base_url': storeConfig.baseUrl,
      'secure_base_url': storeConfig.secureBaseUrl,
      'store_name': storeConfig.storeName,
      'catalog_search_enabled': storeConfig.catalogSearchEnabled,
      'use_store_in_url': storeConfig.useStoreInUrl,
    };
    await _storeConfigBox?.put(_StorageKeys.storeConfig, json);
  }

  /// Load saved store configuration
  models.MagentoStoreConfig? loadStoreConfig() {
    final json = _storeConfigBox?.get(_StorageKeys.storeConfig) as Map<String, dynamic>?;
    if (json == null) return null;
    
    return models.MagentoStoreConfig.fromJson(json);
  }

  /// Clear saved store configuration
  Future<void> clearStoreConfig() async {
    await _storeConfigBox?.delete(_StorageKeys.storeConfig);
  }

  /// Save guest cart ID
  Future<void> saveGuestCartId(String? cartId) async {
    if (cartId != null && cartId.isNotEmpty) {
      await _authBox?.put(_StorageKeys.guestCartId, cartId);
    } else {
      await _authBox?.delete(_StorageKeys.guestCartId);
    }
  }

  /// Load saved guest cart ID
  String? loadGuestCartId() {
    return _authBox?.get(_StorageKeys.guestCartId) as String?;
  }

  /// Clear guest cart ID
  Future<void> clearGuestCartId() async {
    await _authBox?.delete(_StorageKeys.guestCartId);
  }

  /// Save customer cart ID
  Future<void> saveCustomerCartId(String? cartId) async {
    if (cartId != null && cartId.isNotEmpty) {
      await _authBox?.put(_StorageKeys.customerCartId, cartId);
    } else {
      await _authBox?.delete(_StorageKeys.customerCartId);
    }
  }

  /// Load saved customer cart ID
  String? loadCustomerCartId() {
    return _authBox?.get(_StorageKeys.customerCartId) as String?;
  }

  /// Clear customer cart ID
  Future<void> clearCustomerCartId() async {
    await _authBox?.delete(_StorageKeys.customerCartId);
  }

  /// Save current cart ID (used to track active cart before login)
  Future<void> saveCurrentCartId(String? cartId) async {
    if (cartId != null && cartId.isNotEmpty) {
      await _authBox?.put(_StorageKeys.currentCartId, cartId);
    } else {
      await _authBox?.delete(_StorageKeys.currentCartId);
    }
  }

  /// Load current cart ID
  String? loadCurrentCartId() {
    return _authBox?.get(_StorageKeys.currentCartId) as String?;
  }

  /// Clear current cart ID
  Future<void> clearCurrentCartId() async {
    await _authBox?.delete(_StorageKeys.currentCartId);
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await clearConfig();
    await clearAuthToken();
    await clearStoreConfig();
    await clearGuestCartId();
    await clearCustomerCartId();
  }

  /// Dispose storage resources
  Future<void> dispose() async {
    await _configBox?.close();
    await _storeConfigBox?.close();
    await _authBox?.close();
  }
}
