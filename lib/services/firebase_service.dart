import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/device_data.dart';

class FirebaseService {
  late final FirebaseDatabase _db;
  final String homeId;

  FirebaseService({required this.homeId, String? databaseUrl}) {
    if (databaseUrl != null && databaseUrl.isNotEmpty) {
      _db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: databaseUrl,
      );
    } else {
      _db = FirebaseDatabase.instance;
    }
  }

  Stream<DeviceData> getDeviceDataStream() {
    return _db.ref('homes/$homeId').onValue.map((event) {
      if (!event.snapshot.exists) {
        throw 'Home "$homeId" not found in database.';
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
