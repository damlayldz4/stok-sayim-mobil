import '../models/product.dart';
import 'api_client.dart';

/// Barkoda ait ürün bulunamadığında (API 404 döndüğünde) fırlatılır —
/// doküman md.11'deki tam mesajı ekranda göstermek için kullanılıyor.
class ProductNotFoundException implements Exception {}

class ProductService {
  final ApiClient _client;

  ProductService(this._client);

  Future<ProductInfo> findByBarcode(String barcode) async {
    try {
      final json = await _client.get('/products/barcode/$barcode');
      return ProductInfo.fromJson(json as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        throw ProductNotFoundException();
      }
      rethrow;
    }
  }
}
