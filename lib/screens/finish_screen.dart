import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:smart_class_checkin/screens/qr_scanner_screen.dart';
import 'package:smart_class_checkin/services/cloud_sync_service.dart';
import 'package:smart_class_checkin/services/db_service.dart';

class FinishClassScreen extends StatefulWidget {
  const FinishClassScreen({super.key});

  @override
  State<FinishClassScreen> createState() => _FinishClassScreenState();
}

class _FinishClassScreenState extends State<FinishClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _learnedTodayController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();

  Position? _position;
  String? _qrData;
  bool _isSaving = false;
  int _rating = 5;
  DateTime? _latestCheckInTime;
  bool _loadingSummary = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _learnedTodayController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    final latest = await DbService.instance.fetchLatestRecord('check_in');
    final timestamp = latest?['timestamp'] as String?;

    if (!mounted) {
      return;
    }

    setState(() {
      _latestCheckInTime = timestamp == null
          ? null
          : DateTime.tryParse(timestamp);
      _loadingSummary = false;
    });
  }

  // Captures the current GPS position with permission checks.
  Future<void> _captureLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location service is disabled. Please enable GPS.'),
        ),
      );
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final opened = await Geolocator.openAppSettings();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            opened
                ? 'Location permission denied. Enable it in app/site settings.'
                : 'Location permission denied. Please allow location for this site.',
          ),
        ),
      );
      return;
    }

    final current = await Geolocator.getCurrentPosition();
    if (!mounted) return;

    setState(() {
      _position = current;
    });

    HapticFeedback.lightImpact();
  }

  Future<void> _scanQr() async {
    final value = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerScreen()));

    if (!mounted) {
      return;
    }

    if (value == null || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'QR scan was cancelled or camera permission is blocked.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _qrData = value;
    });

    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exit QR scanned successfully.')),
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    if (_position == null || _qrData == null || _qrData!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture GPS and scan QR first.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Automatically record submit time as finish-class timestamp.
    final now = DateTime.now();
    final record = <String, Object?>{
      'flow_type': 'finish_class',
      'timestamp': now.toIso8601String(),
      'latitude': _position!.latitude,
      'longitude': _position!.longitude,
      'qr_data': _qrData,
      'previous_topic': null,
      'expected_topic': null,
      'mood_before': null,
      'learned_today': _learnedTodayController.text.trim(),
      'feedback': _feedbackController.text.trim(),
      'instructor_rating': _rating,
      'created_at': now.toIso8601String(),
    };

    var savedLocally = true;
    try {
      await DbService.instance.insertRecord(record);
    } catch (_) {
      savedLocally = false;
    }

    var syncedToCloud = true;
    try {
      await CloudSyncService.instance.saveRecord(record);
    } catch (_) {
      syncedToCloud = false;
    }

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (!savedLocally && !syncedToCloud) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save finish-class data.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedLocally && syncedToCloud
              ? 'Finish class saved locally and synced to Firebase.'
              : savedLocally
              ? 'Finish class saved locally. Firebase sync is pending.'
              : 'Finish class saved to Firebase (cloud only).',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  String _locationText() {
    if (_position == null) {
      return 'No GPS captured yet';
    }
    return 'Lat: ${_position!.latitude.toStringAsFixed(6)}, Lng: ${_position!.longitude.toStringAsFixed(6)}';
  }

  String _sessionDurationText() {
    if (_latestCheckInTime == null) {
      return 'No earlier check-in found yet';
    }

    final diff = DateTime.now().difference(_latestCheckInTime!);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours h $minutes min in class';
    }
    return '${diff.inMinutes} min in class';
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Finish Class')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Step 3 of 3',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D9488),
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(
                  value: 1,
                  minHeight: 8,
                  backgroundColor: Color(0xFFCCFBF1),
                  valueColor: AlwaysStoppedAnimation(Color(0xFF0D9488)),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _loadingSummary
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Session summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _sessionDurationText(),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _latestCheckInTime == null
                                  ? 'Complete one check-in first, then finish the session.'
                                  : 'Started at ${DateFormat('h:mm a').format(_latestCheckInTime!)} • ready for your exit reflection.',
                              style: const TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Verify class completion',
                subtitle: 'Scan the QR again and capture your final location.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 220,
                          child: FilledButton.icon(
                            onPressed: _scanQr,
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            label: const Text('Scan Exit QR'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: FilledButton.icon(
                            onPressed: _captureLocation,
                            icon: const Icon(Icons.near_me_rounded),
                            label: const Text('Capture Location'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _qrData == null
                                    ? Icons.crop_free_rounded
                                    : Icons.verified_rounded,
                                color: _qrData == null
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF0D9488),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _qrData == null
                                      ? 'No exit QR scanned yet'
                                      : 'Exit QR verified: $_qrData',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                _position == null
                                    ? Icons.location_disabled_outlined
                                    : Icons.location_on_rounded,
                                color: _position == null
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF0D9488),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_locationText())),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionCard(
                title: 'Reflection and instructor feedback',
                subtitle:
                    'Share what mattered most in today’s class before you submit.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _learnedTodayController,
                      decoration: InputDecoration(
                        labelText:
                            'What was the most interesting thing you learned?',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      minLines: 4,
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter what you learned today';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Rate today’s class',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return IconButton(
                          onPressed: () {
                            setState(() {
                              _rating = star;
                            });
                          },
                          icon: Icon(
                            star <= _rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 34,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _feedbackController,
                      decoration: InputDecoration(
                        labelText: 'Feedback about the class or instructor',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      minLines: 3,
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your feedback';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(
                  _isSaving ? 'Submitting reflection...' : 'Finish & Submit',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Completion time: ${DateFormat('h:mm a • d MMM yyyy').format(DateTime.now())}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
