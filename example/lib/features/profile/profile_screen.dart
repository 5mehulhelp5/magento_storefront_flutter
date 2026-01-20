import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';
import '../../services/magento_service.dart';
import '../../core/providers/auth_provider.dart';
import 'edit_profile_screen.dart';
import 'edit_address_screen.dart';

/// Profile screen demonstrating customer profile
///
/// This screen shows:
/// - Customer basic information (name, email, etc.)
/// - Customer addresses
/// - Edit profile functionality
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  String? _error;
  MagentoCustomer? _customer;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      // Check if user is authenticated
      if (sdk.client.authToken == null || sdk.client.authToken!.isEmpty) {
        setState(() {
          _error = 'Please login to view your profile';
        });
        return;
      }

      final customer = await sdk.profile.getProfile();

      setState(() {
        _customer = customer;
      });
    } on AuthException catch (e) {
      setState(() {
        _error =
            'Authentication required: ${e.message}\n\nPlease login to view your profile.';
      });
    } on MagentoGraphQLException catch (e) {
      setState(() {
        _error = 'GraphQL Error: ${e.message}';
      });
    } on MagentoNetworkException catch (e) {
      setState(() {
        _error = 'Network Error: ${e.message}';
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
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_customer != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                final updatedCustomer = await Navigator.push<MagentoCustomer>(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditProfileScreen(customer: _customer!),
                  ),
                );
                // Refresh profile if it was updated
                if (updatedCustomer != null) {
                  setState(() {
                    _customer = updatedCustomer;
                  });
                }
              },
              tooltip: 'Edit Profile',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final router = GoRouter.of(context);
              await authProvider.logout();
              router.go('/auth');
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _error!.contains('Authentication') ||
                              _error!.contains('login')
                          ? Icons.lock_outline
                          : Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadProfile,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _customer == null
          ? const Center(child: Text('No profile data available'))
          : DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Profile'),
                      Tab(text: 'Addresses'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [_buildProfileTab(), _buildAddressesTab()],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileTab() {
    if (_customer == null) {
      return const Center(child: Text('No profile data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header with icon
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Text(
                      _getInitials(_customer!),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getFullName(_customer!),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_customer!.email != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _customer!.email!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              // Customer details
              _buildInfoRow('Customer ID', _customer!.id),
              _buildInfoRow('First Name', _customer!.firstname),
              _buildInfoRow('Last Name', _customer!.lastname),
              _buildInfoRow('Email', _customer!.email),
              _buildInfoRow(
                'Gender',
                _customer!.gender != null
                    ? _customer!.gender == 1
                          ? 'Male'
                          : _customer!.gender == 2
                          ? 'Female'
                          : 'Other'
                    : null,
              ),
              _buildInfoRow('Date of Birth', _customer!.dateOfBirth),
              _buildInfoRow(
                'Newsletter Subscription',
                _customer!.isSubscribed != null
                    ? (_customer!.isSubscribed!
                          ? 'Subscribed'
                          : 'Not Subscribed')
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressesTab() {
    if (_customer == null) {
      return const Center(child: Text('No profile data available'));
    }

    final addresses = _customer!.addresses ?? [];

    return Column(
      children: [
        Expanded(
          child: addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No addresses found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to add an address',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Address header with badges
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _getAddressName(address),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (address.defaultShipping == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Shipping',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                  ),
                                if (address.defaultBilling == true) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Billing',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Street address
                            if (address.street.isNotEmpty) ...[
                              ...address.street.map(
                                (line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    line,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            // City, State, ZIP
                            Row(
                              children: [
                                if (address.city != null)
                                  Text(
                                    '${address.city}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                if (address.city != null &&
                                    address.region?.region != null)
                                  const Text(
                                    ', ',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                if (address.region?.region != null)
                                  Text(
                                    address.region!.region!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                if (address.postcode != null) ...[
                                  if (address.city != null ||
                                      address.region?.region != null)
                                    const Text(' '),
                                  Text(
                                    address.postcode!,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ],
                            ),
                            // Country
                            if (address.countryCode != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                address.countryCode!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            // Phone
                            if (address.telephone != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    address.telephone!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            // Action buttons
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _editAddress(address),
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Edit'),
                                ),
                                const SizedBox(width: 8),
                                // Disable delete button if address is default shipping or billing
                                if (address.defaultShipping == true ||
                                    address.defaultBilling == true)
                                  Tooltip(
                                    message:
                                        address.defaultShipping == true &&
                                            address.defaultBilling == true
                                        ? 'Cannot delete default shipping and billing address'
                                        : address.defaultShipping == true
                                        ? 'Cannot delete default shipping address'
                                        : 'Cannot delete default billing address',
                                    child: TextButton.icon(
                                      onPressed: null, // Disabled
                                      icon: const Icon(Icons.delete, size: 18),
                                      label: const Text('Delete'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.grey,
                                      ),
                                    ),
                                  )
                                else
                                  TextButton.icon(
                                    onPressed: () => _deleteAddress(address),
                                    icon: const Icon(Icons.delete, size: 18),
                                    label: const Text('Delete'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Add Address Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _addAddress,
            icon: const Icon(Icons.add),
            label: const Text('Add New Address'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addAddress() async {
    final result = await Navigator.push<MagentoCustomerAddress>(
      context,
      MaterialPageRoute(builder: (context) => const EditAddressScreen()),
    );
    if (result != null && mounted) {
      // Refresh profile to get updated addresses
      _loadProfile();
    }
  }

  Future<void> _editAddress(MagentoCustomerAddress address) async {
    final result = await Navigator.push<MagentoCustomerAddress>(
      context,
      MaterialPageRoute(
        builder: (context) => EditAddressScreen(address: address),
      ),
    );
    if (result != null && mounted) {
      // Refresh profile to get updated addresses
      _loadProfile();
    }
  }

  Future<void> _deleteAddress(MagentoCustomerAddress address) async {
    // Check if address is a default address - prevent deletion without API call
    if (address.defaultShipping == true || address.defaultBilling == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              address.defaultShipping == true && address.defaultBilling == true
                  ? 'Cannot delete default shipping and billing address. Please set another address as default first.'
                  : address.defaultShipping == true
                  ? 'Cannot delete default shipping address. Please set another address as default shipping first.'
                  : 'Cannot delete default billing address. Please set another address as default billing first.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
      return; // Exit early without calling GraphQL
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text(
          'Are you sure you want to delete this address?\n\n'
          '${address.street.join(", ")}\n'
          '${address.city ?? ""}${address.region?.region != null ? ", ${address.region!.region}" : ""} ${address.postcode ?? ""}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || address.id == null) {
      return;
    }

    // Show loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deleting address...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      final deleted = await sdk.profile.deleteAddress(address.id!);

      if (mounted) {
        if (deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh profile
          _loadProfile();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete address'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on MagentoGraphQLException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
            child: Text(value ?? 'N/A', style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  String _getInitials(MagentoCustomer customer) {
    final first = customer.firstname?.isNotEmpty == true
        ? customer.firstname!.substring(0, 1).toUpperCase()
        : '';
    final last = customer.lastname?.isNotEmpty == true
        ? customer.lastname!.substring(0, 1).toUpperCase()
        : '';
    if (first.isNotEmpty && last.isNotEmpty) {
      return '$first$last';
    } else if (first.isNotEmpty) {
      return first;
    } else if (customer.email?.isNotEmpty == true) {
      return customer.email!.substring(0, 1).toUpperCase();
    }
    return '?';
  }

  String _getFullName(MagentoCustomer customer) {
    final parts = <String>[];
    if (customer.firstname?.isNotEmpty == true) {
      parts.add(customer.firstname!);
    }
    if (customer.lastname?.isNotEmpty == true) {
      parts.add(customer.lastname!);
    }
    if (parts.isEmpty && customer.email?.isNotEmpty == true) {
      return customer.email!;
    }
    final name = parts.join(' ');
    return name.isNotEmpty ? name : 'Customer';
  }

  String _getAddressName(MagentoCustomerAddress address) {
    final parts = <String>[];
    if (address.firstname?.isNotEmpty == true) {
      parts.add(address.firstname!);
    }
    if (address.lastname?.isNotEmpty == true) {
      parts.add(address.lastname!);
    }
    if (parts.isEmpty) {
      return 'Address ${address.id ?? 'Unknown'}';
    }
    return parts.join(' ');
  }
}
