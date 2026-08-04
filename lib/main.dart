import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';

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
      
      // Attempt to initialize Firebase with custom options if available
      if (provider.apiKey != null && provider.appId != null) {
        debugPrint('FirebaseInit: Using custom config');
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: provider.apiKey!,
            appId: provider.appId!,
            messagingSenderId: provider.messagingSenderId ?? '',
            projectId: provider.projectId ?? '',
            databaseURL: provider.databaseUrl,
          ),
        );
      } else {
        debugPrint('FirebaseInit: Using default config');
        try {
          await Firebase.initializeApp();
        } catch (e) {
          debugPrint('FirebaseInit: Default initialization failed (likely missing google-services.json)');
          // We don't throw here, because we want to allow the user to go to Settings
          // to provide their own credentials.
        }
      }
      
      debugPrint('FirebaseInit: App Initialized');
      
      // Dynamic Authentication
      final email = provider.authEmail ?? "smarthome@project.com";
      final password = provider.authPassword ?? "123456";
      
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        debugPrint('FirebaseInit: Signed in as $email');
      } catch (e) {
        debugPrint('FirebaseInit: Auth failed: $e');
        // Again, don't block the app if auth fails; allow user to fix in settings
      }
      
      if (mounted) {
        setState(() => _initialized = true);
        context.read<AppProvider>().onFirebaseReady();
      }
    } catch (e) {
      debugPrint('FirebaseInit: FAILED: $e');
      if (mounted) {
        setState(() => _error = e.toString());
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
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(onPressed: _init, child: const Text('RETRY')),
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
