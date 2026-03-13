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
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: ValueListenableBuilder<MobileScannerState>(
        valueListenable: _controller,
        builder: (context, state, _) {
          return Stack(
            children: [
              MobileScanner(
                controller: _controller,
                errorBuilder: (context, error) {
                  return _PermissionHint(
                    title: 'Camera unavailable',
                    message:
                        'Please allow camera permission for this site, then tap Retry.',
                    onRetry: () => _controller.start(),
                  );
                },
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
              if (state.isInitialized && !state.hasCameraPermission)
                _PermissionHint(
                  title: 'Camera permission required',
                  message:
                      'Allow camera access in browser/site settings and tap Retry.',
                  onRetry: () => _controller.start(),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PermissionHint extends StatelessWidget {
  const _PermissionHint({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Retry Camera'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
