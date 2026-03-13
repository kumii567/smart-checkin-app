import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:smart_class_checkin/screens/qr_scanner_screen.dart';
import 'package:smart_class_checkin/services/cloud_sync_service.dart';
import 'package:smart_class_checkin/services/db_service.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  static const List<_MoodOption> _moodOptions = [
    _MoodOption(1, '😡', 'Very negative', Color(0xFFEF4444)),
    _MoodOption(2, '🙁', 'Negative', Color(0xFFF97316)),
    _MoodOption(3, '😐', 'Neutral', Color(0xFFF59E0B)),
    _MoodOption(4, '🙂', 'Positive', Color(0xFF22C55E)),
    _MoodOption(5, '😄', 'Very positive', Color(0xFF10B981)),
  ];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _previousTopicController =
      TextEditingController();
  final TextEditingController _expectedTopicController =
      TextEditingController();

  Position? _position;
  String? _qrData;
  int _mood = 3;
  bool _isSaving = false;

  @override
  void dispose() {
    _previousTopicController.dispose();
    _expectedTopicController.dispose();
    super.dispose();
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('QR scanned successfully.')));
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

    // Automatically record submit time as check-in timestamp.
    final now = DateTime.now();
    final record = <String, Object?>{
      'flow_type': 'check_in',
      'timestamp': now.toIso8601String(),
      'latitude': _position!.latitude,
      'longitude': _position!.longitude,
      'qr_data': _qrData,
      'previous_topic': _previousTopicController.text.trim(),
      'expected_topic': _expectedTopicController.text.trim(),
      'mood_before': _mood,
      'learned_today': null,
      'feedback': null,
      'instructor_rating': null,
      'created_at': now.toIso8601String(),
    };

    try {
      // Save check-in data locally in SQLite for MVP persistence.
      await DbService.instance.insertRecord(record);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save check-in data.')),
      );
      return;
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          syncedToCloud
              ? 'Check-in saved locally and synced to Firebase.'
              : 'Check-in saved locally. Firebase sync is pending.',
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

  _MoodOption get _selectedMood =>
      _moodOptions.firstWhere((option) => option.value == _mood);

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
    return Scaffold(
      appBar: AppBar(title: const Text('Check-in')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Step 1 of 3',
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
                  value: 1 / 3,
                  minHeight: 8,
                  backgroundColor: Color(0xFFCCFBF1),
                  valueColor: AlwaysStoppedAnimation(Color(0xFF0D9488)),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Ready to prove your attendance and learning intent for ${DateFormat('EEEE').format(DateTime.now())}.',
                style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                title: 'Verify your presence',
                subtitle:
                    'Capture GPS and scan the class QR before continuing.',
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
                            onPressed: _captureLocation,
                            icon: const Icon(Icons.my_location_rounded),
                            label: const Text('Capture GPS'),
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
                            onPressed: _scanQr,
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                            label: const Text('Scan QR Code'),
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
                          const SizedBox(height: 12),
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
                                      ? 'No QR scanned yet'
                                      : 'QR verified: $_qrData',
                                ),
                              ),
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
                title: 'Set your learning mindset',
                subtitle:
                    'Use floating-label fields and tap the emoji that matches your mood.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _previousTopicController,
                      decoration: InputDecoration(
                        labelText: 'Topic covered in previous class',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter previous class topic';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _expectedTopicController,
                      decoration: InputDecoration(
                        labelText: 'Topic expected to learn today',
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter expected topic';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Mood before class',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap an emoji to choose your energy level.',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _moodOptions.map((option) {
                        final isSelected = option.value == _mood;
                        return AnimatedScale(
                          scale: isSelected ? 1.06 : 1,
                          duration: const Duration(milliseconds: 180),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(22),
                            onTap: () {
                              setState(() {
                                _mood = option.value;
                              });
                            },
                            child: Ink(
                              width: 110,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? option.color.withValues(alpha: 0.15)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isSelected
                                      ? option.color
                                      : const Color(0xFFE5E7EB),
                                  width: 1.4,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: option.color.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 14,
                                          offset: const Offset(0, 8),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    option.emoji,
                                    style: const TextStyle(fontSize: 30),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    option.label,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? option.color
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selectedMood.color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        'Selected mood: ${_selectedMood.emoji} ${_selectedMood.label}',
                        style: TextStyle(
                          color: _selectedMood.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                  _isSaving ? 'Saving your check-in...' : 'Confirm Check-in',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Time stamp: ${DateFormat('h:mm a • d MMM yyyy').format(DateTime.now())}',
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

class _MoodOption {
  const _MoodOption(this.value, this.emoji, this.label, this.color);

  final int value;
  final String emoji;
  final String label;
  final Color color;
}
