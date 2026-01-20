import '../core/magento_client.dart';
import '../core/magento_exception.dart';
import '../core/magento_logger.dart';
import '../models/customer/customer.dart';
import '../models/customer/customer_address.dart';
import 'graphql/customer_profile_query.dart';
import 'graphql/update_customer_mutation.dart';
import 'graphql/create_customer_address_mutation.dart';
import 'graphql/update_customer_address_mutation.dart';
import 'graphql/delete_customer_address_mutation.dart';

/// Profile module for Magento Storefront
/// 
/// This module provides access to authenticated customer profile data.
/// 
/// **Supported Operations:**
/// - ✅ Fetch customer profile
/// - ✅ Fetch customer addresses
/// - ✅ Update customer profile information
/// 
/// **Out of Scope:**
/// - ❌ Change password (use auth module)
/// - ❌ Add/edit/delete addresses
/// - ❌ Orders
/// - ❌ Wishlist
/// 
/// **Authentication Required:**
/// This module requires a valid authentication token. The token must be set
/// via `MagentoClient.setAuthToken()` before calling any methods.
/// 
/// Example:
/// ```dart
/// final sdk = MagentoSDK(config: config);
/// await sdk.auth.login('user@example.com', 'password');
/// 
/// final profile = sdk.profile;
/// final customer = await profile.getProfile();
/// 
/// // Access addresses
/// final addresses = customer.addresses ?? [];
/// ```
class MagentoProfile {
  final MagentoClient _client;

  MagentoProfile(this._client);

