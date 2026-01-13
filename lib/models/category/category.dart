/// Category model representing a Magento category
class MagentoCategory {
  final String id;
  final String uid;
  final String name;
  final String? urlPath;
  final String? urlKey;
  final String? description;
  final String? image;
  final int? position;
  final int? level;
  final String? path;
  final List<MagentoCategory>? children;
  final int? productCount;

  MagentoCategory({
    required this.id,
    required this.uid,
    required this.name,
    this.urlPath,
    this.urlKey,
    this.description,
    this.image,
    this.position,
    this.level,
    this.path,
    this.children,
    this.productCount,
  });

  factory MagentoCategory.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert id/uid to String
    String _toString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is int) return value.toString();
      return value.toString();
    }

    // Helper function to safely get String or null
    String? _toStringOrNull(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is int) return value.toString();
      return value.toString();
    }

    return MagentoCategory(
      id: _toString(json['id'] ?? json['uid']),
      uid: _toString(json['uid'] ?? json['id']),
      name: json['name'] as String? ?? '',
      urlPath: json['url_path'] as String?,
      urlKey: json['url_key'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      position: json['position'] is int ? json['position'] as int : (json['position'] is String ? int.tryParse(json['position'] as String) : null),
      level: json['level'] is int ? json['level'] as int : (json['level'] is String ? int.tryParse(json['level'] as String) : null),
      path: _toStringOrNull(json['path']),
      children: json['children'] != null
          ? (json['children'] as List)
              .map((c) => MagentoCategory.fromJson(c as Map<String, dynamic>))
              .toList()
          : null,
      productCount: json['product_count'] is int ? json['product_count'] as int : (json['product_count'] is String ? int.tryParse(json['product_count'] as String) : null),
    );
  }
}
