import 'package:flutter/material.dart';

import '../models/scanned_item.dart';
import '../services/api_client.dart';
import '../services/stock_count_item_service.dart';

class ScannedItemsScreen extends StatefulWidget {
  final int stockCountId;

  const ScannedItemsScreen({super.key, required this.stockCountId});

  @override
  State<ScannedItemsScreen> createState() => _ScannedItemsScreenState();
}

class _ScannedItemsScreenState extends State<ScannedItemsScreen> {
  late final StockCountItemService _service;
  late Future<List<ScannedItem>> _future;

  @override
  void initState() {
    super.initState();
    _service = StockCountItemService(ApiClient());
    _future = _service.getItems(widget.stockCountId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.getItems(widget.stockCountId);
    });
    await _future;
  }

  Future<void> _editQuantity(ScannedItem item) async {
    final controller = TextEditingController(text: item.countedQuantity.toString());

    final newQuantity = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.product.name),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Sayılan Miktar'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(int.tryParse(controller.text.trim())),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (newQuantity == null || newQuantity < 0) return;

    await _submitUpdate(item, newQuantity);
  }

  Future<void> _submitUpdate(ScannedItem item, int quantity, {bool confirm = false}) async {
    try {
      await _service.updateQuantity(widget.stockCountId, item.id, quantity: quantity, confirm: confirm);
      await _refresh();
    } on ApiException catch (e) {
      if (e.statusCode == 409 && mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Miktarı onaylıyor musun?'),
            content: Text(e.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Evet, Devam Et'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await _submitUpdate(item, quantity, confirm: true);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Güncellenemedi, bağlantını kontrol et.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sayılan Ürünler')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ScannedItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              final message = snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : 'Liste yüklenemedi.';
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(message, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: _refresh, child: const Text('Tekrar Dene')),
                    ],
                  ),
                ),
              );
            }

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Henüz hiç ürün okutulmadı.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                // API girildiği sırayla (id artan) döndürüyor — en son
                // okutulan en üstte görünsün diye burada tersten gösteriyoruz.
                final item = items[items.length - 1 - index];

                return ListTile(
                  title: Text(item.product.name),
                  subtitle: Text(
                    'Barkod: ${item.product.barcode}'
                    '${item.countedByName != null ? ' • ${item.countedByName}' : ''}',
                  ),
                  trailing: Text(
                    '${item.countedQuantity}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _editQuantity(item),
                );
              },
            );
          },
        ),
      ),
    );
  }
}