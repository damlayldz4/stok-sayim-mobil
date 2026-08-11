import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../services/api_client.dart';
import '../services/stock_count_item_service.dart';

class QuantityEntryScreen extends StatefulWidget {
  final int stockCountId;
  final ProductInfo product;

  const QuantityEntryScreen({
    super.key,
    required this.stockCountId,
    required this.product,
  });

  @override
  State<QuantityEntryScreen> createState() => _QuantityEntryScreenState();
}

class _QuantityEntryScreenState extends State<QuantityEntryScreen> {
  late final StockCountItemService _service;
  late final TextEditingController _quantityController;
  final _focusNode = FocusNode();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = StockCountItemService(ApiClient());

    // Doküman md.12 + danışman notu: varsayılan miktar 1 gelir VE
    // seçili gelir — kullanıcı silme tuşuna basmadan direkt yeni bir
    // sayı yazabilsin.
    _quantityController = TextEditingController(text: '1');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _quantityController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _quantityController.text.length,
      );
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit({bool confirm = false}) async {
    final quantity = int.tryParse(_quantityController.text.trim());

    if (quantity == null || quantity < 1) {
      setState(() => _errorMessage = 'Miktar boş veya negatif olamaz.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _service.scan(
        widget.stockCountId,
        barcode: widget.product.barcode,
        quantity: quantity,
        confirm: confirm,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        final confirmed = await _showThresholdDialog(e.message);
        if (confirmed == true) {
          if (mounted) setState(() => _isSubmitting = false);
          await _submit(confirm: true);
          return;
        }
      } else {
        setState(() => _errorMessage = e.message);
      }
    } catch (_) {
      setState(() => _errorMessage = 'Kayıt gönderilemedi, bağlantını kontrol et.');
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  /// Şirket adminin belirlediği eşik aşıldığında (409) gösterilen onay penceresi.
  Future<bool?> _showThresholdDialog(String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Miktarı onaylıyor musun?'),
        content: Text(message),
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
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      appBar: AppBar(title: const Text('Miktar Gir')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Barkod: ${product.barcode}', style: const TextStyle(color: Colors.black54)),
                    if (product.code != null && product.code!.isNotEmpty)
                      Text('Kod: ${product.code}', style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text(
                      'Beklenen Miktar: ${product.expectedQuantity}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

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

            TextField(
              controller: _quantityController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Sayılan Miktar',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: _isSubmitting ? null : () => _submit(),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Kaydı Gönder'),
            ),
          ],
        ),
      ),
    );
  }
}
