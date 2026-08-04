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
