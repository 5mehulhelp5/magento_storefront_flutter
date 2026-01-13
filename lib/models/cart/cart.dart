import '../product/product.dart';

/// Cart model representing a Magento cart
class MagentoCart {
  final String id;
  final List<MagentoCartItem> items;
  final MagentoCartPrices? prices;
  final int totalQuantity;
  final bool isEmpty;

  MagentoCart({
    required this.id,
    required this.items,
    this.prices,
    required this.totalQuantity,
    required this.isEmpty,
  });

  factory MagentoCart.fromJson(Map<String, dynamic> json) {
    final itemsData = json['items'] as List<dynamic>? ?? [];
    
    return MagentoCart(
      id: _toString(json['id']),
      items: itemsData
          .map((item) => MagentoCartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      prices: json['prices'] != null
          ? MagentoCartPrices.fromJson(json['prices'] as Map<String, dynamic>)
          : null,
      totalQuantity: json['total_quantity'] as int? ?? 
                     itemsData.fold<int>(0, (sum, item) => sum + ((item as Map)['quantity'] as int? ?? 0)),
      isEmpty: itemsData.isEmpty,
    );
  }

  static String _toString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    return value.toString();
  }
}

/// Cart item model
class MagentoCartItem {
  final String id;
  final MagentoProduct product;
  final int quantity;
  final MagentoCartItemPrices? prices;

  MagentoCartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.prices,
  });

  factory MagentoCartItem.fromJson(Map<String, dynamic> json) {
    return MagentoCartItem(
      id: _toString(json['id']),
      product: MagentoProduct.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int? ?? 0,
      prices: json['prices'] != null
          ? MagentoCartItemPrices.fromJson(json['prices'] as Map<String, dynamic>)
          : null,
    );
  }

  static String _toString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is int) return value.toString();
    return value.toString();
  }
}

/// Cart prices model
class MagentoCartPrices {
  final MagentoMoney? grandTotal;
  final MagentoMoney? subtotalExcludingTax;
  final MagentoMoney? subtotalIncludingTax;

  MagentoCartPrices({
    this.grandTotal,
    this.subtotalExcludingTax,
    this.subtotalIncludingTax,
  });

  factory MagentoCartPrices.fromJson(Map<String, dynamic> json) {
    return MagentoCartPrices(
      grandTotal: json['grand_total'] != null
          ? MagentoMoney.fromJson(json['grand_total'] as Map<String, dynamic>)
          : null,
      subtotalExcludingTax: json['subtotal_excluding_tax'] != null
          ? MagentoMoney.fromJson(json['subtotal_excluding_tax'] as Map<String, dynamic>)
          : null,
      subtotalIncludingTax: json['subtotal_including_tax'] != null
          ? MagentoMoney.fromJson(json['subtotal_including_tax'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Cart item prices model
class MagentoCartItemPrices {
  final MagentoMoney? price;
  final MagentoMoney? rowTotal;

  MagentoCartItemPrices({
    this.price,
    this.rowTotal,
  });

  factory MagentoCartItemPrices.fromJson(Map<String, dynamic> json) {
    return MagentoCartItemPrices(
      price: json['price'] != null
          ? MagentoMoney.fromJson(json['price'] as Map<String, dynamic>)
          : null,
      rowTotal: json['row_total'] != null
          ? MagentoMoney.fromJson(json['row_total'] as Map<String, dynamic>)
          : null,
    );
  }
}
