import 'package:flutter/material.dart';
import 'package:magento_storefront_flutter/magento_storefront_flutter.dart';
import '../../services/magento_service.dart';

/// Edit/Add address screen for managing customer addresses
class EditAddressScreen extends StatefulWidget {
  final MagentoCustomerAddress? address; // null for new address

  const EditAddressScreen({
    super.key,
    this.address,
  });

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstnameController;
  late TextEditingController _lastnameController;
  late TextEditingController _streetLine1Controller;
  late TextEditingController _streetLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _postcodeController;
  late TextEditingController _countryCodeController;
  late TextEditingController _telephoneController;
  late TextEditingController _regionController;
  late TextEditingController _regionCodeController;

  bool? _defaultShipping;
  bool? _defaultBilling;
  bool _isLoading = false;
  bool _isLoadingCountries = false;
  String? _error;

  // Country/Region/City data
  List<MagentoCountry>? _countries;
  MagentoCountry? _selectedCountry;
  MagentoCountryRegion? _selectedRegion;
  MagentoCountryCity? _selectedCity;

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _firstnameController = TextEditingController(text: address?.firstname ?? '');
    _lastnameController = TextEditingController(text: address?.lastname ?? '');
    _streetLine1Controller = TextEditingController(
      text: address?.street.isNotEmpty == true ? address!.street[0] : '',
    );
    _streetLine2Controller = TextEditingController(
      text: address?.street.length == 2 ? address!.street[1] : '',
    );
    _cityController = TextEditingController(text: address?.city ?? '');
    _postcodeController = TextEditingController(text: address?.postcode ?? '');
    _countryCodeController = TextEditingController(
      text: address?.countryCode ?? 'US',
    );
    _telephoneController = TextEditingController(text: address?.telephone ?? '');
    _regionController = TextEditingController(text: address?.region?.region ?? '');
    _regionCodeController = TextEditingController(
      text: address?.region?.regionCode ?? '',
    );
    _defaultShipping = address?.defaultShipping;
    _defaultBilling = address?.defaultBilling;
    
