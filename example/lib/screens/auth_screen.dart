import 'package:flutter/material.dart';
import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';
import '../services/magento_service.dart';
import '../services/cart_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _forgotPasswordFormKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController(text: 'bytesqa@bytestechnolab.com');
  final _loginPasswordController = TextEditingController(text: 'Test@123');

  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerFirstNameController = TextEditingController();
  final _registerLastNameController = TextEditingController();

  final _forgotPasswordEmailController = TextEditingController();

  bool _isLoading = false;
  String? _authStatus;

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerFirstNameController.dispose();
    _registerLastNameController.dispose();
    _forgotPasswordEmailController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _authStatus = null;
    });

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      // Ensure the SDK knows the guest cart before login, so merge works.
      await CartService.prepareGuestCartForLogin();

      final result = await sdk.auth.login(_loginEmailController.text.trim(), _loginPasswordController.text);

      // Switch app state to customer cart and clear stale guest/current cart ids.
      await CartService.syncAfterLogin();

      setState(() {
        final tokenPreview = result.token.length > 20 ? '${result.token.substring(0, 20)}...' : result.token;
        _authStatus = 'Login successful! Token: $tokenPreview';
      });
    } on MagentoAuthenticationException catch (e) {
      setState(() {
        _authStatus = 'Login failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _authStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _authStatus = null;
    });

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      // Ensure the SDK knows the guest cart before registration/login, so merge works.
      await CartService.prepareGuestCartForLogin();

      final result = await sdk.auth.register(
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
        firstName: _registerFirstNameController.text.trim(),
        lastName: _registerLastNameController.text.trim(),
      );

      // Switch app state to customer cart and clear stale guest/current cart ids.
      await CartService.syncAfterLogin();

      setState(() {
        final tokenPreview = result.token.length > 20 ? '${result.token.substring(0, 20)}...' : result.token;
        _authStatus = 'Registration successful! Token: $tokenPreview';
      });
    } on MagentoAuthenticationException catch (e) {
      setState(() {
        _authStatus = 'Registration failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _authStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forgotPassword() async {
    if (!_forgotPasswordFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _authStatus = null;
    });

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      await sdk.auth.forgotPassword(_forgotPasswordEmailController.text.trim());

      setState(() {
        _authStatus = 'Password reset email sent successfully!';
      });
    } on MagentoAuthenticationException catch (e) {
      setState(() {
        _authStatus = 'Failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _authStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _logout() {
    final sdk = MagentoService.sdk;
    if (sdk != null) {
      sdk.auth.logout();
      setState(() {
        _authStatus = 'Logged out successfully';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Authentication'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Login'),
              Tab(text: 'Register'),
              Tab(text: 'Forgot Password'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_authStatus != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: _authStatus!.contains('successful') || _authStatus!.contains('sent') ? Colors.green.shade100 : Colors.red.shade100,
                child: Text(
                  _authStatus!,
                  style: TextStyle(
                    color: _authStatus!.contains('successful') || _authStatus!.contains('sent')
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                  ),
                ),
              ),
            Expanded(child: TabBarView(children: [_buildLoginTab(), _buildRegisterTab(), _buildForgotPasswordTab()])),
            if (MagentoService.sdk?.auth.isAuthenticated == true)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('Logout'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _loginEmailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loginPasswordController,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _registerFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _registerEmailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerPasswordController,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock)),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerFirstNameController,
              decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your first name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registerLastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your last name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForgotPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _forgotPasswordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _forgotPasswordEmailController,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _forgotPassword,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send Reset Email'),
            ),
          ],
        ),
      ),
    );
  }
}
