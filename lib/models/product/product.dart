import '../category/category.dart';

/// Product model representing a Magento product
class MagentoProduct {
  final String id;
  final String sku;
  final String name;
  final String? urlKey;
  final String? description;
  final String? shortDescription;
  final List<MagentoProductImage> images;
  final MagentoPriceRange? priceRange;
  final List<MagentoProductAttribute> attributes;
  final List<MagentoCategory>? categories;
  final bool? inStock;
  final String? stockStatus;

  MagentoProduct({
    required this.id,
    required this.sku,
    required this.name,
    this.urlKey,
    this.description,
    this.shortDescription,
    this.images = const [],
    this.priceRange,
    this.attributes = const [],
    this.categories,
    this.inStock,
    this.stockStatus,
  });

  factory MagentoProduct.fromJson(Map<String, dynamic> json) {
    // Handle description which can be a string or an object with html field
    String? description;
    if (json['description'] != null) {
      if (json['description'] is String) {
        description = json['description'] as String;
      } else if (json['description'] is Map) {
        description = (json['description'] as Map)['html'] as String?;
      }
    }

    // Handle short_description which can be a string or an object with html field
    String? shortDescription;
    if (json['short_description'] != null) {
      if (json['short_description'] is String) {
        shortDescription = json['short_description'] as String;
      } else if (json['short_description'] is Map) {
        shortDescription = (json['short_description'] as Map)['html'] as String?;
      }
    }

    return MagentoProduct(
      id: json['id'] as String? ?? json['uid'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      urlKey: json['url_key'] as String?,
      description: description,
      shortDescription: shortDescription,
      images: (json['image'] != null || json['images'] != null)
          ? _parseImages(json['image'] ?? json['images'])
          : [],
      priceRange: json['price_range'] != null
          ? MagentoPriceRange.fromJson(json['price_range'] as Map<String, dynamic>)
          : null,
      attributes: json['attributes'] != null
          ? (json['attributes'] as List)
              .map((a) => MagentoProductAttribute.fromJson(a as Map<String, dynamic>))
              .toList()
          : [],
      categories: json['categories'] != null
          ? (json['categories'] as List)
              .map((c) => MagentoCategory.fromJson(c as Map<String, dynamic>))
              .toList()
          : null,
      inStock: json['stock_status'] == 'IN_STOCK',
      stockStatus: json['stock_status'] as String?,
    );
  }

  static List<MagentoProductImage> _parseImages(dynamic imageData) {
    if (imageData is List) {
      return imageData
          .map((img) => MagentoProductImage.fromJson(img as Map<String, dynamic>))
          .toList();
    } else if (imageData is Map) {
      return [MagentoProductImage.fromJson(imageData as Map<String, dynamic>)];
    }
    return [];
  }
}

/// Product image model
class MagentoProductImage {
  final String url;
  final String? label;
  final int? position;

  MagentoProductImage({
    required this.url,
    this.label,
    this.position,
  });

  factory MagentoProductImage.fromJson(Map<String, dynamic> json) {
    return MagentoProductImage(
      url: json['url'] as String? ?? json['src'] as String? ?? '',
      label: json['label'] as String?,
      position: json['position'] as int?,
    );
  }
}

/// Price range model
class MagentoPriceRange {
  final MagentoPrice? minimumPrice;
  final MagentoPrice? maximumPrice;

  MagentoPriceRange({
    this.minimumPrice,
    this.maximumPrice,
  });

  factory MagentoPriceRange.fromJson(Map<String, dynamic> json) {
    return MagentoPriceRange(
      minimumPrice: json['minimum_price'] != null
          ? MagentoPrice.fromJson(json['minimum_price'] as Map<String, dynamic>)
          : null,
      maximumPrice: json['maximum_price'] != null
          ? MagentoPrice.fromJson(json['maximum_price'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Price model
class MagentoPrice {
  final MagentoMoney? regularPrice;
  final MagentoMoney? finalPrice;
  final MagentoMoney? discount;

  MagentoPrice({
    this.regularPrice,
    this.finalPrice,
    this.discount,
  });

  factory MagentoPrice.fromJson(Map<String, dynamic> json) {
    return MagentoPrice(
      regularPrice: json['regular_price'] != null
          ? MagentoMoney.fromJson(json['regular_price'] as Map<String, dynamic>)
          : null,
      finalPrice: json['final_price'] != null
          ? MagentoMoney.fromJson(json['final_price'] as Map<String, dynamic>)
          : null,
      discount: json['discount'] != null
          ? MagentoMoney.fromJson(json['discount'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Money model
class MagentoMoney {
  final double value;
  final String currency;

  MagentoMoney({
    required this.value,
    required this.currency,
  });

  factory MagentoMoney.fromJson(Map<String, dynamic> json) {
    return MagentoMoney(
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}

/// Product attribute model
class MagentoProductAttribute {
  final String code;
  final String? value;
  final String? label;

  MagentoProductAttribute({
    required this.code,
    this.value,
    this.label,
  });

  factory MagentoProductAttribute.fromJson(Map<String, dynamic> json) {
    return MagentoProductAttribute(
      code: json['code'] as String? ?? '',
      value: json['value'] as String?,
      label: json['label'] as String?,
    );
  }
}
