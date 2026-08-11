import '../models/stock_count.dart';
import 'api_client.dart';

class StockCountService {
  final ApiClient _client;

  StockCountService(this._client);

  /// Admin için tüm sayımlar, sayım personeli için yalnızca atanmış
  /// sayımlar döner — bu filtre backend'de zaten role'e göre uygulanıyor.
  Future<List<StockCount>> getAssigned() async {
    final json = await _client.get('/stock-counts') as List<dynamic>;
    return json.map((e) => StockCount.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StockCount> getDetail(int id) async {
    final json = await _client.get('/stock-counts/$id');
    return StockCount.fromJson(json as Map<String, dynamic>);
  }

  Future<void> complete(int id) async {
    await _client.post('/stock-counts/$id/complete');
  }
}
