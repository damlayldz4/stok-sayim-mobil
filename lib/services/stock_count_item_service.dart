import '../models/scanned_item.dart';
import 'api_client.dart';

/// Barkod okutma ve manuel miktar düzeltme çağrıları.
///
/// Eşik üstü bir miktar girildiğinde (ve `confirm` gönderilmediğinde)
/// backend 409 döner — bunu burada özel bir exception'a sarmıyoruz,
/// [ApiException.statusCode] üzerinden ekranda kontrol ediyoruz (bkz.
/// quantity_entry_screen.dart), çünkü backend'in ürettiği mesaj zaten
/// kullanıcıya gösterilecek tam cümle.
class StockCountItemService {
  final ApiClient _client;

  StockCountItemService(this._client);

  Future<List<ScannedItem>> getItems(int stockCountId) async {
    final json = await _client.get('/stock-counts/$stockCountId/items') as List<dynamic>;
    return json.map((e) => ScannedItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ScannedItem> scan(
    int stockCountId, {
    required String barcode,
    required int quantity,
    bool confirm = false,
  }) async {
    final json = await _client.post(
      '/stock-counts/$stockCountId/items/scan',
      body: {
        'barcode': barcode,
        'quantity': quantity,
        if (confirm) 'confirm': true,
      },
    );
    return ScannedItem.fromJson(json as Map<String, dynamic>);
  }

  Future<ScannedItem> updateQuantity(
    int stockCountId,
    int itemId, {
    required int quantity,
    bool confirm = false,
  }) async {
    final json = await _client.patch(
      '/stock-counts/$stockCountId/items/$itemId',
      body: {
        'counted_quantity': quantity,
        if (confirm) 'confirm': true,
      },
    );
    return ScannedItem.fromJson(json as Map<String, dynamic>);
  }
}
