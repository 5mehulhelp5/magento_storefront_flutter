import 'package:hive_flutter/hive_flutter.dart';

/// Storage keys for Hive boxes
class StorageKeys {
  static const String preferencesBox = 'preferences';
  static const String sessionBox = 'session';
  
  // Preference keys
  static const String baseUrl = 'base_url';
  static const String storeCode = 'store_code';
  static const String enableDebugLogging = 'enable_debug_logging';
  
  // Session keys
  static const String authToken = 'auth_token';
  static const String guestCartId = 'guest_cart_id';
  static const String customerCartId = 'customer_cart_id';
  static const String isAuthenticated = 'is_authenticated';
}

/// Service class to manage local storage using Hive
class StorageService {
  static Box? _preferencesBox;
  static Box? _sessionBox;
  static bool _initialized = false;

  /// Initialize Hive and open boxes
  static Future<void> initialize() async {
    if (_initialized) return;

    await Hive.initFlutter();
    
    // Open boxes
    _preferencesBox = await Hive.openBox(StorageKeys.preferencesBox);
    _sessionBox = await Hive.openBox(StorageKeys.sessionBox);
    
    _initialized = true;
  }

  /// Check if storage is initialized
  static bool get isInitialized => _initialized;

  /// Get preferences box
  static Box get preferencesBox {
    if (_preferencesBox == null) {
      throw Exception('StorageService not initialized. Call initialize() first.');
    }
    return _preferencesBox!;
  }

  /// Get session box
  static Box get sessionBox {
    if (_sessionBox == null) {
      throw Exception('StorageService not initialized. Call initialize() first.');
    }
    return _sessionBox!;
  }

  // ========== Store Configuration ==========

  /// Save base URL
  static Future<void> saveBaseUrl(String baseUrl) async {
    await preferencesBox.put(StorageKeys.baseUrl, baseUrl);
  }

  /// Get base URL
  static String? getBaseUrl() {
    return preferencesBox.get(StorageKeys.baseUrl) as String?;
  }

  /// Save store code
  static Future<void> saveStoreCode(String? storeCode) async {
    if (storeCode == null || storeCode.isEmpty) {
      await preferencesBox.delete(StorageKeys.storeCode);
    } else {
      await preferencesBox.put(StorageKeys.storeCode, storeCode);
    }
  }

  /// Get store code
  static String? getStoreCode() {
    return preferencesBox.get(StorageKeys.storeCode) as String?;
  }

  /// Save debug logging preference
  static Future<void> saveEnableDebugLogging(bool enabled) async {
    await preferencesBox.put(StorageKeys.enableDebugLogging, enabled);
  }

  /// Get debug logging preference
  static bool getEnableDebugLogging() {
    return preferencesBox.get(StorageKeys.enableDebugLogging, defaultValue: false) as bool;
  }

  // ========== User Session ==========

  /// Save authentication token
  static Future<void> saveAuthToken(String? token) async {
    if (token == null || token.isEmpty) {
      await sessionBox.delete(StorageKeys.authToken);
      await sessionBox.put(StorageKeys.isAuthenticated, false);
    } else {
      await sessionBox.put(StorageKeys.authToken, token);
      await sessionBox.put(StorageKeys.isAuthenticated, true);
    }
  }

  /// Get authentication token
  static String? getAuthToken() {
    return sessionBox.get(StorageKeys.authToken) as String?;
  }

  /// Check if user is authenticated
  static bool isAuthenticated() {
    return sessionBox.get(StorageKeys.isAuthenticated, defaultValue: false) as bool;
  }

  /// Save guest cart ID
  static Future<void> saveGuestCartId(String? cartId) async {
    if (cartId == null || cartId.isEmpty) {
      await sessionBox.delete(StorageKeys.guestCartId);
    } else {
      await sessionBox.put(StorageKeys.guestCartId, cartId);
    }
  }

  /// Get guest cart ID
  static String? getGuestCartId() {
    return sessionBox.get(StorageKeys.guestCartId) as String?;
  }

  /// Save customer cart ID
  static Future<void> saveCustomerCartId(String? cartId) async {
    if (cartId == null || cartId.isEmpty) {
      await sessionBox.delete(StorageKeys.customerCartId);
    } else {
      await sessionBox.put(StorageKeys.customerCartId, cartId);
    }
  }

  /// Get customer cart ID
  static String? getCustomerCartId() {
    return sessionBox.get(StorageKeys.customerCartId) as String?;
  }

  // ========== Clear Data ==========

  /// Clear all session data (logout)
  static Future<void> clearSession() async {
    await sessionBox.clear();
  }

  /// Clear all preferences
  static Future<void> clearPreferences() async {
    await preferencesBox.clear();
  }

  /// Clear all data
  static Future<void> clearAll() async {
    await clearSession();
    await clearPreferences();
  }

  /// Close boxes (call on app dispose)
  static Future<void> close() async {
    await _preferencesBox?.close();
    await _sessionBox?.close();
    _preferencesBox = null;
    _sessionBox = null;
    _initialized = false;
  }
}
