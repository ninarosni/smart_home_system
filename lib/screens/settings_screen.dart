import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _projectIdController;
  late TextEditingController _apiKeyController;
  late TextEditingController _dbUrlController;
  late TextEditingController _appIdController;
  late TextEditingController _senderIdController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _projectIdController = TextEditingController(text: provider.firebaseProjectId);
    _apiKeyController = TextEditingController(text: provider.apiKey);
    _dbUrlController = TextEditingController(text: provider.databaseUrl);
    _appIdController = TextEditingController(text: provider.appId);
    _senderIdController = TextEditingController(text: provider.messagingSenderId);
    _emailController = TextEditingController(text: provider.authEmail);
    _passwordController = TextEditingController(text: provider.authPassword);
  }

  @override
  void dispose() {
    _projectIdController.dispose();
    _apiKeyController.dispose();
    _dbUrlController.dispose();
    _appIdController.dispose();
    _senderIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: () {
                provider.applyAllSettings(
                  projectId: _projectIdController.text.trim(),
                  databaseUrl: _dbUrlController.text.trim(),
                  apiKey: _apiKeyController.text.trim(),
                  appId: _appIdController.text.trim(),
                  messagingSenderId: _senderIdController.text.trim(),
                  email: _emailController.text.trim(),
                  password: _passwordController.text.trim(),
                );
                setState(() => _isEditing = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Re-initializing Connection...')),
                );
                Navigator.pop(context); // RETURN IMMEDIATELY to Dashboard
              },
              child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_note),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionHeader('Current Connection'),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.home_outlined)),
            title: const Text('Home ID'),
            subtitle: Text(provider.homeId ?? 'None'),
            trailing: provider.homeId != null 
              ? const Icon(Icons.verified, color: Colors.green)
              : null,
          ),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.cloud_sync)),
            title: const Text('Database (Project ID)'),
            subtitle: Text(provider.firebaseProjectId ?? 'smart-home-dc84e (Default)'),
          ),
          const Divider(),
          _buildSectionHeader('Firebase Credentials'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                _buildTextField(_projectIdController, 'Firebase Project ID', Icons.fingerprint),
                const SizedBox(height: 12),
                _buildTextField(_dbUrlController, 'Database URL', Icons.link),
                const SizedBox(height: 12),
                _buildTextField(_apiKeyController, 'API Key', Icons.key),
                const SizedBox(height: 12),
                _buildTextField(_appIdController, 'App ID (Optional)', Icons.apps),
                const SizedBox(height: 12),
                _buildTextField(_senderIdController, 'Sender ID (Optional)', Icons.message),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader('Authentication'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                _buildTextField(_emailController, 'Auth Email', Icons.email),
                const SizedBox(height: 12),
                _buildTextField(_passwordController, 'Auth Password', Icons.lock, obscure: true),
              ],
            ),
          ),
          const Divider(),
          _buildSectionHeader('Management'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Disconnect Home'),
            subtitle: const Text('Return to Home ID setup screen'),
            onTap: () {
              _showConfirmDialog(context, provider);
            },
          ),
          const Divider(),
          _buildSectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Smart Home App'),
            subtitle: Text('Version 2.1.0 (Identity Separation)'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.deepPurple,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      enabled: _isEditing,
      obscureText: obscure && !_isEditing,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: !_isEditing,
        fillColor: _isEditing ? null : Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      style: const TextStyle(fontSize: 14),
    );
  }

  void _showConfirmDialog(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Home?'),
        content: const Text('This will clear your Home ID and return you to the setup screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.clearAll();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close settings screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DISCONNECT'),
          ),
        ],
      ),
    );
  }
}
