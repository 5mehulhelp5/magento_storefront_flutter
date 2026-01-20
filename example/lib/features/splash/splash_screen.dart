import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/magento_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Wait for a brief moment for better UX
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (MagentoService.isInitialized) {
      if (MagentoService.sdk?.auth.isAuthenticated == true) {
        context.go('/');
      } else {
        context.go('/auth');
      }
    } else {
      context.go('/config');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Placeholder for Logo
            Icon(Icons.shopping_bag, size: 100, color: Colors.blue),
            SizedBox(height: 24),
            Text(
              'Magento Storefront',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
