import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';

/// Service class to manage Magento SDK instance
class MagentoService {
  static MagentoSDK? _sdk;
  static MagentoConfig? _config;

  /// Initialize the SDK with configuration
  /// If config is not provided, attempts to load from storage
  static void initialize({
    String? baseUrl,
    String? storeCode,
  }) {
    // Try to load config from storage if not provided
    if (baseUrl == null) {
      final savedConfig = MagentoSDK.loadConfigFromStorage();
      if (savedConfig != null) {
        _config = savedConfig.copyWith(
          enableDebugLogging: true,
        );
        _sdk = MagentoSDK(config: _config!);
        return;
      }
    }

    // Use provided config or throw error
    if (baseUrl == null) {
      throw ArgumentError('baseUrl is required if no saved config exists');
    }

    _config = MagentoConfig(
      baseUrl: baseUrl,
      storeCode: storeCode,
      enableDebugLogging: true,
    );
    _sdk = MagentoSDK(config: _config!);
  }

  /// Get the SDK instance
  static MagentoSDK? get sdk => _sdk;

  /// Get the current configuration
  static MagentoConfig? get config => _config;

  /// Check if SDK is initialized
  static bool get isInitialized => _sdk != null;

  /// Dispose the SDK
  static void dispose() {
    _sdk?.dispose();
    _sdk = null;
    _config = null;
  }

  /// Reinitialize with new config
  static void reinitialize({
    required String baseUrl,
    String? storeCode,
  }) {
    dispose();
    initialize(baseUrl: baseUrl, storeCode: storeCode);
  }

  /// Try to initialize from saved storage
  static bool tryInitializeFromStorage() {
    try {
      initialize();
      return _sdk != null;
    } catch (e) {
      return false;
    }
  }
}
