// Consolidated Data Models for Smart Home System

class UserFirebaseConfig {
  const UserFirebaseConfig({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    required this.databaseUrl,
  });

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String databaseUrl;
}

class SensorData {
  final double temperature;
  final double humidity;
  final int soilMoisture;
  final int waterLevel;
  final bool rainSensor;
  final int lightSensor;
  final double distance;
  final double solarVoltage;
  final double windVoltage;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.waterLevel,
    required this.rainSensor,
    required this.lightSensor,
    required this.distance,
    required this.solarVoltage,
    required this.windVoltage,
  });

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      temperature: (map['temperature'] ?? 0.0).toDouble(),
      humidity: (map['humidity'] ?? 0.0).toDouble(),
      soilMoisture: map['soil'] ?? 0,
      waterLevel: map['water'] ?? 0,
      rainSensor: (map['rain'] ?? 0) > 0,
      lightSensor: map['light'] ?? 0,
      distance: (map['distance'] ?? 0.0).toDouble(),
      solarVoltage: (map['voltage'] ?? 0.0).toDouble(),
      windVoltage: (map['windVoltage'] ?? 0.0).toDouble(),
    );
  }
}

class ActuatorStatus {
  final bool waterPump;
  final bool roomLed;
  final bool buzzer;

  ActuatorStatus({
    required this.waterPump,
    required this.roomLed,
    required this.buzzer,
  });

  factory ActuatorStatus.fromMap(Map<dynamic, dynamic> map) {
    return ActuatorStatus(
      waterPump: map['pump'] ?? false,
      roomLed: map['led'] ?? false,
      buzzer: map['buzzer'] ?? false,
    );
  }
}

class SystemInfo {
  final bool wifi;
  final int rssi;
  final int uptime;
  final bool isOnline;

  SystemInfo({
    required this.wifi,
    required this.rssi,
    required this.uptime,
    required this.isOnline,
  });

  factory SystemInfo.fromMap(Map<dynamic, dynamic> statusMap) {
    return SystemInfo(
      wifi: statusMap['wifi'] ?? false,
      rssi: statusMap['rssi'] ?? 0,
      uptime: statusMap['uptime'] ?? 0,
      isOnline: statusMap['wifi'] ?? false,
    );
  }
}

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
