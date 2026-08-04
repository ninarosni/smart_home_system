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
