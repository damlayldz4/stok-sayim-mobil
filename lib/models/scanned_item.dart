import 'product.dart';

/// `stock_count_items` tablosundaki TEK bir satırı temsil eder — danışman
/// notu gereği artık her okutma ayrı bir satır, bu yüzden bir ürün için
/// listede birden fazla [ScannedItem] görünebilir.
class ScannedItem {
  final int id;
  final ProductInfo product;
  final int expectedQuantity;
  final int countedQuantity;
  final String? countedByName;
  final String? countedAt;

  ScannedItem({
    required this.id,
    required this.product,
    required this.expectedQuantity,
    required this.countedQuantity,
    this.countedByName,
    this.countedAt,
  });

  factory ScannedItem.fromJson(Map<String, dynamic> json) {
    return ScannedItem(
      id: (json['id'] as num).toInt(),
      product: ProductInfo.fromJson(json['product'] as Map<String, dynamic>),
      expectedQuantity: (json['expected_quantity'] as num?)?.toInt() ?? 0,
      countedQuantity: (json['counted_quantity'] as num?)?.toInt() ?? 0,
      countedByName: json['counted_by_name'] as String?,
      countedAt: json['counted_at'] as String?,
    );
  }
}