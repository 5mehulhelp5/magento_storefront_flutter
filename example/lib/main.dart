import 'package:flutter/material.dart';
import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/config_screen.dart';
import 'services/magento_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive storage
  await MagentoStorage.init();
  
  // Try to initialize SDK from saved storage
  MagentoService.tryInitializeFromStorage();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Magento Storefront Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Navigate to home if SDK is already initialized, otherwise show config screen
      home: MagentoService.isInitialized ? const HomeScreen() : const ConfigScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/config': (context) => const ConfigScreen(),
      },
    );
  }
}
