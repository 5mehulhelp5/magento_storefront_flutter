import 'package:logger/logger.dart';

/// Logger instance for Magento Storefront Flutter SDK
class MagentoLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  /// Log debug message
  static void debug(String message) {
    _logger.d(message);
  }

  /// Log info message
  static void info(String message) {
    _logger.i(message);
  }

  /// Log warning message
  static void warning(String message) {
    _logger.w(message);
  }

  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log verbose message
  static void verbose(String message) {
    _logger.t(message);
  }
}
