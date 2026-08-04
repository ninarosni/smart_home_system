import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/sensor_card.dart';
import '../widgets/actuator_switch.dart';
import '../widgets/status_badge.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Smart Home',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Consumer<AppProvider>(
              builder: (context, provider, child) => Text(
                provider.projectId ?? 'Not Connected',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: StatusBadge(isOnline: provider.isDeviceOnline),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.deviceData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(provider.loadingStatus, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          if (provider.errorMessage != null && provider.deviceData == null) {
            return _buildErrorState(provider);
          }

          final data = provider.deviceData;
          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Initializing connection...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSystemStatus(context, provider),
                const SizedBox(height: 24),
                _buildModeToggle(context, provider),
                const SizedBox(height: 32),
                _buildSectionTitle(context, 'Sensors', Icons.sensors),
                const SizedBox(height: 16),
                _buildSensorGrid(data),
                const SizedBox(height: 32),
                _buildSectionTitle(context, 'Controls', Icons.settings_remote),
                const SizedBox(height: 16),
                _buildActuatorList(provider),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSystemStatus(BuildContext context, AppProvider provider) {
    final data = provider.deviceData!;
    final lastSeen = provider.secondsSinceLastUpdate;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Home Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    'Database: ${data.id}',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(isOnline: provider.isDeviceOnline),
                  if (lastSeen >= 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      lastSeen == 0 ? 'Just now' : 'Last seen: ${lastSeen}s ago',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
              CircleAvatar(
                radius: 25,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.home, color: Colors.white),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem(context, Icons.wifi, 'RSSI', '${data.system.rssi} dBm'),
              _buildInfoItem(context, Icons.timer_outlined, 'Uptime', _formatUptime(data.system.uptime)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildModeToggle(BuildContext context, AppProvider provider) {
    final isAuto = provider.deviceData?.isAutoMode ?? false;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isAuto ? Colors.blue.withOpacity(0.5) : Colors.grey[300]!),
        color: isAuto ? Colors.blue.withOpacity(0.05) : Colors.transparent,
      ),
      child: SwitchListTile(
        title: const Text('AUTO MODE', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(isAuto ? 'System controlling actuators' : 'Manual control enabled'),
        secondary: Icon(isAuto ? Icons.auto_awesome : Icons.touch_app, 
          color: isAuto ? Colors.blue : Colors.grey),
        value: isAuto,
        onChanged: (val) => provider.toggleMode(val),
      ),
    );
  }

  Widget _buildSensorGrid(dynamic data) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.1,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        SensorCard(
          label: 'Temperature',
          value: data.sensors.temperature.toStringAsFixed(1),
          unit: '°C',
          icon: Icons.thermostat,
          color: Colors.orange,
        ),
        SensorCard(
          label: 'Humidity',
          value: data.sensors.humidity.toStringAsFixed(0),
          unit: '%',
          icon: Icons.water_drop,
          color: Colors.blue,
        ),
        SensorCard(
          label: 'Soil Moisture',
          value: data.sensors.soilMoisture.toString(),
          unit: '%',
          icon: Icons.grass,
          color: Colors.green,
        ),
        SensorCard(
          label: 'Distance',
          value: data.sensors.distance.toStringAsFixed(1),
          unit: 'cm',
          icon: Icons.settings_remote,
          color: Colors.deepPurple,
        ),
        SensorCard(
          label: 'Rain',
          value: data.sensors.rainSensor ? 'YES' : 'NO',
          unit: '',
          icon: Icons.cloudy_snowing,
          color: Colors.indigo,
        ),
        SensorCard(
          label: 'Light',
          value: data.sensors.lightSensor.toString(),
          unit: 'lux',
          icon: Icons.light_mode,
          color: Colors.amber,
        ),
        SensorCard(
          label: 'Water Level',
          value: data.sensors.waterLevel.toString(),
          unit: 'units',
          icon: Icons.waves,
          color: Colors.cyan,
        ),
        SensorCard(
          label: 'Solar',
          value: data.sensors.solarVoltage.toStringAsFixed(2),
          unit: 'V',
          icon: Icons.solar_power,
          color: Colors.yellow[800]!,
        ),
        SensorCard(
          label: 'Wind',
          value: data.sensors.windVoltage.toStringAsFixed(2),
          unit: 'V',
          icon: Icons.air,
          color: Colors.blueGrey,
        ),
      ],
    );
  }

  Widget _buildActuatorList(AppProvider provider) {
    final actuators = provider.deviceData!.actuators;
    final isAuto = provider.deviceData!.isAutoMode;

    return Column(
      children: [
        ActuatorSwitch(
          label: 'Water Pump',
          value: actuators.waterPump,
          icon: Icons.water_drop_outlined,
          onChanged: (val) => provider.toggleActuator('pump', val),
          enabled: !isAuto,
        ),
        ActuatorSwitch(
          label: 'Room LED',
          value: actuators.roomLed,
          icon: Icons.lightbulb_outline,
          onChanged: (val) => provider.toggleActuator('led', val),
          enabled: !isAuto,
        ),
        ActuatorSwitch(
          label: 'Buzzer',
          value: actuators.buzzer,
          icon: Icons.notifications_none,
          onChanged: (val) => provider.toggleActuator('buzzer', val),
          enabled: !isAuto,
        ),
      ],
    );
  }

  Widget _buildErrorState(AppProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Connection Failed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(provider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: () => provider.clearProjectId(), child: const Text('RESET SETUP')),
          ],
        ),
      ),
    );
  }

  String _formatUptime(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
