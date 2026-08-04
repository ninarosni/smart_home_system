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
