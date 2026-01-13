import 'package:flutter/material.dart';
import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';
import '../services/magento_service.dart';

class StoreInfoScreen extends StatefulWidget {
  const StoreInfoScreen({super.key});

  @override
  State<StoreInfoScreen> createState() => _StoreInfoScreenState();
}

class _StoreInfoScreenState extends State<StoreInfoScreen> {
  bool _isLoading = false;
  String? _error;
  MagentoStoreConfig? _storeConfig;
  List<MagentoStore>? _stores;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
  }

  Future<void> _loadStoreInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      final config = await sdk.store.getStoreConfig();
      final stores = await sdk.store.getStores();

      setState(() {
        _storeConfig = config;
        _stores = stores;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Information'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStoreInfo,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStoreInfo,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Store Config'),
                          Tab(text: 'Stores'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildStoreConfigTab(),
                            _buildStoresTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStoreConfigTab() {
    if (_storeConfig == null) {
      return const Center(child: Text('No store config available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Store Name', _storeConfig!.storeName),
              _buildInfoRow('Store Code', _storeConfig!.code),
              _buildInfoRow('Website ID', _storeConfig!.websiteId),
              _buildInfoRow('Locale', _storeConfig!.locale),
              _buildInfoRow('Base Currency', _storeConfig!.baseCurrencyCode),
              _buildInfoRow(
                'Display Currency',
                _storeConfig!.defaultDisplayCurrencyCode,
              ),
              _buildInfoRow('Timezone', _storeConfig!.timezone),
              _buildInfoRow('Weight Unit', _storeConfig!.weightUnit),
              _buildInfoRow('Base URL', _storeConfig!.baseUrl),
              _buildInfoRow('Secure Base URL', _storeConfig!.secureBaseUrl),
              _buildInfoRow(
                'Catalog Search Enabled',
                _storeConfig!.catalogSearchEnabled?.toString() ?? 'N/A',
              ),
              _buildInfoRow(
                'Use Store in URL',
                _storeConfig!.useStoreInUrl?.toString() ?? 'N/A',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoresTab() {
    if (_stores == null || _stores!.isEmpty) {
      return const Center(child: Text('No stores available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stores!.length,
      itemBuilder: (context, index) {
        final store = _stores![index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Code', store.code),
                _buildInfoRow('ID', store.id),
                _buildInfoRow('Website ID', store.websiteId),
                _buildInfoRow('Locale', store.locale),
                _buildInfoRow('Base Currency', store.baseCurrencyCode),
                _buildInfoRow('Display Currency', store.defaultDisplayCurrencyCode),
                _buildInfoRow('Timezone', store.timezone),
                _buildInfoRow('Weight Unit', store.weightUnit),
                _buildInfoRow('Base URL', store.baseUrl),
                _buildInfoRow('Secure Base URL', store.secureBaseUrl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }
}
