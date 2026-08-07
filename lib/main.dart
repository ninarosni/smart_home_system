import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ENGINE A (FOUNDATION): Initialize the default app immediately.
  // This stays running in the background and is never "deleted".
  try {
    await Firebase.initializeApp();
    debugPrint('Main: Engine A (Foundation) initialized');
  } catch (e) {
    debugPrint('Main: Engine A was already initialized');
  }

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
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        // 1. Wait for local storage to load
        if (!provider.isConfigLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Decide based on Home ID (Project ID)
        if (provider.homeId == null) {
          return const SetupScreen();
        }

        // 3. Show Dashboard
        return const DashboardScreen();
      },
    );
  }
}
