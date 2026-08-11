import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/stock_count.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/stock_count_service.dart';
import 'stock_count_detail_screen.dart';

class AssignedCountsScreen extends StatefulWidget {
  const AssignedCountsScreen({super.key});

  @override
  State<AssignedCountsScreen> createState() => _AssignedCountsScreenState();
}

class _AssignedCountsScreenState extends State<AssignedCountsScreen> {
  late final StockCountService _service;
  late Future<List<StockCount>> _future;

  @override
  void initState() {
    super.initState();
    _service = StockCountService(ApiClient());
    _future = _service.getAssigned();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.getAssigned();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sayımlarım'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<StockCount>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              final message = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Sayımlar yüklenemedi.';
              return _ErrorView(message: message, onRetry: _refresh);
            }

            final counts = snapshot.data ?? [];

            if (counts.isEmpty) {
              // ListView içine sarıyoruz ki liste boşken de aşağı çekip
              // yenileme (RefreshIndicator) çalışsın.
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Sana atanmış bir sayım yok.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: counts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final count = counts[index];
                return _StockCountCard(count: count, onReturn: _refresh);
              },
            );
          },
        ),
      ),
    );
  }
}

class _StockCountCard extends StatelessWidget {
  final StockCount count;
  final VoidCallback onReturn;

  const _StockCountCard({required this.count, required this.onReturn});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(count.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${count.branchName} / ${count.warehouseName}'),
        trailing: StatusChip(status: count.status),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => StockCountDetailScreen(stockCountId: count.id)),
          );
          // Detay ekranından dönünce (örn. sayım başlatıldıysa) liste tazelensin.
          onReturn();
        },
      ),
    );
  }
}

/// Sayım detay ekranıyla da paylaşılan küçük bir durum rozeti.
class StatusChip extends StatelessWidget {
  final StockCountStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    const colors = {
      StockCountStatus.draft: Colors.grey,
      StockCountStatus.inProgress: Colors.orange,
      StockCountStatus.completed: Colors.green,
      StockCountStatus.cancelled: Colors.red,
    };

    final color = colors[status]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Tekrar Dene')),
          ],
        ),
      ),
    );
  }
}
