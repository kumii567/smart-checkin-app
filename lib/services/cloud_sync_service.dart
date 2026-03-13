import 'package:cloud_firestore/cloud_firestore.dart';

class CloudSyncService {
  CloudSyncService._();

  static final CloudSyncService instance = CloudSyncService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Saves one attendance/reflection record to Cloud Firestore.
  Future<void> saveRecord(Map<String, Object?> data) async {
    await _firestore.collection('class_records').add({
      ...data,
      'synced_at': DateTime.now().toIso8601String(),
    });
  }
}
