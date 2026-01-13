import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';

/// Service class to manage Magento SDK instance
class MagentoService {
  static MagentoSDK? _sdk;
  static MagentoConfig? _config;

  /// Initialize the SDK with configuration
  static void initialize({
    required String baseUrl,
    String? storeCode,
  }) {
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
}
