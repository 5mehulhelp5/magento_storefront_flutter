/// Country model representing a Magento country
class MagentoCountry {
  /// Country ID (nullable)
  final String? id;
  
  /// Two-letter country code (e.g., "US", "GB") (nullable)
  final String? twoLetterAbbreviation;
  
  /// Three-letter country code (e.g., "USA", "GBR") (nullable)
  final String? threeLetterAbbreviation;
  
  /// Full country name in English (nullable)
  final String? fullNameEnglish;
  
  /// Full country name in locale (nullable)
  final String? fullNameLocale;
  
  /// Available regions for this country (nullable list)
  final List<MagentoCountryRegion>? availableRegions;

  MagentoCountry({
    this.id,
    this.twoLetterAbbreviation,
    this.threeLetterAbbreviation,
    this.fullNameEnglish,
    this.fullNameLocale,
    this.availableRegions,
  });

  /// Parse country from GraphQL JSON response
  factory MagentoCountry.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert any value to String or null
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      if (value is int) return value.toString();
      return value.toString();
    }

    // Parse available regions
    List<MagentoCountryRegion>? availableRegions;
    if (json['available_regions'] != null) {
      if (json['available_regions'] is List) {
        final regionsList = json['available_regions'] as List;
        if (regionsList.isNotEmpty) {
          availableRegions = regionsList
              .map((r) {
                try {
                  return MagentoCountryRegion.fromJson(
                    r as Map<String, dynamic>,
                  );
                } catch (e) {
                  return null;
                }
              })
              .whereType<MagentoCountryRegion>()
              .toList();
        }
      }
    }

    return MagentoCountry(
      id: _toStringOrNull(json['id']),
      twoLetterAbbreviation: _toStringOrNull(json['two_letter_abbreviation']),
      threeLetterAbbreviation: _toStringOrNull(json['three_letter_abbreviation']),
      fullNameEnglish: _toStringOrNull(json['full_name_english']),
      fullNameLocale: _toStringOrNull(json['full_name_locale']),
      availableRegions: availableRegions,
    );
  }

  @override
  String toString() {
    return 'MagentoCountry(id: $id, code: $twoLetterAbbreviation, name: $fullNameEnglish)';
  }
}

/// Region model representing a country region/state
class MagentoCountryRegion {
  /// Region ID (nullable)
  final String? id;
  
  /// Region code (e.g., "CA", "NY") (nullable)
  final String? code;
  
  /// Region name (e.g., "California", "New York") (nullable)
  final String? name;
  
  /// Available cities in this region (nullable list)
  final List<MagentoCountryCity>? cities;

  MagentoCountryRegion({
    this.id,
    this.code,
    this.name,
    this.cities,
  });

  /// Parse region from GraphQL JSON response
  factory MagentoCountryRegion.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert any value to String or null
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      if (value is int) return value.toString();
      return value.toString();
    }

    // Parse cities
    List<MagentoCountryCity>? cities;
    if (json['cities'] != null) {
      if (json['cities'] is List) {
        final citiesList = json['cities'] as List;
        if (citiesList.isNotEmpty) {
          cities = citiesList
              .map((c) {
                try {
                  return MagentoCountryCity.fromJson(
                    c as Map<String, dynamic>,
                  );
                } catch (e) {
                  return null;
                }
              })
              .whereType<MagentoCountryCity>()
              .toList();
        }
      }
    }

    return MagentoCountryRegion(
      id: _toStringOrNull(json['id']),
      code: _toStringOrNull(json['code']),
      name: _toStringOrNull(json['name']),
      cities: cities,
    );
  }

  @override
  String toString() {
    return 'MagentoCountryRegion(id: $id, code: $code, name: $name)';
  }
}

/// City model representing a city within a region
class MagentoCountryCity {
  /// City ID (nullable)
  final String? id;
  
  /// City code (nullable)
  final String? code;
  
  /// City name (nullable)
  final String? name;
  
  /// Localized city name (nullable)
  final String? localizedName;

  MagentoCountryCity({
    this.id,
    this.code,
    this.name,
    this.localizedName,
  });

  /// Parse city from GraphQL JSON response
  factory MagentoCountryCity.fromJson(Map<String, dynamic> json) {
    // Helper to safely convert any value to String or null
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      if (value is int) return value.toString();
      return value.toString();
    }

    return MagentoCountryCity(
      id: _toStringOrNull(json['id']),
      code: _toStringOrNull(json['code']),
      name: _toStringOrNull(json['name']),
      localizedName: _toStringOrNull(json['localized_name']),
    );
  }

  @override
  String toString() {
    return 'MagentoCountryCity(id: $id, code: $code, name: $name)';
  }
}
