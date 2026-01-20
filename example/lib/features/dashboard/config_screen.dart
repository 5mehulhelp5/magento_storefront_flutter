import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';
import '../../services/magento_service.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _storeCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  void _loadSavedConfig() {
    // Try to load saved config from storage
    final savedConfig = MagentoSDK.loadConfigFromStorage();
    if (savedConfig != null) {
      _baseUrlController.text = savedConfig.baseUrl;
      _storeCodeController.text = savedConfig.storeCode ?? 'default';
    } else {
      // Default values if no saved config
      _baseUrlController.text = 'https://ideaoman.bytestechnolab.net/graphql';
      _storeCodeController.text = 'default';
    }
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _storeCodeController.dispose();
    super.dispose();
  }

  Future<void> _initializeSDK() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      MagentoService.initialize(
        baseUrl: _baseUrlController.text.trim(),
        storeCode: _storeCodeController.text.trim().isEmpty
            ? null
            : _storeCodeController.text.trim(),
      );

      if (mounted) {
        context.go('/splash');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing SDK: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Magento Configuration'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your Magento store details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'https://yourstore.com/graphql',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a base URL';
                  }
                  final uri = Uri.tryParse(value.trim());
                  if (uri == null || !uri.hasScheme) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _storeCodeController,
                decoration: const InputDecoration(
                  labelText: 'Store Code (Optional)',
                  hintText: 'default',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _initializeSDK,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Initialize SDK',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Note: Make sure your Magento store has GraphQL enabled and is accessible.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
