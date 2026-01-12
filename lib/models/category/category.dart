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
    return MagentoCategory(
      id: json['id'] as String? ?? json['uid'] as String? ?? '',
      uid: json['uid'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      urlPath: json['url_path'] as String?,
      urlKey: json['url_key'] as String?,
      description: json['description'] as String?,
      image: json['image'] as String?,
      position: json['position'] as int?,
      level: json['level'] as int?,
      path: json['path'] as String?,
      children: json['children'] != null
          ? (json['children'] as List)
              .map((c) => MagentoCategory.fromJson(c as Map<String, dynamic>))
              .toList()
          : null,
      productCount: json['product_count'] as int?,
    );
  }
}
