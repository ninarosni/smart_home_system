import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const SmartHomeApp(),
    ),
  );
}

class SmartHomeApp extends StatelessWidget {
  const SmartHomeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Smart Home',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      home: const FirebaseInitializer(),
    );
  }
}

class FirebaseInitializer extends StatefulWidget {
  const FirebaseInitializer({super.key});

  @override
  State<FirebaseInitializer> createState() => _FirebaseInitializerState();
}

class _FirebaseInitializerState extends State<FirebaseInitializer> {
  bool _initialized = false;
  String? _error;
  String? _lastConfigKey; // Track if config changed

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      debugPrint('FirebaseInit: Starting...');
      final provider = context.read<AppProvider>();

      // Wait for provider to load local settings from storage
      int timeout = 0;
      while (!provider.isConfigLoaded && timeout < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        timeout++;
      }
      
      // Cleanup existing app if we are re-initializing
      try {
        await Firebase.app().delete();
        debugPrint('FirebaseInit: Cleaned up previous instance');
      } catch (_) {}

      // Initialize based on available credentials
      if (provider.apiKey != null && provider.appId != null) {
        debugPrint('FirebaseInit: Using custom configuration');
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: provider.apiKey!,
            appId: provider.appId!,
            messagingSenderId: provider.messagingSenderId ?? '',
            projectId: provider.projectId ?? 'smart-home-dc84e',
            databaseURL: provider.databaseUrl,
            iosBundleId: provider.iosBundleId,
          ),
        );
      } else {
        debugPrint('FirebaseInit: Using default native configuration');
        await Firebase.initializeApp();
      }
      
      // Authentication
      final email = provider.authEmail ?? "smarthome@project.com";
      final password = provider.authPassword ?? "123456";
      
      debugPrint('FirebaseInit: Authenticating as $email...');
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (mounted) {
        setState(() {
          _initialized = true;
          _error = null;
          _lastConfigKey = "${provider.apiKey}${provider.projectId}";
        });
        provider.onFirebaseReady();
      }
    } catch (e) {
      debugPrint('FirebaseInit: FAILED: $e');
      if (mounted) {
        setState(() {
          _initialized = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    
    // Auto-detect if we need to re-initialize (e.g. user clicked Save in Settings)
    if (provider.isConfigLoaded && !provider.isLoading && _initialized) {
        final currentKey = "${provider.apiKey}${provider.projectId}";
        if (_lastConfigKey != currentKey) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _init());
        }
    }

    if (!provider.isConfigLoaded || (!_initialized && _error == null)) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to services...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Connection Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 12)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(onPressed: _init, child: const Text('RETRY')),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      ),
                      child: const Text('SETTINGS'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const RootNavigator();
  }
}

class RootNavigator extends StatelessWidget {
  const RootNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.projectId == null) {
          return const SetupScreen();
        }

        if (provider.isLoading) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    provider.loadingStatus,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.errorMessage != null && provider.deviceData == null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('Database Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(provider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(onPressed: () => provider.clearProjectId(), child: const Text('DISCONNECT')),
                        const SizedBox(width: 12),
                        OutlinedButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                            ),
                            child: const Text('SETTINGS'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const DashboardScreen();
      },
    );
  }
}
