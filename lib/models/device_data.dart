import 'sensor_data.dart';
import 'actuator_status.dart';
import 'system_info.dart';

class DeviceData {
  final String id;
  final SensorData sensors;
  final ActuatorStatus actuators;
  final SystemInfo system;
  final bool isAutoMode;

  DeviceData({
    required this.id,
    required this.sensors,
    required this.actuators,
    required this.system,
    required this.isAutoMode,
  });

  factory DeviceData.fromMap(String id, Map<dynamic, dynamic> map) {
    final sensorsMap = map['sensors'] as Map<dynamic, dynamic>? ?? {};
    final actuatorsMap = map['actuators'] as Map<dynamic, dynamic>? ?? {};
    final systemMap = map['system'] as Map<dynamic, dynamic>? ?? {};

    return DeviceData(
      id: id,
      sensors: SensorData.fromMap(sensorsMap),
      actuators: ActuatorStatus.fromMap(actuatorsMap),
      system: SystemInfo.fromMap(systemMap),
      isAutoMode: systemMap['auto'] ?? false,
    );
  }
}
