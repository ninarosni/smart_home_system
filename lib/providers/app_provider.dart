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
        _errorMessage = 'Connection timed out. Check your settings.';
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
    _loadingStatus = 'Hard Disconnecting...';
    notifyListeners();
    
    _startLoadingTimeout();

    try {
      await _subscription?.cancel();
      _subscription = null;
      _deviceData = null;
      
      try {
        await Firebase.app().delete();
        await Future.delayed(const Duration(milliseconds: 600));
      } catch (_) {}

      _loadingStatus = 'Regrowing Connection...';
      notifyListeners();

      if (_apiKey != null && _databaseUrl != null) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: _apiKey!,
            appId: _appId ?? '1:517039773968:android:7d9360a49226d10bbbad95',
            messagingSenderId: _messagingSenderId ?? '517039773968',
            projectId: _firebaseProjectId ?? 'smart-home-dc84e',
            databaseURL: _databaseUrl!,
          ),
        );
      } else {
        await Firebase.initializeApp();
      }

      final email = _authEmail ?? "smarthome@project.com";
      final password = _authPassword ?? "123456";
      
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _firebaseService = FirebaseService(
        homeId: _homeId!,
        databaseUrl: _databaseUrl,
      );
      
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
          _errorMessage = 'Access Denied: Check Rules or Path.';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Connection Failed: Check Keys/Network.';
      _isLoading = false;
      notifyListeners();
    }
  }

  // ATOMIC APPLY: Save everything first, then reconnect once.
  Future<void> applyAllSettings({
    required String projectId,
    required String databaseUrl,
    required String apiKey,
    required String appId,
    required String messagingSenderId,
    required String email,
    required String password,
  }) async {
    _firebaseProjectId = projectId.isEmpty ? null : projectId;
    _databaseUrl = databaseUrl.isEmpty ? null : databaseUrl;
    _apiKey = apiKey.isEmpty ? null : apiKey;
    _appId = appId.isEmpty ? null : appId;
    _messagingSenderId = messagingSenderId.isEmpty ? null : messagingSenderId;
    _authEmail = email.isEmpty ? null : email;
    _authPassword = password.isEmpty ? null : password;

    // 1. Save all to storage
    await _storageService.saveFirebaseConfig(
      projectId: _firebaseProjectId ?? '',
      databaseUrl: _databaseUrl ?? '',
      apiKey: _apiKey ?? '',
      appId: _appId ?? '',
      messagingSenderId: _messagingSenderId ?? '',
    );
    await _storageService.saveAuthCredentials(
      _authEmail ?? '',
      _authPassword ?? '',
    );

    // 2. Trigger exactly ONE reconnection cycle
    await connectToFirebase();
  }

  Future<void> setHomeId(String id) async {
    _homeId = id;
    await _storageService.saveHomeId(id);
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
      _errorMessage = 'Control Failed: ${e.toString()}';
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
