import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  // Prevents multiple pop calls when the camera reads the same QR repeatedly.
  bool _isDetected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_isDetected) {
            return;
          }

          // Use the first detected barcode payload as the QR result.
          final first = capture.barcodes.firstOrNull;
          final value = first?.rawValue;
          if (value == null || value.isEmpty) {
            return;
          }

          _isDetected = true;
          Navigator.of(context).pop(value);
        },
      ),
    );
  }
}
