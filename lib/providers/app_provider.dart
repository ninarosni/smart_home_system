import 'dart:async';
import 'package:flutter/material.dart';
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

  bool _isFirebaseInitialized = false;

  AppProvider() {
    _loadConfig();
    _startHeartbeatTimer();
  }

  void onFirebaseReady() {
    _isFirebaseInitialized = true;
    if (_projectId != null) {
      _startDataStream();
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
    
    if (_projectId == null) {
      _projectId = 'smart-home-dc84e';
    }

    _isConfigLoaded = true;
    notifyListeners();
  }

  void _startDataStream() async {
    if (!_isFirebaseInitialized || _projectId == null) return;
    
    _isLoading = true;
    _errorMessage = null;
    _loadingStatus = 'Connecting to database...';
    notifyListeners();
    
    _startLoadingTimeout();

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
        String msg = error.toString();
        if (msg.contains('permission-denied')) {
          _errorMessage = 'Access Denied: Check Firebase Rules.';
        } else {
          _errorMessage = 'Connection Error: $msg';
        }
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> setProjectId(String id) async {
    _projectId = id;
    await _storageService.saveProjectId(id);
    _startDataStream();
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

    _isFirebaseInitialized = false;
    _isConfigLoaded = false;
    _loadConfig();
  }

  Future<void> updateAuthCredentials(String email, String password) async {
    _authEmail = email;
    _authPassword = password;
    await _storageService.saveAuthCredentials(email, password);
    
    _isFirebaseInitialized = false;
    _isConfigLoaded = false;
    _loadConfig();
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
    _iosBundleId = null;
    _authEmail = null;
    _authPassword = null;
    _deviceData = null;
    _firebaseService = null;
    await _storageService.clearProjectId();
    
    _isFirebaseInitialized = false;
    _isConfigLoaded = false;
    _loadConfig();
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
