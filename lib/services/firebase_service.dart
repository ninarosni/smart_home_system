import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/device_data.dart';
import 'package:logger/logger.dart';

class FirebaseService {
  late final FirebaseDatabase _db;
  final String projectId;
  final String databaseUrl;
  final FirebaseApp app;
  final _logger = Logger();

  FirebaseService({
    required this.projectId,
    required this.databaseUrl,
    required this.app,
  }) {
    _db = FirebaseDatabase.instanceFor(
      app: app,
      databaseURL: databaseUrl,
    );
  }

  Stream<DeviceData> getDeviceDataStream() {
    return _db.ref('homes/$projectId').onValue.map((event) {
      if (!event.snapshot.exists) {
        throw 'Project ID "$projectId" not found in database.';
      }
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return DeviceData.fromMap(projectId, data);
    }).handleError((error) {
      _logger.e('Error reading from Firebase: $error');
      throw error;
    });
  }

  Future<void> updateActuator(String actuator, bool value) async {
    try {
      await _db.ref('homes/$projectId/commands/$actuator').set(value);
    } catch (e) {
      _logger.e('Error updating actuator $actuator: $e');
    }
  }

  Future<void> setOperationMode(bool isAuto) async {
    try {
      await _db.ref('homes/$projectId/system/auto').set(isAuto);
    } catch (e) {
      _logger.e('Error setting operation mode: $e');
    }
  }
}
