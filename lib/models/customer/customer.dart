import 'customer_address.dart';

/// Customer model representing a Magento customer
/// 
/// All fields are nullable to handle cases where:
/// - Some stores disable certain fields (e.g., gender, date_of_birth)
/// - GraphQL schema variations across Magento versions
/// - Optional customer attributes
class MagentoCustomer {
  /// Customer ID (nullable - may not be present in all responses)
  final String? id;
  
  /// Customer first name (nullable)
  final String? firstname;
  
  /// Customer last name (nullable)
  final String? lastname;
  
  /// Customer email (nullable)
  final String? email;
  
  /// Customer gender (nullable - may be disabled in store config)
  final int? gender;
  
  /// Customer date of birth (nullable - may be disabled in store config)
  final String? dateOfBirth;
  
  /// Whether customer is subscribed to newsletter (nullable)
  final bool? isSubscribed;
  
  /// Customer addresses (nullable list - may be empty or null)
  final List<MagentoCustomerAddress>? addresses;

  MagentoCustomer({
    this.id,
    this.firstname,
    this.lastname,
    this.email,
    this.gender,
    this.dateOfBirth,
    this.isSubscribed,
    this.addresses,
  });

  /// Parse customer from GraphQL JSON response
  /// 
  /// Defensive parsing: all fields are safely extracted with null checks
  factory MagentoCustomer.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert any value to String or null
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      if (value is int) return value.toString();
      return value.toString();
    }

    // Helper to safely convert any value to int or null
    int? _toIntOrNull(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed;
      }
      return null;
    }

    // Helper to safely convert any value to bool or null
    bool? _toBoolOrNull(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is String) {
        return value.toLowerCase() == 'true' || value == '1';
      }
      if (value is int) return value != 0;
      return null;
    }

    // Parse addresses - can be null, empty list, or list with items
    List<MagentoCustomerAddress>? addresses;
    if (json['addresses'] != null) {
      if (json['addresses'] is List) {
        final addressesList = json['addresses'] as List;
        if (addressesList.isEmpty) {
          addresses = [];
        } else {
          addresses = addressesList
              .map((addr) {
                try {
                  return MagentoCustomerAddress.fromJson(
                    addr as Map<String, dynamic>,
                  );
                } catch (e) {
                  // Log but don't fail - skip invalid address
                  return null;
                }
              })
              .whereType<MagentoCustomerAddress>()
              .toList();
        }
      }
    }

    return MagentoCustomer(
      id: _toStringOrNull(json['id']),
      firstname: _toStringOrNull(json['firstname']),
      lastname: _toStringOrNull(json['lastname']),
      email: _toStringOrNull(json['email']),
      gender: _toIntOrNull(json['gender']),
      dateOfBirth: _toStringOrNull(json['date_of_birth']),
      isSubscribed: _toBoolOrNull(json['is_subscribed']),
      addresses: addresses,
    );
  }

  @override
  String toString() {
    return 'MagentoCustomer(id: $id, email: $email, firstname: $firstname, lastname: $lastname)';
  }
}
