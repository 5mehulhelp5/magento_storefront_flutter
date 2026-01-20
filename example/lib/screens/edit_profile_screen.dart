import 'package:flutter/material.dart';
import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';
import '../services/magento_service.dart';

/// Edit profile screen for updating customer information
class EditProfileScreen extends StatefulWidget {
  final MagentoCustomer customer;

  const EditProfileScreen({
    super.key,
    required this.customer,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _emailController;
  late TextEditingController _dateOfBirthController;

  int? _selectedGender;
  bool? _isSubscribed;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _firstnameController = TextEditingController(text: widget.customer.firstname ?? '');
    _lastnameController = TextEditingController(text: widget.customer.lastname ?? '');
    _emailController = TextEditingController(text: widget.customer.email ?? '');
    _dateOfBirthController = TextEditingController(text: widget.customer.dateOfBirth ?? '');
    _selectedGender = widget.customer.gender;
    _isSubscribed = widget.customer.isSubscribed;
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      // Build update parameters - only include changed values
      // Note: Email cannot be updated via updateProfile - requires separate mutation
      final updatedCustomer = await sdk.profile.updateProfile(
        firstname: _firstnameController.text.trim().isNotEmpty
            ? _firstnameController.text.trim()
            : null,
        lastname: _lastnameController.text.trim().isNotEmpty
            ? _lastnameController.text.trim()
            : null,
        gender: _selectedGender,
        dateOfBirth: _dateOfBirthController.text.trim().isNotEmpty
            ? _dateOfBirthController.text.trim()
            : null,
        isSubscribed: _isSubscribed,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Return updated customer to previous screen
        Navigator.of(context).pop(updatedCustomer);
      }
    } on AuthException catch (e) {
      setState(() {
        _error = 'Authentication error: ${e.message}';
      });
    } on MagentoGraphQLException catch (e) {
      setState(() {
        _error = 'Update failed: ${e.message}';
      });
    } on MagentoNetworkException catch (e) {
      setState(() {
        _error = 'Network error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
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
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // First Name
              TextFormField(
                controller: _firstnameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Last Name
              TextFormField(
                controller: _lastnameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Email (Read-only - cannot be updated via this mutation)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (Read-only)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                  helperText: 'Email cannot be changed via profile update',
                ),
                enabled: false,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              // Gender
              DropdownButtonFormField<int>(
                value: _selectedGender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc),
                ),
                items: const [
                  DropdownMenuItem<int>(
                    value: null,
                    child: Text('Not specified'),
                  ),
                  DropdownMenuItem<int>(
                    value: 1,
                    child: Text('Male'),
                  ),
                  DropdownMenuItem<int>(
                    value: 2,
                    child: Text('Female'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Date of Birth
              TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  helperText: 'Format: YYYY-MM-DD (e.g., 1990-05-15)',
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    // Basic date format validation
                    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                    if (!datePattern.hasMatch(value.trim())) {
                      return 'Please use format YYYY-MM-DD';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Newsletter Subscription
              Card(
                child: SwitchListTile(
                  title: const Text('Newsletter Subscription'),
                  subtitle: const Text('Receive updates and promotions'),
                  value: _isSubscribed ?? false,
                  onChanged: (value) {
                    setState(() {
                      _isSubscribed = value;
                    });
                  },
                  secondary: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 24),
              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 8),
              // Cancel Button
              OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).pop();
                      },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
