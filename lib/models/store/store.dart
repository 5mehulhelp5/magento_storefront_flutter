/// Store model representing a Magento store
class MagentoStore {
  final String id;
  final String code;
  final String name;
  final String? websiteId;
  final String? locale;
  final String? baseCurrencyCode;
  final String? defaultDisplayCurrencyCode;
  final String? timezone;
  final String? weightUnit;
  final String? baseUrl;
  final String? secureBaseUrl;

  MagentoStore({
    required this.id,
    required this.code,
    required this.name,
    this.websiteId,
    this.locale,
    this.baseCurrencyCode,
    this.defaultDisplayCurrencyCode,
    this.timezone,
    this.weightUnit,
    this.baseUrl,
    this.secureBaseUrl,
  });

  factory MagentoStore.fromJson(Map<String, dynamic> json) {
    return MagentoStore(
      id: json['id'] as String? ?? json['store_id'] as String? ?? '',
      code: json['code'] as String? ?? json['store_code'] as String? ?? '',
      name: json['name'] as String? ?? json['store_name'] as String? ?? '',
      websiteId: json['website_id'] as String?,
      locale: json['locale'] as String?,
      baseCurrencyCode: json['base_currency_code'] as String?,
      defaultDisplayCurrencyCode: json['default_display_currency_code'] as String?,
      timezone: json['timezone'] as String?,
      weightUnit: json['weight_unit'] as String?,
      baseUrl: json['base_url'] as String?,
      secureBaseUrl: json['secure_base_url'] as String?,
    );
  }
}

/// Store configuration model
class MagentoStoreConfig {
  final String? id;
  final String? code;
  final String? websiteId;
  final String? locale;
  final String? baseCurrencyCode;
  final String? defaultDisplayCurrencyCode;
  final String? timezone;
  final String? weightUnit;
  final String? baseUrl;
  final String? secureBaseUrl;
  final String? storeName;
  final bool? catalogSearchEnabled;
  final bool? useStoreInUrl;

  MagentoStoreConfig({
    this.id,
    this.code,
    this.websiteId,
    this.locale,
    this.baseCurrencyCode,
    this.defaultDisplayCurrencyCode,
    this.timezone,
    this.weightUnit,
    this.baseUrl,
    this.secureBaseUrl,
    this.storeName,
    this.catalogSearchEnabled,
    this.useStoreInUrl,
  });

  factory MagentoStoreConfig.fromJson(Map<String, dynamic> json) {
    return MagentoStoreConfig(
      id: json['id'] as String?,
      code: json['code'] as String?,
      websiteId: json['website_id'] as String?,
      locale: json['locale'] as String?,
      baseCurrencyCode: json['base_currency_code'] as String?,
      defaultDisplayCurrencyCode: json['default_display_currency_code'] as String?,
      timezone: json['timezone'] as String?,
      weightUnit: json['weight_unit'] as String?,
      baseUrl: json['base_url'] as String?,
      secureBaseUrl: json['secure_base_url'] as String?,
      storeName: json['store_name'] as String?,
      catalogSearchEnabled: json['catalog_search_enabled'] as bool?,
      useStoreInUrl: json['use_store_in_url'] as bool?,
    );
  }
}
