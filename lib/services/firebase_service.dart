import 'package:firebase_database/firebase_database.dart';
import '../models/device_data.dart';
import 'package:logger/logger.dart';

class FirebaseService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final String homeId; // This is the user entered name like HOME-004
  final _logger = Logger();

  FirebaseService({required this.homeId});

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
