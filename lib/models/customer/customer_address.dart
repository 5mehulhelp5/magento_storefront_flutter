/// Customer address model representing a Magento customer address
/// 
/// All fields are nullable to handle:
/// - Optional address fields
/// - Stores that don't require all fields
/// - GraphQL schema variations
class MagentoCustomerAddress {
  /// Address ID (nullable)
  final String? id;
  
  /// First name (nullable)
  final String? firstname;
  
  /// Last name (nullable)
  final String? lastname;
  
  /// Street address lines (MUST be List<String> - Magento returns array)
  /// Can be empty list but not null
  final List<String> street;
  
  /// City (nullable)
  final String? city;
  
  /// Region information (nullable - may not be present for some countries)
  final MagentoCustomerAddressRegion? region;
  
  /// Postal/ZIP code (nullable)
  final String? postcode;
  
  /// Country code (e.g., "US", "GB") (nullable)
  final String? countryCode;
  
  /// Telephone number (nullable)
  final String? telephone;
  
  /// Whether this is the default shipping address (nullable)
  final bool? defaultShipping;
  
  /// Whether this is the default billing address (nullable)
  final bool? defaultBilling;

  MagentoCustomerAddress({
    this.id,
    this.firstname,
    this.lastname,
    required this.street,
    this.city,
    this.region,
    this.postcode,
    this.countryCode,
    this.telephone,
    this.defaultShipping,
    this.defaultBilling,
  });

  /// Parse address from GraphQL JSON response
  /// 
  /// Defensive parsing: handles null values, type conversions, and edge cases
  factory MagentoCustomerAddress.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert any value to String or null
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      if (value is int) return value.toString();
      return value.toString();
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

    // Parse street - MUST be List<String>
    // Magento GraphQL returns street as an array of strings
    List<String> street = [];
    if (json['street'] != null) {
      if (json['street'] is List) {
        street = (json['street'] as List)
            .map((s) => _toStringOrNull(s) ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      } else if (json['street'] is String) {
        // Fallback: if it's a string, convert to list
        final streetStr = json['street'] as String;
        if (streetStr.isNotEmpty) {
          street = [streetStr];
        }
      }
    }

    // Parse region - can be null
    MagentoCustomerAddressRegion? region;
    if (json['region'] != null && json['region'] is Map) {
      try {
        region = MagentoCustomerAddressRegion.fromJson(
          json['region'] as Map<String, dynamic>,
        );
      } catch (e) {
        // If region parsing fails, leave it as null
        region = null;
      }
    }

    return MagentoCustomerAddress(
      id: _toStringOrNull(json['id']),
      firstname: _toStringOrNull(json['firstname']),
      lastname: _toStringOrNull(json['lastname']),
      street: street,
      city: _toStringOrNull(json['city']),
      region: region,
      postcode: _toStringOrNull(json['postcode']),
      countryCode: _toStringOrNull(json['country_code']),
      telephone: _toStringOrNull(json['telephone']),
      defaultShipping: _toBoolOrNull(json['default_shipping']),
      defaultBilling: _toBoolOrNull(json['default_billing']),
    );
  }

  @override
  String toString() {
    return 'MagentoCustomerAddress(id: $id, street: ${street.join(", ")}, city: $city, countryCode: $countryCode)';
  }
}

/// Region information for customer address
/// 
/// All fields are nullable as region structure may vary
class MagentoCustomerAddressRegion {
  /// Region name (e.g., "California") (nullable)
  final String? region;
  
  /// Region code (e.g., "CA") (nullable)
  final String? regionCode;
  
  /// Region ID (nullable)
  final String? regionId;

  MagentoCustomerAddressRegion({
    this.region,
    this.regionCode,
    this.regionId,
  });

  /// Parse region from GraphQL JSON response
  factory MagentoCustomerAddressRegion.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert any value to String or null
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      if (value is int) return value.toString();
      return value.toString();
    }

    return MagentoCustomerAddressRegion(
      region: _toStringOrNull(json['region']),
      regionCode: _toStringOrNull(json['region_code']),
      regionId: _toStringOrNull(json['region_id']),
    );
  }

  @override
  String toString() {
    return 'MagentoCustomerAddressRegion(region: $region, regionCode: $regionCode, regionId: $regionId)';
  }
}