  /// Get the authenticated customer's profile
  /// 
  /// This method fetches the complete customer profile including:
  /// - Basic information (id, name, email)
  /// - Optional fields (gender, date_of_birth, subscription status)
  /// - All customer addresses
  /// 
  /// **Authentication Required:**
  /// This method requires a valid authentication token. If no token is present
  /// or the token is invalid, a `MagentoAuthenticationException` will be thrown.
  /// 
  /// **Defensive Parsing:**
  /// All fields are parsed defensively to handle:
  /// - Stores that disable optional fields (gender, date_of_birth)
  /// - Missing or null values
  /// - Empty address lists
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   final customer = await profile.getProfile();
  ///   print('Customer: ${customer.firstname} ${customer.lastname}');
  ///   print('Email: ${customer.email}');
  ///   
  ///   // Access addresses (may be null or empty)
  ///   final addresses = customer.addresses ?? [];
  ///   for (final address in addresses) {
  ///     print('Address: ${address.street.join(", ")}');
  ///   }
  /// } on MagentoAuthenticationException catch (e) {
  ///   // Handle authentication error
  ///   print('Not authenticated: ${e.message}');
  /// } on MagentoGraphQLException catch (e) {
  ///   // Handle GraphQL error
  ///   print('GraphQL error: ${e.message}');
  /// }
  /// ```
  /// 
  /// Throws:
  /// - [MagentoAuthenticationException] if not authenticated or token is invalid
  /// - [MagentoGraphQLException] if GraphQL query fails
  /// - [MagentoNetworkException] if network request fails
  /// - [MagentoException] for other errors
  Future<MagentoCustomer> getProfile() async {
    // Validate authentication before making request
    if (_client.authToken == null || _client.authToken!.isEmpty) {
      throw AuthException(
        'Authentication required. Please login before fetching profile.',
        code: '401',
      );
    }

    try {
      // Execute GraphQL query
      final response = await _client.query(customerProfileQuery);

      // Extract data from response
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      // Extract customer data
      final customerData = data['customer'] as Map<String, dynamic>?;
      if (customerData == null) {
        // This should not happen for authenticated requests, but handle gracefully
        throw MagentoGraphQLException(
          'Customer data not found in response. User may not be authenticated.',
          originalError: response,
        );
      }

      // Parse customer model with defensive parsing
      try {
        return MagentoCustomer.fromJson(customerData);
      } catch (e, stackTrace) {
        MagentoLogger.error(
          '[MagentoProfile] Failed to parse customer data: ${e.toString()}',
          e,
          stackTrace,
        );
        throw UnknownMagentoException(
          'Failed to parse customer profile: ${e.toString()}',
          originalError: e,
        );
      }
    } on AuthException {
      // Re-throw auth exceptions as-is
      rethrow;
    } on MagentoGraphQLException {
      // Re-throw GraphQL exceptions as-is
      rethrow;
    } on MagentoException catch (e) {
      MagentoLogger.error(
        '[MagentoProfile] Get profile error: ${e.toString()}',
        e,
      );
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoProfile] Failed to get profile: ${e.toString()}',
        e,
        stackTrace,
      );
      throw UnknownMagentoException(
        'Failed to get customer profile: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Update the authenticated customer's profile information
  /// 
  /// This method updates customer profile fields. All parameters are optional,
  /// so you can update only the fields you want to change.
  /// 
  /// **Authentication Required:**
  /// This method requires a valid authentication token. If no token is present
  /// or the token is invalid, an `AuthException` will be thrown.
  /// 
  /// **Field Notes:**
  /// - `firstname` and `lastname`: Basic customer name fields
  /// - `gender`: Integer value (1 = Male, 2 = Female, null = Not specified)
  /// - `dateOfBirth`: String in format "YYYY-MM-DD" (e.g., "1990-01-15")
  /// - `isSubscribed`: Boolean for newsletter subscription status
  /// 
  /// **Note:** Email cannot be updated via this method. Magento 2 requires a separate
  /// `updateCustomerEmail` mutation for email changes, which is not currently supported.
  /// 
  /// **Defensive Parsing:**
  /// The response is parsed defensively to handle optional fields and schema variations.
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   final updatedCustomer = await profile.updateProfile(
  ///     firstname: 'John',
  ///     lastname: 'Doe',
  ///     isSubscribed: true,
  ///   );
  ///   print('Updated customer: ${updatedCustomer.firstname} ${updatedCustomer.lastname}');
  /// } on AuthException catch (e) {
  ///   // Handle authentication error
  ///   print('Not authenticated: ${e.message}');
  /// } on MagentoGraphQLException catch (e) {
  ///   // Handle GraphQL error (e.g., validation errors)
  ///   print('Update failed: ${e.message}');
  /// }
  /// ```
  /// 
  /// Throws:
  /// - [AuthException] if not authenticated or token is invalid
  /// - [MagentoGraphQLException] if GraphQL mutation fails (e.g., validation errors)
  /// - [MagentoNetworkException] if network request fails
  /// - [UnknownMagentoException] for other errors
  Future<MagentoCustomer> updateProfile({
    String? firstname,
    String? lastname,
    int? gender,
    String? dateOfBirth,
    bool? isSubscribed,
  }) async {
    // Validate authentication before making request
    if (_client.authToken == null || _client.authToken!.isEmpty) {
      throw AuthException(
        'Authentication required. Please login before updating profile.',
        code: '401',
      );
    }

    // Build variables map - only include non-null values
    final variables = <String, dynamic>{};
    if (firstname != null) variables['firstname'] = firstname;
    if (lastname != null) variables['lastname'] = lastname;
    if (gender != null) variables['gender'] = gender;
    if (dateOfBirth != null) variables['dateOfBirth'] = dateOfBirth;
    if (isSubscribed != null) variables['isSubscribed'] = isSubscribed;

    // At least one field must be provided
    if (variables.isEmpty) {
      throw MagentoException(
        'At least one field must be provided to update the profile.',
      );
    }

    try {
      // Execute GraphQL mutation
      final response = await _client.mutate(
        updateCustomerMutation,
        variables: variables,
      );

      // Extract data from response
      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      // Extract updateCustomerV2 data
      final updateData = data['updateCustomerV2'] as Map<String, dynamic>?;
      if (updateData == null) {
        throw MagentoGraphQLException(
          'Update customer data not found in response.',
          originalError: response,
        );
      }

      // Extract customer data
      final customerData = updateData['customer'] as Map<String, dynamic>?;
      if (customerData == null) {
        throw MagentoGraphQLException(
          'Customer data not found in update response.',
          originalError: response,
        );
      }

      // Parse customer model with defensive parsing
      try {
        return MagentoCustomer.fromJson(customerData);
      } catch (e, stackTrace) {
        MagentoLogger.error(
          '[MagentoProfile] Failed to parse updated customer data: ${e.toString()}',
          e,
          stackTrace,
        );
        throw UnknownMagentoException(
          'Failed to parse updated customer profile: ${e.toString()}',
          originalError: e,
        );
      }
    } on AuthException {
      // Re-throw auth exceptions as-is
      rethrow;
    } on MagentoGraphQLException {
      // Re-throw GraphQL exceptions as-is
      rethrow;
    } on MagentoException catch (e) {
      MagentoLogger.error(
        '[MagentoProfile] Update profile error: ${e.toString()}',
        e,
      );
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoProfile] Failed to update profile: ${e.toString()}',
        e,
        stackTrace,
      );
      throw UnknownMagentoException(
        'Failed to update customer profile: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Create a new customer address
  /// 
  /// This method creates a new address for the authenticated customer.
  /// 
  /// **Authentication Required:**
  /// This method requires a valid authentication token. If no token is present
  /// or the token is invalid, an `AuthException` will be thrown.
  /// 
  /// **Required Fields:**
  /// - `firstname`: Customer's first name
  /// - `lastname`: Customer's last name
  /// - `street`: List of street address lines (max 2 lines)
  /// - `city`: City name
  /// - `postcode`: Postal/ZIP code
  /// - `countryCode`: Country code (e.g., "US", "GB", "CA")
  /// - `telephone`: Phone number
  /// 
  /// **Optional Fields:**
  /// - `region`: Region information (for countries with states/provinces)
  /// - `defaultShipping`: Set as default shipping address
  /// - `defaultBilling`: Set as default billing address
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   final address = await profile.createAddress(
  ///     firstname: 'John',
  ///     lastname: 'Doe',
  ///     street: ['123 Main St', 'Apt 4B'],
  ///     city: 'Phoenix',
  ///     postcode: '85001',
  ///     countryCode: 'US',
  ///     telephone: '555-1234',
  ///     region: MagentoCustomerAddressRegion(
  ///       region: 'Arizona',
  ///       regionCode: 'AZ',
  ///     ),
  ///     defaultShipping: true,
  ///   );
  ///   print('Created address: ${address.id}');
  /// } on AuthException catch (e) {
  ///   // Handle authentication error
  /// } on MagentoGraphQLException catch (e) {
  ///   // Handle validation errors
  /// }
  /// ```
  /// 
  /// Throws:
  /// - [AuthException] if not authenticated or token is invalid
  /// - [MagentoGraphQLException] if GraphQL mutation fails (e.g., validation errors)
  /// - [MagentoNetworkException] if network request fails
  /// - [UnknownMagentoException] for other errors
  Future<MagentoCustomerAddress> createAddress({
    required String firstname,
    required String lastname,
    required List<String> street,
    required String city,
    required String postcode,
    required String countryCode,
    required String telephone,
    MagentoCustomerAddressRegion? region,
    bool? defaultShipping,
    bool? defaultBilling,
  }) async {
    // Validate authentication
    if (_client.authToken == null || _client.authToken!.isEmpty) {
      throw AuthException(
        'Authentication required. Please login before creating address.',
        code: '401',
      );
    }

    // Validate required fields
    if (firstname.trim().isEmpty) {
      throw MagentoException('First name is required');
    }
    if (lastname.trim().isEmpty) {
      throw MagentoException('Last name is required');
    }
    if (street.isEmpty || street.any((s) => s.trim().isEmpty)) {
      throw MagentoException('Street address is required');
    }
    if (street.length > 2) {
      throw MagentoException('Street address cannot have more than 2 lines');
    }
    if (city.trim().isEmpty) {
      throw MagentoException('City is required');
    }
    if (postcode.trim().isEmpty) {
      throw MagentoException('Postcode is required');
    }
    if (countryCode.trim().isEmpty) {
      throw MagentoException('Country code is required');
    }
    if (telephone.trim().isEmpty) {
      throw MagentoException('Telephone is required');
    }

    // Build variables
    final variables = <String, dynamic>{
      'firstname': firstname.trim(),
      'lastname': lastname.trim(),
      'street': street.map((s) => s.trim()).toList(),
      'city': city.trim(),
      'postcode': postcode.trim(),
      'countryCode': countryCode.trim().toUpperCase(),
      'telephone': telephone.trim(),
    };

    // Add optional region
    if (region != null) {
      final regionInput = <String, dynamic>{};
      if (region.region != null) {
        regionInput['region'] = region.region;
      }
      if (region.regionCode != null) {
        regionInput['region_code'] = region.regionCode;
      }
      if (region.regionId != null) {
        regionInput['region_id'] = int.tryParse(region.regionId!) ?? region.regionId;
      }
      if (regionInput.isNotEmpty) {
        variables['region'] = regionInput;
      }
    }

    // Add optional default flags
    if (defaultShipping != null) {
      variables['defaultShipping'] = defaultShipping;
    }
    if (defaultBilling != null) {
      variables['defaultBilling'] = defaultBilling;
    }

    try {
      final response = await _client.mutate(
        createCustomerAddressMutation,
        variables: variables,
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final addressData = data['createCustomerAddress'] as Map<String, dynamic>?;
      if (addressData == null) {
        throw MagentoGraphQLException(
          'Address data not found in response.',
          originalError: response,
        );
      }

      try {
        return MagentoCustomerAddress.fromJson(addressData);
      } catch (e, stackTrace) {
        MagentoLogger.error(
          '[MagentoProfile] Failed to parse created address: ${e.toString()}',
          e,
          stackTrace,
        );
        throw UnknownMagentoException(
          'Failed to parse created address: ${e.toString()}',
          originalError: e,
        );
      }
    } on AuthException {
      rethrow;
    } on MagentoGraphQLException {
      rethrow;
    } on MagentoException catch (e) {
      MagentoLogger.error(
        '[MagentoProfile] Create address error: ${e.toString()}',
        e,
      );
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoProfile] Failed to create address: ${e.toString()}',
        e,
        stackTrace,
      );
      throw UnknownMagentoException(
        'Failed to create address: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Update an existing customer address
  /// 
  /// This method updates an existing address. Only provided fields will be updated.
  /// 
  /// **Authentication Required:**
  /// This method requires a valid authentication token. If no token is present
  /// or the token is invalid, an `AuthException` will be thrown.
  /// 
  /// **Required:**
  /// - `id`: The address ID to update (must belong to the authenticated customer)
  /// 
  /// **Optional Fields (partial updates supported):**
  /// All other fields are optional - only include fields you want to change.
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   final updatedAddress = await profile.updateAddress(
  ///     id: '123',
  ///     city: 'New City',
  ///     postcode: '12345',
  ///   );
  ///   print('Updated address: ${updatedAddress.city}');
  /// } on AuthException catch (e) {
  ///   // Handle authentication error
  /// } on MagentoGraphQLException catch (e) {
  ///   // Handle errors (e.g., address not found, validation errors)
  /// }
  /// ```
  /// 
  /// Throws:
  /// - [AuthException] if not authenticated or token is invalid
  /// - [MagentoGraphQLException] if GraphQL mutation fails (e.g., address not found, validation errors)
  /// - [MagentoNetworkException] if network request fails
  /// - [UnknownMagentoException] for other errors
  Future<MagentoCustomerAddress> updateAddress({
    required String id,
    String? firstname,
    String? lastname,
    List<String>? street,
    String? city,
    String? postcode,
    String? countryCode,
    String? telephone,
    MagentoCustomerAddressRegion? region,
    bool? defaultShipping,
    bool? defaultBilling,
  }) async {
    // Validate authentication
    if (_client.authToken == null || _client.authToken!.isEmpty) {
      throw AuthException(
        'Authentication required. Please login before updating address.',
        code: '401',
      );
    }

    // Validate address ID
    final addressIdInt = int.tryParse(id);
    if (addressIdInt == null) {
      throw MagentoException('Invalid address ID: $id');
    }

    // Validate street if provided
    if (street != null) {
      if (street.isEmpty || street.any((s) => s.trim().isEmpty)) {
        throw MagentoException('Street address cannot be empty');
      }
      if (street.length > 2) {
        throw MagentoException('Street address cannot have more than 2 lines');
      }
    }

    // Build variables
    final variables = <String, dynamic>{
      'id': addressIdInt,
    };

    if (firstname != null && firstname.trim().isNotEmpty) {
      variables['firstname'] = firstname.trim();
    }
    if (lastname != null && lastname.trim().isNotEmpty) {
      variables['lastname'] = lastname.trim();
    }
    if (street != null) {
      variables['street'] = street.map((s) => s.trim()).toList();
    }
    if (city != null && city.trim().isNotEmpty) {
      variables['city'] = city.trim();
    }
    if (postcode != null && postcode.trim().isNotEmpty) {
      variables['postcode'] = postcode.trim();
    }
    if (countryCode != null && countryCode.trim().isNotEmpty) {
      variables['countryCode'] = countryCode.trim().toUpperCase();
    }
    if (telephone != null && telephone.trim().isNotEmpty) {
      variables['telephone'] = telephone.trim();
    }

    // Add optional region
    if (region != null) {
      final regionInput = <String, dynamic>{};
      if (region.region != null) {
        regionInput['region'] = region.region;
      }
      if (region.regionCode != null) {
        regionInput['region_code'] = region.regionCode;
      }
      if (region.regionId != null) {
        regionInput['region_id'] = int.tryParse(region.regionId!) ?? region.regionId;
      }
      if (regionInput.isNotEmpty) {
        variables['region'] = regionInput;
      }
    }

    // Add optional default flags
    if (defaultShipping != null) {
      variables['defaultShipping'] = defaultShipping;
    }
    if (defaultBilling != null) {
      variables['defaultBilling'] = defaultBilling;
    }

    // At least one field (besides id) must be provided
    if (variables.length == 1) {
      throw MagentoException('At least one field must be provided to update the address.');
    }

    try {
      final response = await _client.mutate(
        updateCustomerAddressMutation,
        variables: variables,
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final addressData = data['updateCustomerAddress'] as Map<String, dynamic>?;
      if (addressData == null) {
        throw MagentoGraphQLException(
          'Address data not found in response.',
          originalError: response,
        );
      }

      try {
        return MagentoCustomerAddress.fromJson(addressData);
      } catch (e, stackTrace) {
        MagentoLogger.error(
          '[MagentoProfile] Failed to parse updated address: ${e.toString()}',
          e,
          stackTrace,
        );
        throw UnknownMagentoException(
          'Failed to parse updated address: ${e.toString()}',
          originalError: e,
        );
      }
    } on AuthException {
      rethrow;
    } on MagentoGraphQLException {
      rethrow;
    } on MagentoException catch (e) {
      MagentoLogger.error(
        '[MagentoProfile] Update address error: ${e.toString()}',
        e,
      );
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoProfile] Failed to update address: ${e.toString()}',
        e,
        stackTrace,
      );
      throw UnknownMagentoException(
        'Failed to update address: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Delete a customer address
  /// 
  /// This method deletes an address for the authenticated customer.
  /// 
  /// **Authentication Required:**
  /// This method requires a valid authentication token. If no token is present
  /// or the token is invalid, an `AuthException` will be thrown.
  /// 
  /// **Constraints:**
  /// - Cannot delete an address if it is set as default_shipping or default_billing
  /// - Must assign a different address as default before deletion
  /// - Address must belong to the authenticated customer
  /// 
  /// Example:
  /// ```dart
  /// try {
  ///   await profile.deleteAddress('123');
  ///   print('Address deleted successfully');
  /// } on AuthException catch (e) {
  ///   // Handle authentication error
  /// } on MagentoGraphQLException catch (e) {
  ///   // Handle errors (e.g., address is default, address not found)
  /// }
  /// ```
  /// 
  /// Throws:
  /// - [AuthException] if not authenticated or token is invalid
  /// - [MagentoGraphQLException] if GraphQL mutation fails (e.g., address is default, address not found)
  /// - [MagentoNetworkException] if network request fails
  /// - [UnknownMagentoException] for other errors
  Future<bool> deleteAddress(String id) async {
    // Validate authentication
    if (_client.authToken == null || _client.authToken!.isEmpty) {
      throw AuthException(
        'Authentication required. Please login before deleting address.',
        code: '401',
      );
    }

    // Validate address ID
    final addressIdInt = int.tryParse(id);
    if (addressIdInt == null) {
      throw MagentoException('Invalid address ID: $id');
    }

    try {
      final response = await _client.mutate(
        deleteCustomerAddressMutation,
        variables: {'id': addressIdInt},
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw MagentoException('Invalid response from server');
      }

      final result = data['deleteCustomerAddress'] as bool?;
      if (result == null) {
        throw MagentoGraphQLException(
          'Delete result not found in response.',
          originalError: response,
        );
      }

      return result;
    } on AuthException {
      rethrow;
    } on MagentoGraphQLException {
      rethrow;
    } on MagentoException catch (e) {
      MagentoLogger.error(
        '[MagentoProfile] Delete address error: ${e.toString()}',
        e,
      );
      rethrow;
    } catch (e, stackTrace) {
      MagentoLogger.error(
        '[MagentoProfile] Failed to delete address: ${e.toString()}',
        e,
        stackTrace,
      );
      throw UnknownMagentoException(
        'Failed to delete address: ${e.toString()}',
        originalError: e,
      );
    }
  }
}
