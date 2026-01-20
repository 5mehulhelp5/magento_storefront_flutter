import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../services/cart_service.dart';

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

    setState(() => _authStatus = null);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final router = GoRouter.of(context);
      
      await CartService.prepareGuestCartForLogin();
      await authProvider.login(
        _loginEmailController.text.trim(),
        _loginPasswordController.text,
      );
      await CartService.syncAfterLogin();

      router.go('/');

    } on MagentoAuthenticationException catch (e) {
      setState(() {
        _authStatus = 'Login failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _authStatus = 'Error: $e';
      });
    }
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _authStatus = null);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final router = GoRouter.of(context);

      await CartService.prepareGuestCartForLogin();
      await authProvider.register(
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
        firstName: _registerFirstNameController.text.trim(),
        lastName: _registerLastNameController.text.trim(),
      );
      await CartService.syncAfterLogin();

      router.go('/');

    } on MagentoAuthenticationException catch (e) {
      setState(() {
        _authStatus = 'Registration failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _authStatus = 'Error: $e';
      });
    }
  }

  Future<void> _forgotPassword() async {
    if (!_forgotPasswordFormKey.currentState!.validate()) return;

    setState(() => _authStatus = null);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.forgotPassword(_forgotPasswordEmailController.text.trim());

      if (mounted) {
        setState(() {
          _authStatus = 'Password reset email sent successfully!';
        });
      }
    } on MagentoAuthenticationException catch (e) {
      setState(() {
        _authStatus = 'Failed: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _authStatus = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthProvider>(context).isLoading;

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
                color: _authStatus!.contains('successfully') || _authStatus!.contains('sent') ? Colors.green.shade100 : Colors.red.shade100,
                child: Text(
                  _authStatus!,
                  style: TextStyle(
                    color: _authStatus!.contains('successfully') || _authStatus!.contains('sent')
                        ? Colors.green.shade900
                        : Colors.red.shade900,
                  ),
                ),
              ),
            Expanded(child: TabBarView(children: [_buildLoginTab(isLoading), _buildRegisterTab(isLoading), _buildForgotPasswordTab(isLoading)])),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab(bool isLoading) {
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
              onPressed: isLoading ? null : _login,
              child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterTab(bool isLoading) {
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
              onPressed: isLoading ? null : _register,
              child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForgotPasswordTab(bool isLoading) {
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
              onPressed: isLoading ? null : _forgotPassword,
              child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send Reset Email'),
            ),
          ],
        ),
      ),
    );
  }
}
