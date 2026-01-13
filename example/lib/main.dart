import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/config_screen.dart';

void main() {
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
      home: const ConfigScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/config': (context) => const ConfigScreen(),
      },
    );
  }
}
