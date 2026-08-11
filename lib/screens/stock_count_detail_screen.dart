import 'package:flutter/material.dart';

import '../models/stock_count.dart';
import '../services/api_client.dart';
import '../services/stock_count_service.dart';
import 'assigned_counts_screen.dart' show StatusChip;
import 'barcode_scan_screen.dart';
import 'complete_count_screen.dart';
import 'scanned_items_screen.dart';

class StockCountDetailScreen extends StatefulWidget {
  final int stockCountId;

  const StockCountDetailScreen({super.key, required this.stockCountId});

  @override
  State<StockCountDetailScreen> createState() => _StockCountDetailScreenState();
}

class _StockCountDetailScreenState extends State<StockCountDetailScreen> {
  late final StockCountService _service;
  late Future<StockCount> _future;

  @override
  void initState() {
    super.initState();
    _service = StockCountService(ApiClient());
    _future = _service.getDetail(widget.stockCountId);
  }

  void _refresh() {
    setState(() {
      _future = _service.getDetail(widget.stockCountId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sayım Detayı')),
      body: FutureBuilder<StockCount>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error as ApiException).message
                : 'Sayım yüklenemedi.';
            return Center(
              child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
            );
          }

          final count = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(count.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              StatusChip(status: count.status),
              const SizedBox(height: 20),

              _InfoRow(label: 'Şube / Depo', value: '${count.branchName} / ${count.warehouseName}'),

              if (count.shelfCodes.isNotEmpty)
                _InfoRow(label: 'Raflar', value: count.shelfCodes.join(', '))
              else
                _InfoRow(label: 'Raflar', value: 'Tüm depo (raf kısıtı yok)'),

              _InfoRow(label: 'Tarih Aralığı', value: '${count.startDate} — ${count.endDate}'),

              if (count.assignedUserNames.isNotEmpty)
                _InfoRow(label: 'Sayım Personeli', value: count.assignedUserNames.join(', ')),

              if (count.description != null && count.description!.isNotEmpty)
                _InfoRow(label: 'Açıklama', value: count.description!),

              const SizedBox(height: 24),

              // "Sayılan Ürünler" her durumda görülebilir (tamamlanmış bir
              // sayımı da denetlemek için); barkod okutma yalnızca devam
              // eden sayımlarda mümkün.
              if (count.status == StockCountStatus.inProgress) ...[
                FilledButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BarcodeScanScreen(stockCountId: count.id),
                      ),
                    );
                    _refresh();
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Barkod Okut'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final completed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => CompleteCountScreen(
                          stockCountId: count.id,
                          stockCountName: count.name,
                        ),
                      ),
                    );
                    if (completed == true) _refresh();
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Sayımı Tamamla'),
                ),
                const SizedBox(height: 8),
              ] else if (count.status == StockCountStatus.draft) ...[
                const _NoticeBox(
                  text: 'Bu sayım henüz başlatılmadı. Şirket adminin web '
                      'panelinden başlatmasını bekle.',
                ),
                const SizedBox(height: 8),
              ] else if (count.status == StockCountStatus.completed) ...[
                const _NoticeBox(text: 'Bu sayım tamamlandı.'),
                const SizedBox(height: 8),
              ] else ...[
                const _NoticeBox(text: 'Bu sayım iptal edildi.'),
                const SizedBox(height: 8),
              ],

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ScannedItemsScreen(stockCountId: count.id),
                    ),
                  );
                },
                icon: const Icon(Icons.list_alt),
                label: const Text('Sayılan Ürünler'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}

class _NoticeBox extends StatelessWidget {
  final String text;

  const _NoticeBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black54)),
    );
  }
}