    // Load countries
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _isLoadingCountries = true;
    });

    try {
      final sdk = MagentoService.sdk;
      if (sdk == null) {
        throw Exception('SDK not initialized');
      }

      final countries = await sdk.store.getCountries();

      // Find selected country if editing
      MagentoCountry? selectedCountry;
      if (widget.address?.countryCode != null && countries.isNotEmpty) {
        try {
          selectedCountry = countries.firstWhere(
            (c) => c.twoLetterAbbreviation?.toUpperCase() ==
                widget.address!.countryCode!.toUpperCase(),
          );
        } catch (e) {
          // Country not found, use first country as default
          selectedCountry = countries.first;
        }
      }

      // Find selected region if editing
      MagentoCountryRegion? selectedRegion;
      if (selectedCountry != null &&
          selectedCountry.availableRegions != null &&
          selectedCountry.availableRegions!.isNotEmpty &&
          widget.address?.region?.regionCode != null) {
        try {
          selectedRegion = selectedCountry.availableRegions!.firstWhere(
            (r) => r.code?.toUpperCase() ==
                widget.address!.region!.regionCode!.toUpperCase(),
          );
        } catch (e) {
          // Try matching by name
          try {
            selectedRegion = selectedCountry.availableRegions!.firstWhere(
              (r) => r.name == widget.address!.region!.region,
            );
          } catch (e2) {
            // Region not found, leave as null
            selectedRegion = null;
          }
        }
      }

      setState(() {
        _countries = countries;
        _selectedCountry = selectedCountry ?? (countries.isNotEmpty ? countries.first : null);
        _selectedRegion = selectedRegion;
        // Update country code controller
        if (_selectedCountry != null) {
          _countryCodeController.text =
              _selectedCountry!.twoLetterAbbreviation ?? '';
        }
        // Update region controllers
        if (_selectedRegion != null) {
          _regionController.text = _selectedRegion!.name ?? '';
          _regionCodeController.text = _selectedRegion!.code ?? '';
        }
      });
    } catch (e) {
      // If countries fail to load, continue with manual entry
      setState(() {
        _countries = [];
      });
    } finally {
      setState(() {
        _isLoadingCountries = false;
      });
    }
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _lastnameController.dispose();
    _streetLine1Controller.dispose();
    _streetLine2Controller.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _countryCodeController.dispose();
    _telephoneController.dispose();
    _regionController.dispose();
    _regionCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
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

      // Build street list
      final street = <String>[];
      if (_streetLine1Controller.text.trim().isNotEmpty) {
        street.add(_streetLine1Controller.text.trim());
      }
      if (_streetLine2Controller.text.trim().isNotEmpty) {
        street.add(_streetLine2Controller.text.trim());
      }

      // Build region if provided - use selected region from dropdown if available
      MagentoCustomerAddressRegion? region;
      if (_selectedRegion != null) {
        // Use selected region from dropdown
        region = MagentoCustomerAddressRegion(
          region: _selectedRegion!.name,
          regionCode: _selectedRegion!.code,
          regionId: _selectedRegion!.id,
        );
      } else if (_regionController.text.trim().isNotEmpty ||
          _regionCodeController.text.trim().isNotEmpty) {
        // Fallback to manual entry
        region = MagentoCustomerAddressRegion(
          region: _regionController.text.trim().isNotEmpty
              ? _regionController.text.trim()
              : null,
          regionCode: _regionCodeController.text.trim().isNotEmpty
              ? _regionCodeController.text.trim()
              : null,
        );
      }

      // Get country code from selected country or text field
      final countryCode = _selectedCountry?.twoLetterAbbreviation ??
          _countryCodeController.text.trim();
      
      // Get city from selected city or text field
      final city = _selectedCity?.localizedName ??
          _selectedCity?.name ??
          _cityController.text.trim();

      MagentoCustomerAddress? result;
      if (_isEditing) {
        // Update existing address
        result = await sdk.profile.updateAddress(
          id: widget.address!.id!,
          firstname: _firstnameController.text.trim(),
          lastname: _lastnameController.text.trim(),
          street: street,
          city: city,
          postcode: _postcodeController.text.trim(),
          countryCode: countryCode,
          telephone: _telephoneController.text.trim(),
          region: region,
          defaultShipping: _defaultShipping,
          defaultBilling: _defaultBilling,
        );
      } else {
        // Create new address
        result = await sdk.profile.createAddress(
          firstname: _firstnameController.text.trim(),
          lastname: _lastnameController.text.trim(),
          street: street,
          city: city,
          postcode: _postcodeController.text.trim(),
          countryCode: countryCode,
          telephone: _telephoneController.text.trim(),
          region: region,
          defaultShipping: _defaultShipping,
          defaultBilling: _defaultBilling,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Address updated successfully'
                : 'Address created successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(result);
      }
    } on AuthException catch (e) {
      setState(() {
        _error = 'Authentication error: ${e.message}';
      });
    } on MagentoGraphQLException catch (e) {
      setState(() {
        _error = 'Error: ${e.message}';
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
        title: Text(_isEditing ? 'Edit Address' : 'Add Address'),
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
              onPressed: _saveAddress,
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
                  labelText: 'First Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Last Name
              TextFormField(
                controller: _lastnameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Street Line 1
              TextFormField(
                controller: _streetLine1Controller,
                decoration: const InputDecoration(
                  labelText: 'Street Address *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Street Line 2
              TextFormField(
                controller: _streetLine2Controller,
                decoration: const InputDecoration(
                  labelText: 'Street Address Line 2',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home_outlined),
                ),
              ),
              const SizedBox(height: 16),
              // Country Dropdown
              if (_isLoadingCountries)
                const LinearProgressIndicator()
              else if (_countries != null && _countries!.isNotEmpty)
                DropdownButtonFormField<MagentoCountry>(
                  initialValue: _selectedCountry,
                  decoration: const InputDecoration(
                    labelText: 'Country *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.public),
                  ),
                  items: _countries!.map((country) {
                    return DropdownMenuItem<MagentoCountry>(
                      value: country,
                      child: Text(
                        '${country.fullNameEnglish ?? country.fullNameLocale ?? country.twoLetterAbbreviation ?? "Unknown"} (${country.twoLetterAbbreviation ?? ""})',
                      ),
                    );
                  }).toList(),
                  onChanged: (country) {
                    setState(() {
                      _selectedCountry = country;
                      _selectedCity = null;
                      if (country != null) {
                        _countryCodeController.text =
                            country.twoLetterAbbreviation ?? '';
                        
                        // Auto-select first region if available_regions is not empty
                        if (country.availableRegions != null &&
                            country.availableRegions!.isNotEmpty) {
                          _selectedRegion = country.availableRegions!.first;
                          _regionController.text = _selectedRegion!.name ?? '';
                          _regionCodeController.text = _selectedRegion!.code ?? '';
                          
                          // Auto-select first city if available
                          if (_selectedRegion!.cities != null &&
                              _selectedRegion!.cities!.isNotEmpty) {
                            _selectedCity = _selectedRegion!.cities!.first;
                            _cityController.text = _selectedCity!.localizedName ??
                                _selectedCity!.name ??
                                _selectedCity!.code ??
                                '';
                          } else {
                            _cityController.clear();
                          }
                        } else {
                          // No regions available, clear region selection
                          _selectedRegion = null;
                          _regionController.clear();
                          _regionCodeController.clear();
                          _cityController.clear();
                        }
                      } else {
                        _selectedRegion = null;
                        _regionController.clear();
                        _regionCodeController.clear();
                        _cityController.clear();
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Required';
                    }
                    return null;
                  },
                )
              else
                TextFormField(
                  controller: _countryCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Country Code *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.public),
                    helperText: 'e.g., US, GB, CA',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              // Region Dropdown (if country has regions)
              // Only show if a country is selected and it has available_regions
              if (_selectedCountry != null &&
                  _selectedCountry!.availableRegions != null &&
                  _selectedCountry!.availableRegions!.isNotEmpty)
                DropdownButtonFormField<MagentoCountryRegion>(
                  initialValue: _selectedRegion,
                  decoration: InputDecoration(
                    labelText: 'State/Province',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.map),
                    helperText: _selectedCountry != null
                        ? 'Regions for ${_selectedCountry!.fullNameEnglish ?? _selectedCountry!.twoLetterAbbreviation ?? "selected country"}'
                        : null,
                  ),
                  items: _selectedCountry!.availableRegions!.map((region) {
                    return DropdownMenuItem<MagentoCountryRegion>(
                      value: region,
                      child: Text(
                        '${region.name ?? region.code ?? "Unknown"}${region.code != null ? " (${region.code})" : ""}',
                      ),
                    );
                  }).toList(),
                  onChanged: (region) {
                    setState(() {
                      _selectedRegion = region;
                      _selectedCity = null;
                      if (region != null) {
                        _regionController.text = region.name ?? '';
                        _regionCodeController.text = region.code ?? '';
                        _cityController.clear();
                      }
                    });
                  },
                )
              else if (_selectedCountry != null &&
                  (_selectedCountry!.availableRegions == null ||
                      _selectedCountry!.availableRegions!.isEmpty))
                // Show message if country selected but no regions available
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No regions available for ${_selectedCountry!.fullNameEnglish ?? _selectedCountry!.twoLetterAbbreviation ?? "selected country"}. Please enter manually below.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Fallback to text fields if no regions available
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _regionController,
                        decoration: const InputDecoration(
                          labelText: 'State/Province',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.map),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _regionCodeController,
                        decoration: const InputDecoration(
                          labelText: 'State Code',
                          border: OutlineInputBorder(),
                          helperText: 'e.g., CA, NY',
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              // City Dropdown (if region has cities)
              if (_selectedRegion != null &&
                  _selectedRegion!.cities != null &&
                  _selectedRegion!.cities!.isNotEmpty)
                DropdownButtonFormField<MagentoCountryCity>(
                  initialValue: _selectedCity,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  items: _selectedRegion!.cities!.map((city) {
                    return DropdownMenuItem<MagentoCountryCity>(
                      value: city,
                      child: Text(
                        city.localizedName ?? city.name ?? city.code ?? 'Unknown',
                      ),
                    );
                  }).toList(),
                  onChanged: (city) {
                    setState(() {
                      _selectedCity = city;
                      if (city != null) {
                        _cityController.text =
                            city.localizedName ?? city.name ?? city.code ?? '';
                      }
                    });
                  },
                )
              else
                // Fallback to text field if no cities available
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(
                    labelText: 'City *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_city),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              // Postcode
              TextFormField(
                controller: _postcodeController,
                decoration: const InputDecoration(
                  labelText: 'Postal/ZIP Code *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.markunread_mailbox),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Telephone
              TextFormField(
                controller: _telephoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Default Shipping
              Card(
                child: SwitchListTile(
                  title: const Text('Default Shipping Address'),
                  value: _defaultShipping ?? false,
                  onChanged: (value) {
                    setState(() {
                      _defaultShipping = value;
                    });
                  },
                  secondary: const Icon(Icons.local_shipping),
                ),
              ),
              const SizedBox(height: 8),
              // Default Billing
              Card(
                child: SwitchListTile(
                  title: const Text('Default Billing Address'),
                  value: _defaultBilling ?? false,
                  onChanged: (value) {
                    setState(() {
                      _defaultBilling = value;
                    });
                  },
                  secondary: const Icon(Icons.payment),
                ),
              ),
              const SizedBox(height: 24),
              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
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
                    : Text(
                        _isEditing ? 'Update Address' : 'Create Address',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
