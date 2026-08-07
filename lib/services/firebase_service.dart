import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/device_data.dart';

class FirebaseService {
  late final FirebaseDatabase _db;
  final String homeId;

  FirebaseService({required this.homeId, String? databaseUrl}) {
    // Initializer for the service itself (default behavior)
    if (databaseUrl != null && databaseUrl.isNotEmpty) {
      _db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: databaseUrl,
      );
    } else {
      _db = FirebaseDatabase.instance;
    }
  }

  // UPDATED: Allow passing a specific FirebaseApp instance for multi-app support
  Stream<DeviceData> getDeviceDataStream({FirebaseApp? app}) {
    final db = app != null ? FirebaseDatabase.instanceFor(app: app) : _db;
    
    return db.ref('homes/$homeId').onValue.map((event) {
      if (!event.snapshot.exists) {
        throw 'Path "homes/$homeId" not found in this database.';
      }
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return DeviceData.fromMap(homeId, data);
    }).handleError((error) {
      throw error;
    });
  }

  Future<void> updateActuator(String actuator, bool value) async {
    try {
      await _db.ref('homes/$homeId/commands/$actuator').set(value);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setOperationMode(bool isAuto) async {
    try {
      await _db.ref('homes/$homeId/system/auto').set(isAuto);
    } catch (e) {
      rethrow;
    }
  }
}
