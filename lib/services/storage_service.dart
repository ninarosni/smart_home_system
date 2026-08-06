import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyHomeId = 'home_id';
  static const String _keyFirebaseProjectId = 'firebase_project_id';
  static const String _keyApiKey = 'api_key';
  static const String _keyDatabaseUrl = 'database_url';
  static const String _keyAppId = 'app_id';
  static const String _keyMessagingSenderId = 'messaging_sender_id';
  static const String _keyAuthEmail = 'auth_email';
  static const String _keyAuthPassword = 'auth_password';

  Future<void> saveHomeId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHomeId, id);
  }

  Future<String?> getHomeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHomeId);
  }

  Future<void> saveFirebaseConfig({
    required String projectId,
    required String databaseUrl,
    required String apiKey,
    required String appId,
    required String messagingSenderId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFirebaseProjectId, projectId);
    await prefs.setString(_keyDatabaseUrl, databaseUrl);
    await prefs.setString(_keyApiKey, apiKey);
    await prefs.setString(_keyAppId, appId);
    await prefs.setString(_keyMessagingSenderId, messagingSenderId);
  }

  Future<Map<String, String?>> getFirebaseConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'projectId': prefs.getString(_keyFirebaseProjectId),
      'databaseUrl': prefs.getString(_keyDatabaseUrl),
      'apiKey': prefs.getString(_keyApiKey),
      'appId': prefs.getString(_keyAppId),
      'messagingSenderId': prefs.getString(_keyMessagingSenderId),
    };
  }

  Future<void> saveAuthCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthEmail, email);
    await prefs.setString(_keyAuthPassword, password);
  }

  Future<Map<String, String?>> getAuthCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_keyAuthEmail),
      'password': prefs.getString(_keyAuthPassword),
    };
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHomeId);
    await prefs.remove(_keyFirebaseProjectId);
    await prefs.remove(_keyApiKey);
    await prefs.remove(_keyDatabaseUrl);
    await prefs.remove(_keyAppId);
    await prefs.remove(_keyMessagingSenderId);
    await prefs.remove(_keyAuthEmail);
    await prefs.remove(_keyAuthPassword);
  }
}
