import 'package:flutter/material.dart';
import '../../services/magento_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool get isAuthenticated => MagentoService.sdk?.auth.isAuthenticated ?? false;

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) throw Exception('SDK not initialized');
      
      await sdk.auth.login(email, password);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _setLoading(true);
    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) throw Exception('SDK not initialized');

      await sdk.auth.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> forgotPassword(String email) async {
    _setLoading(true);
    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) throw Exception('SDK not initialized');

      await sdk.auth.forgotPassword(email);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    final sdk = MagentoService.sdk;
    if (sdk != null) {
      await sdk.auth.logout();
      notifyListeners();
    }
  }


  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
