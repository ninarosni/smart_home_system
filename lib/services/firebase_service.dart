import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/device_data.dart';
import '../models/user_firebase_config.dart';

class FirebaseService {
  FirebaseService._({
    required this.homeId,
    required FirebaseDatabase database,
    required FirebaseApp app,
  })  : _db = database,
        appInstance = app;

  static const _userAppName = 'user-owned-firebase';

  final String homeId;
  final FirebaseDatabase _db;
  final FirebaseApp appInstance; // Direct access for Auth and Diagnostics

  static Future<FirebaseService> connect({
    required String homeId,
    required UserFirebaseConfig? config,
  }) async {
    FirebaseApp app;
    String? databaseUrl;

    if (config != null) {
      // 1. Remove the previous user connection safely
      for (final existingApp in Firebase.apps.where((a) => a.name == _userAppName)) {
        await existingApp.delete();
      }

      // 2. Initialize the user-owned app with provided config
      app = await Firebase.initializeApp(
        name: _userAppName,
        options: FirebaseOptions(
          apiKey: config.apiKey,
          appId: config.appId,
          messagingSenderId: config.messagingSenderId,
          projectId: config.projectId,
          databaseURL: config.databaseUrl,
        ),
      );
      databaseUrl = config.databaseUrl;
    } else {
      // 3. Fallback to default native app
      app = Firebase.app();
      databaseUrl = app.options.databaseURL;
    }

    final database = FirebaseDatabase.instanceFor(
      app: app,
      databaseURL: databaseUrl,
    );

    return FirebaseService._(
      homeId: homeId,
      database: database,
      app: app,
    );
  }

  Stream<DeviceData> getDeviceDataStream() {
    return _db.ref('homes/$homeId').onValue.map((event) {
      if (!event.snapshot.exists) {
        throw StateError('Home "$homeId" was not found.');
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      return DeviceData.fromMap(homeId, data);
    });
  }

  Future<void> updateActuator(String actuator, bool value) =>
      _db.ref('homes/$homeId/commands/$actuator').set(value);

  Future<void> setOperationMode(bool isAuto) =>
      _db.ref('homes/$homeId/system/auto').set(isAuto);

  Future<void> disconnect() async {
    if (appInstance.name == _userAppName) {
      await appInstance.delete();
    }
  }
}
