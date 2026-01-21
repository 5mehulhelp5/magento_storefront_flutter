import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';
import 'core/providers/auth_provider.dart';
import 'core/routing/app_router.dart';
import 'services/magento_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive storage
  await MagentoStorage.init();

  // Try to initialize SDK from saved storage
  MagentoService.tryInitializeFromStorage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Magento Storefront Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
    );
  }
}

