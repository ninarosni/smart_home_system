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
  
  String? _projectId;
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

  String? get projectId => _projectId;
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
      if (_projectId != null) {
        notifyListeners();
      }
    });
  }

  void _startLoadingTimeout() {
    _loadingTimeoutTimer?.cancel();
    _loadingTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (_isLoading) {
        _errorMessage = 'Connection timed out. Please check your settings.';
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadConfig() async {
    _projectId = await _storageService.getProjectId();
    final config = await _storageService.getFirebaseConfig();
    _apiKey = config['apiKey'];
    _databaseUrl = config['databaseUrl'];
    _appId = config['appId'];
    _messagingSenderId = config['messagingSenderId'];

    final auth = await _storageService.getAuthCredentials();
    _authEmail = auth['email'];
    _authPassword = auth['password'];
    
    _isConfigLoaded = true;
    
    if (_projectId != null) {
      // If we have an ID, start the connection automatically
      connectToFirebase();
    } else {
      notifyListeners();
    }
  }

  Future<void> connectToFirebase() async {
    if (_projectId == null) return;
    
    _isLoading = true;
    _errorMessage = null;
    _loadingStatus = 'Connecting...';
    notifyListeners();
    
    _startLoadingTimeout();

    try {
      // Ensure we are working with a clean slate
      try {
        await Firebase.app().delete();
      } catch (_) {}

      // 1. Initialize Firebase
      if (_apiKey != null && _databaseUrl != null) {
        debugPrint('AppProvider: Initializing with custom options');
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: _apiKey!,
            appId: _appId ?? '1:0:android:0', // Placeholder if missing
            messagingSenderId: _messagingSenderId ?? '0',
            projectId: _projectId!,
            databaseURL: _databaseUrl!,
          ),
        );
      } else {
        debugPrint('AppProvider: Initializing with default native options');
        await Firebase.initializeApp();
      }

      // 2. Authenticate
      final email = _authEmail ?? "smarthome@project.com";
      final password = _authPassword ?? "123456";
      
      debugPrint('AppProvider: Authenticating as $email...');
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Start Data Stream
      _firebaseService = FirebaseService(projectId: _projectId!);
      
      await _subscription?.cancel();
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
          _errorMessage = 'Database Error: ${error.toString()}';
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('AppProvider: Connection FAILED: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setProjectId(String id) async {
    _projectId = id;
    await _storageService.saveProjectId(id);
    await connectToFirebase();
  }

  Future<void> updateFirebaseConfig({
    required String databaseUrl,
    required String apiKey,
    required String appId,
    required String messagingSenderId,
  }) async {
    _databaseUrl = databaseUrl;
    _apiKey = apiKey;
    _appId = appId;
    _messagingSenderId = messagingSenderId;

    await _storageService.saveFirebaseConfig(
      databaseUrl: databaseUrl,
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
    );

    await connectToFirebase();
  }

  Future<void> updateAuthCredentials(String email, String password) async {
    _authEmail = email;
    _authPassword = password;
    await _storageService.saveAuthCredentials(email, password);
    await connectToFirebase();
  }

  Future<void> clearProjectId() async {
    await _subscription?.cancel();
    _subscription = null;
    _loadingTimeoutTimer?.cancel();
    _projectId = null;
    _apiKey = null;
    _databaseUrl = null;
    _appId = null;
    _messagingSenderId = null;
    _authEmail = null;
    _authPassword = null;
    _deviceData = null;
    _firebaseService = null;
    await _storageService.clearProjectId();
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
