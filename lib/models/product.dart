class ProductInfo {
  final int id;
  final String name;
  final String? code;
  final String barcode;
  final int expectedQuantity;

  ProductInfo({
    required this.id,
    required this.name,
    this.code,
    required this.barcode,
    required this.expectedQuantity,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: (json['id'] as num).toInt(),
      name: json['product_name'] as String,
      code: json['product_code'] as String?,
      barcode: json['barcode'] as String,
      // API'nin farklı endpoint'leri (barkod sorgulama vs. sayım
      // listesi) bu alanı her zaman aynı şekilde döndürmeyebilir —
      // eksikse uygulamanın çökmesindense 0 göstermek daha güvenli.
      expectedQuantity: (json['expected_quantity'] as num?)?.toInt() ?? 0,
    );
  }
}