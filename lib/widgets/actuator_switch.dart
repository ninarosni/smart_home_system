import 'package:flutter/material.dart';

class ActuatorSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final IconData icon;
  final Function(bool) onChanged;
  final bool enabled;

  const ActuatorSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: value ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.grey[200]!,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: value ? Theme.of(context).colorScheme.primary : Colors.grey[300],
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          value ? 'ON' : 'OFF',
          style: TextStyle(
            color: value ? Theme.of(context).colorScheme.primary : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
