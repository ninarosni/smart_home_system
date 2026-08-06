import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/device_data.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../config/firebase_secrets.dart';
import 'dart:convert';

class AppProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  FirebaseService? _firebaseService;
  
  String? _projectId;
  String? _apiKey;
  String? _databaseUrl;
  String? _appId;
  String? _messagingSenderId;
  String? _iosBundleId;
  String? _authEmail;
  String? _authPassword;

  DeviceData? _deviceData;
  bool _isLoading = true;
  bool _isConfigLoaded = false;
  String? _errorMessage;
  String _loadingStatus = 'Initializing...';
  StreamSubscription? _subscription;
  
  DateTime? _lastUpdateTime;
  Timer? _heartbeatTimer;
  Timer? _loadingTimeoutTimer;

  bool _isFirebaseReady = false;
  bool _isGlobalHandshakeDone = false;

  AppProvider() {
    _loadConfig();
    _startHeartbeatTimer();
  }

  void onFirebaseReady() {
    _isFirebaseReady = true;
    _isGlobalHandshakeDone = true;
    if (_projectId != null) {
      _initFirebase();
    }
  }

  String? get projectId => _projectId;
  String? get apiKey => _apiKey;
  String? get databaseUrl => _databaseUrl;
  String? get appId => _appId;
  String? get messagingSenderId => _messagingSenderId;
  String? get iosBundleId => _iosBundleId;
  String? get authEmail => _authEmail;
  String? get authPassword => _authPassword;

  DeviceData? get deviceData => _deviceData;
  bool get isLoading => _isLoading;
  bool get isConfigLoaded => _isConfigLoaded;
  String? get errorMessage => _errorMessage;
  String get loadingStatus => _loadingStatus;
  
  bool get isDeviceOnline {
    if (_lastUpdateTime == null) return false;
    final difference = DateTime.now().difference(_lastUpdateTime!).inSeconds;
    return difference < 20;
  }

  int get secondsSinceLastUpdate {
    if (_lastUpdateTime == null) return -1;
    return DateTime.now().difference(_lastUpdateTime!).inSeconds;
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_projectId != null) {
        notifyListeners();
      }
    });
  }

  void _startLoadingTimeout() {
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_isLoading) {
        _errorMessage = 'Connection timed out. Please check your internet connection.';
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadConfig() async {
    _loadingStatus = 'Checking local storage...';
    notifyListeners();
    
    _projectId = await _storageService.getProjectId();
    final config = await _storageService.getFirebaseConfig();
    _apiKey = config['apiKey'];
    _databaseUrl = config['databaseUrl'];
    _appId = config['appId'];
    _messagingSenderId = config['messagingSenderId'];
    _iosBundleId = config['iosBundleId'];

    final auth = await _storageService.getAuthCredentials();
    _authEmail = auth['email'];
    _authPassword = auth['password'];
    
    // Auto-Discovery from CI Secrets
    if (_projectId == null) {
      _tryAutoConfigureFromCI();
    }

    _isConfigLoaded = true;
    if (_projectId != null && _isFirebaseReady) {
      _initFirebase();
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _tryAutoConfigureFromCI() {
    try {
      debugPrint('AppProvider: Auto-Discovery...');
      
      // PRIORITY 1: CI Secrets (from GitHub)
      if (FirebaseSecrets.projectId != null) {
        _projectId ??= FirebaseSecrets.projectId;
        _apiKey ??= FirebaseSecrets.apiKey;
        _appId ??= FirebaseSecrets.appId;
        _databaseUrl ??= FirebaseSecrets.databaseURL;
        _iosBundleId ??= FirebaseSecrets.iosBundleId;
        _messagingSenderId ??= FirebaseSecrets.messagingSenderId;
        debugPrint('AppProvider: Configured from CI for $_projectId');
      }

      // PRIORITY 2: Hardcoded Default (Final Fallback)
      if (_projectId == null) {
        _projectId = 'smart-home-dc84e';
        debugPrint('AppProvider: Using Hardcoded Fallback for $_projectId');
      }
    } catch (e) {
      debugPrint('AppProvider: Auto-config failed: $e');
    }
  }

  void _initFirebase() async {
    if (!_isGlobalHandshakeDone) {
      debugPrint('AppProvider: Waiting for global handshake...');
      return;
    }

    if (_projectId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    _loadingStatus = 'Connecting to Firebase...';
    notifyListeners();
    
    _startLoadingTimeout();

    final dbUrl = _databaseUrl ?? 'https://smart-home-dc84e-default-rtdb.asia-southeast1.firebasedatabase.app';
    
    FirebaseApp? app;
    try {
      // Prefer custom app if configured, otherwise use default
      if (_apiKey != null && _appId != null) {
        try {
          app = await Firebase.initializeApp(
            name: 'custom_home',
            options: FirebaseOptions(
              apiKey: _apiKey!,
              appId: _appId!,
              messagingSenderId: _messagingSenderId ?? '',
              projectId: _projectId ?? '',
              databaseURL: dbUrl,
              iosBundleId: _iosBundleId,
            ),
          );
        } catch (e) {
          if (e.toString().contains('duplicate-app')) {
            app = Firebase.app('custom_home');
          } else {
            throw 'Custom Firebase Init Error: $e';
          }
        }
      } else {
        app = Firebase.app();
      }
    } catch (e) {
      _errorMessage = 'Firebase not ready. Please check your configuration.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (app == null) {
      _errorMessage = 'Could not find a valid Firebase instance.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Unified Authentication
    // Use stored credentials if available, otherwise fallback to defaults
    final email = _authEmail ?? "smarthome@project.com";
    final password = _authPassword ?? "123456";

    try {
      debugPrint('AppProvider: Authenticating as $email...');
      await FirebaseAuth.instanceFor(app: app).signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('AppProvider: Auth Successful');
    } catch (e) {
      _errorMessage = 'Authentication Failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _firebaseService = FirebaseService(
      projectId: _projectId!,
      databaseUrl: dbUrl,
      app: app,
    );
    _subscription?.cancel();
    _subscription = _firebaseService!.getDeviceDataStream().listen(
      (data) {
        _loadingTimeoutTimer?.cancel();
        
        // Logic check: if sensors are missing, the path might be wrong or device never sent data
        if (data.sensors.temperature == 0 && data.sensors.humidity == 0 && data.system.rssi == 0) {
           // We can't be 100% sure it's "not found" vs "just zeroed", 
           // but we can check the snapshot more deeply in FirebaseService if needed.
           // For now, let's just assume valid if we get an event.
        }

        _deviceData = data;
        _lastUpdateTime = DateTime.now();
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _loadingTimeoutTimer?.cancel();
        String msg = error.toString();
        if (msg.contains('permission-denied')) {
          _errorMessage = 'Access Denied: Please check your Firebase Security Rules.';
        } else {
          _errorMessage = 'Firebase Error: $msg';
        }
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> setProjectId(String id) async {
    _projectId = id;
    await _storageService.saveProjectId(id);
    if (_isFirebaseReady) {
      _initFirebase();
    }
  }

  Future<void> updateApiKeys(String key, String secret) async {
    _apiKey = key;
    await _storageService.saveApiKeys(key, secret);
    
    // Live refresh the connection if already active
    if (_projectId != null && _isFirebaseReady) {
      _initFirebase();
    }
    notifyListeners();
  }

  Future<void> updateFirebaseConfig({
    required String databaseUrl,
    required String apiKey,
    required String appId,
    required String messagingSenderId,
    String? iosBundleId,
  }) async {
    _databaseUrl = databaseUrl;
    _apiKey = apiKey;
    _appId = appId;
    _messagingSenderId = messagingSenderId;
    _iosBundleId = iosBundleId;

    await _storageService.saveFirebaseConfig(
      databaseUrl: databaseUrl,
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      iosBundleId: iosBundleId,
    );

    if (_projectId != null && _isFirebaseReady) {
      _initFirebase();
    }
    notifyListeners();
  }

  Future<void> updateAuthCredentials(String email, String password) async {
    _authEmail = email;
    _authPassword = password;
    await _storageService.saveAuthCredentials(email, password);

    if (_projectId != null && _isFirebaseReady) {
      _initFirebase();
    }
    notifyListeners();
  }

  Future<void> clearProjectId() async {
    _subscription?.cancel();
    _loadingTimeoutTimer?.cancel();
    _projectId = null;
    _apiKey = null;
    _databaseUrl = null;
    _appId = null;
    _messagingSenderId = null;
    _iosBundleId = null;
    _authEmail = null;
    _authPassword = null;
    _deviceData = null;
    _firebaseService = null;
    await _storageService.clearProjectId();
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> toggleActuator(String actuator, bool value) async {
    try {
      await _firebaseService?.updateActuator(actuator, value);
    } catch (e) {
      _errorMessage = 'Failed to toggle $actuator: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> toggleMode(bool isAuto) async {
    try {
      await _firebaseService?.setOperationMode(isAuto);
    } catch (e) {
      _errorMessage = 'Failed to change mode: ${e.toString()}';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
