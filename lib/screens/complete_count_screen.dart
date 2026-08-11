import 'package:flutter/material.dart';

import '../models/scanned_item.dart';
import '../services/api_client.dart';
import '../services/stock_count_item_service.dart';
import '../services/stock_count_service.dart';

class CompleteCountScreen extends StatefulWidget {
  final int stockCountId;
  final String stockCountName;

  const CompleteCountScreen({
    super.key,
    required this.stockCountId,
    required this.stockCountName,
  });

  @override
  State<CompleteCountScreen> createState() => _CompleteCountScreenState();
}

class _CompleteCountScreenState extends State<CompleteCountScreen> {
  late final StockCountItemService _itemService;
  late final StockCountService _countService;
  late Future<List<ScannedItem>> _future;

  bool _isCompleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _itemService = StockCountItemService(ApiClient());
    _countService = StockCountService(ApiClient());
    _future = _itemService.getItems(widget.stockCountId);
  }

  Future<void> _complete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sayımı tamamla'),
        content: const Text(
          'Sayım tamamlandıktan sonra yeni barkod okutulamaz ve '
          'mevcut kayıtlar değiştirilemez. Emin misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Evet, Tamamla'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isCompleting = true;
      _errorMessage = null;
    });

    try {
      await _countService.complete(widget.stockCountId);

      if (!mounted) return;
      // Detay ekranına (ve onun üstündeki listeye) "tamamlandı" bilgisini
      // taşımak için true ile geri dönüyoruz.
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Sayım tamamlanamadı, bağlantını kontrol et.');
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sayımı Tamamla')),
      body: FutureBuilder<List<ScannedItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Özet yüklenemese bile tamamlama işlemine devam edilebilsin diye
          // hata burada akışı tamamen durdurmuyor, sadece özeti atlıyor.
          final items = snapshot.data ?? [];
          final totalScans = items.length;
          final totalQuantity = items.fold<int>(0, (sum, i) => sum + i.countedQuantity);
          final distinctProducts = items.map((i) => i.product.id).toSet().length;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.stockCountName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bu sayımda',
                          style: TextStyle(color: Colors.black54, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(label: 'Toplam okutma', value: '$totalScans'),
                        _SummaryRow(label: 'Farklı ürün sayısı', value: '$distinctProducts'),
                        _SummaryRow(label: 'Toplam sayılan miktar', value: '$totalQuantity'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Text(
                  'Not: eksik/fazla/sayılmamış ürün karşılaştırması şirket '
                  'adminin web panelindeki rapor ekranında görünür.',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),

                const Spacer(),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                  ),
                  const SizedBox(height: 16),
                ],

                FilledButton.icon(
                  onPressed: _isCompleting ? null : _complete,
                  icon: _isCompleting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle),
                  label: const Text('Sayımı Tamamla'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
