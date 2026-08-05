import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'config/firebase_secrets.dart';

void main() async {
  // Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start the app immediately
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      debugPrint('FirebaseInit: Starting...');
      final provider = context.read<AppProvider>();
      
      // 1. Initialize with User-Provided Settings (from the app UI)
      if (provider.apiKey != null && provider.appId != null) {
        debugPrint('FirebaseInit: Using custom user config');
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: provider.apiKey!,
            appId: provider.appId!,
            messagingSenderId: provider.messagingSenderId ?? '',
            projectId: provider.projectId ?? '',
            databaseURL: provider.databaseUrl,
            iosBundleId: provider.iosBundleId,
          ),
        );
      } 
      // 2. Initialize with CI-Injected Secrets (Bulletproof for Cloud Builds)
      else if (FirebaseSecrets.apiKey != null) {
        debugPrint('FirebaseInit: Using CI Secrets');
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: FirebaseSecrets.apiKey!,
            appId: FirebaseSecrets.appId!,
            messagingSenderId: FirebaseSecrets.messagingSenderId ?? '',
            projectId: FirebaseSecrets.projectId!,
            databaseURL: FirebaseSecrets.databaseURL,
            iosBundleId: FirebaseSecrets.iosBundleId,
          ),
        );
      }
      // 3. Fallback to Native config files
      else {
        debugPrint('FirebaseInit: Standard native initialization');
        await Firebase.initializeApp();
      }
      
      debugPrint('FirebaseInit: Core Handshake Success');
      
      if (mounted) {
        setState(() {
          _initialized = true;
          _error = null;
        });
        context.read<AppProvider>().onFirebaseReady();
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
    
    if (!provider.isConfigLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
                const Text('Firebase Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 12)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text('Diagnostic Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(FirebaseSecrets.diagnosticInfo, 
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      const SizedBox(height: 4),
                      const Text('SDK Status: LOADED', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
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
                      child: const Text('CONFIGURE MANUALLY'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Connecting to services...', style: TextStyle(color: Colors.grey)),
            ],
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
        // Decide which screen to show
        if (provider.projectId == null) {
          if (provider.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return const SetupScreen();
        }

        // If project ID exists but we are still loading data
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

        // If there was an error during initial fetch
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
                    const Text('Connection Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(provider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 32),
                    ElevatedButton(onPressed: () => provider.clearProjectId(), child: const Text('BACK TO SETUP')),
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
