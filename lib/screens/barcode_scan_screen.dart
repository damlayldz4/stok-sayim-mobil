import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/api_client.dart';
import '../services/product_service.dart';
import 'quantity_entry_screen.dart';

class BarcodeScanScreen extends StatefulWidget {
  final int stockCountId;

  const BarcodeScanScreen({super.key, required this.stockCountId});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  late final ProductService _productService;

  bool _isProcessing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _productService = ProductService(ApiClient());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = null;
    });

    // Aynı barkodu arka arkaya tekrar tekrar okumasın diye kamerayı durduruyoruz;
    // miktar ekranından dönünce (veya hata sonrası) tekrar başlatıyoruz.
    await _controller.stop();

    try {
      final product = await _productService.findByBarcode(barcode);
      if (!mounted) return;

      final added = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => QuantityEntryScreen(
            stockCountId: widget.stockCountId,
            product: product,
          ),
        ),
      );

      if (!mounted) return;
      setState(() => _statusMessage = added == true ? '${product.name} eklendi.' : null);
    } on ProductNotFoundException {
      setState(() => _statusMessage = 'Bu barkoda ait ürün bulunamadı.');
    } catch (_) {
      setState(() => _statusMessage = 'Ürün sorgulanamadı, bağlantını kontrol et.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
        await _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barkod Okut')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Ortada basit bir hedefleme çerçevesi.
          Center(
            child: Container(
              width: 240,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          if (_isProcessing)
            const Positioned(
              top: 16,
              right: 16,
              child: CircularProgressIndicator(color: Colors.white),
            ),

          if (_statusMessage != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
