import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/device_data.dart';
import 'package:logger/logger.dart';

class FirebaseService {
  late final FirebaseDatabase _db;
  final String homeId;
  final _logger = Logger();

  FirebaseService({required this.homeId, String? databaseUrl}) {
    // EXPLICIT INSTANCE: If a URL is provided, force Firebase to use it.
    // Otherwise, use the default instance from google-services.json
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
      _logger.e('Error reading from Firebase: $error');
      throw error;
    });
  }

  Future<void> updateActuator(String actuator, bool value) async {
    try {
      await _db.ref('homes/$homeId/commands/$actuator').set(value);
      _logger.i('Successfully updated actuator $actuator to $value');
    } catch (e) {
      _logger.e('Error updating actuator $actuator: $e');
      rethrow;
    }
  }

  Future<void> setOperationMode(bool isAuto) async {
    try {
      await _db.ref('homes/$homeId/system/auto').set(isAuto);
      _logger.i('Successfully set operation mode to ${isAuto ? "AUTO" : "MANUAL"}');
    } catch (e) {
      _logger.e('Error setting operation mode: $e');
      rethrow;
    }
  }
}
