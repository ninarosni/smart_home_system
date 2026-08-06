import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/device_data.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';

class AppProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  FirebaseService? _firebaseService;
  
  String? _homeId;
  String? _firebaseProjectId;
  String? _apiKey;
  String? _databaseUrl;
  String? _appId;
  String? _messagingSenderId;
  String? _authEmail;
  String? _authPassword;

  DeviceData? _deviceData;
  bool _isLoading = false;
  bool _isConfigLoaded = false;
  String? _errorMessage;
  String _loadingStatus = '';
  StreamSubscription? _subscription;
  
  DateTime? _lastUpdateTime;
  Timer? _heartbeatTimer;
  Timer? _loadingTimeoutTimer;

  AppProvider() {
    _loadConfig();
    _startHeartbeatTimer();
  }

  String? get homeId => _homeId;
  String? get firebaseProjectId => _firebaseProjectId;
  String? get apiKey => _apiKey;
  String? get databaseUrl => _databaseUrl;
  String? get appId => _appId;
  String? get messagingSenderId => _messagingSenderId;
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
      if (_homeId != null) {
        notifyListeners();
      }
    });
  }

  void _startLoadingTimeout() {
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_isLoading) {
        _errorMessage = 'Connection timed out. Check your internet or credentials.';
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadConfig() async {
    _homeId = await _storageService.getHomeId();
    final config = await _storageService.getFirebaseConfig();
    _firebaseProjectId = config['projectId'];
    _apiKey = config['apiKey'];
    _databaseUrl = config['databaseUrl'];
    _appId = config['appId'];
    _messagingSenderId = config['messagingSenderId'];

    final auth = await _storageService.getAuthCredentials();
    _authEmail = auth['email'];
    _authPassword = auth['password'];
    
    _isConfigLoaded = true;
    
    if (_homeId != null) {
      connectToFirebase();
    } else {
      notifyListeners();
    }
  }

  Future<void> connectToFirebase() async {
    if (_homeId == null) return;
    
    _isLoading = true;
    _errorMessage = null;
    _loadingStatus = 'Connecting...';
    notifyListeners();
    
    _startLoadingTimeout();

    try {
      // 1. Clean shutdown of previous connection
      await _subscription?.cancel();
      _subscription = null;
      _deviceData = null;
      
      try {
        await Firebase.app().delete();
      } catch (_) {}

      // 2. Determine Connection Strategy
      // If ANY key is provided, we MUST use FirebaseOptions to override the native file
      if (_apiKey != null || _databaseUrl != null || _firebaseProjectId != null) {
        debugPrint('AppProvider: Manual Connection Strategy Active');
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: _apiKey ?? '', 
            appId: _appId ?? '1:517039773968:android:7d9360a49226d10bbbad95', // Use default App ID if missing
            messagingSenderId: _messagingSenderId ?? '517039773968',
            projectId: _firebaseProjectId ?? 'smart-home-dc84e',
            databaseURL: _databaseUrl ?? 'https://smart-home-dc84e-default-rtdb.asia-southeast1.firebasedatabase.app',
          ),
        );
      } else {
        debugPrint('AppProvider: Native File Strategy Active');
        await Firebase.initializeApp();
      }

      // 3. Authenticate
      final email = _authEmail ?? "smarthome@project.com";
      final password = _authPassword ?? "123456";
      
      debugPrint('AppProvider: Attempting Auth for $email');
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 4. Start Data Stream
      _firebaseService = FirebaseService(homeId: _homeId!);
      
      _subscription = _firebaseService!.getDeviceDataStream().listen(
        (data) {
          _loadingTimeoutTimer?.cancel();
          _deviceData = data;
          _lastUpdateTime = DateTime.now();
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (error) {
          _loadingTimeoutTimer?.cancel();
          _errorMessage = 'Database Access Denied or Missing Path.';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('AppProvider: Connection FATAL ERROR: $e');
      _errorMessage = 'Failed to connect. Check API Key and URL.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setHomeId(String id) async {
    _homeId = id;
    await _storageService.saveHomeId(id);
    await connectToFirebase();
  }

  Future<void> updateFirebaseConfig({
    required String projectId,
    required String databaseUrl,
    required String apiKey,
    required String appId,
    required String messagingSenderId,
  }) async {
    _firebaseProjectId = projectId.isEmpty ? null : projectId;
    _databaseUrl = databaseUrl.isEmpty ? null : databaseUrl;
    _apiKey = apiKey.isEmpty ? null : apiKey;
    _appId = appId.isEmpty ? null : appId;
    _messagingSenderId = messagingSenderId.isEmpty ? null : messagingSenderId;

    await _storageService.saveFirebaseConfig(
      projectId: _firebaseProjectId ?? '',
      databaseUrl: _databaseUrl ?? '',
      apiKey: _apiKey ?? '',
      appId: _appId ?? '',
      messagingSenderId: _messagingSenderId ?? '',
    );

    await connectToFirebase();
  }

  Future<void> updateAuthCredentials(String email, String password) async {
    _authEmail = email.isEmpty ? null : email;
    _authPassword = password.isEmpty ? null : password;
    await _storageService.saveAuthCredentials(_authEmail ?? '', _authPassword ?? '');
    await connectToFirebase();
  }

  Future<void> clearAll() async {
    await _subscription?.cancel();
    _subscription = null;
    _loadingTimeoutTimer?.cancel();
    _homeId = null;
    _firebaseProjectId = null;
    _apiKey = null;
    _databaseUrl = null;
    _appId = null;
    _messagingSenderId = null;
    _authEmail = null;
    _authPassword = null;
    _deviceData = null;
    _firebaseService = null;
    await _storageService.clearAll();
    notifyListeners();
  }

  Future<void> toggleActuator(String actuator, bool value) async {
    try {
      await _firebaseService?.updateActuator(actuator, value);
    } catch (e) {
      _errorMessage = 'Toggle Failed: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> toggleMode(bool isAuto) async {
    try {
      await _firebaseService?.setOperationMode(isAuto);
    } catch (e) {
      _errorMessage = 'Mode Switch Failed: ${e.toString()}';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
