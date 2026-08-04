import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyProjectId = 'project_id';
  static const String _keyApiKey = 'api_key';
  static const String _keyApiSecret = 'api_secret'; // Retaining for compatibility if needed
  static const String _keyDatabaseUrl = 'database_url';
  static const String _keyAppId = 'app_id';
  static const String _keyMessagingSenderId = 'messaging_sender_id';
  static const String _keyAuthEmail = 'auth_email';
  static const String _keyAuthPassword = 'auth_password';
  static const String _keyIosBundleId = 'ios_bundle_id';

  Future<void> saveProjectId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProjectId, id);
  }

  Future<String?> getProjectId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyProjectId);
  }

  Future<void> saveApiKeys(String key, String secret) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey, key);
    await prefs.setString(_keyApiSecret, secret);
  }

  Future<void> saveFirebaseConfig({
    required String databaseUrl,
    required String apiKey,
    required String appId,
    required String messagingSenderId,
    String? iosBundleId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDatabaseUrl, databaseUrl);
    await prefs.setString(_keyApiKey, apiKey);
    await prefs.setString(_keyAppId, appId);
    await prefs.setString(_keyMessagingSenderId, messagingSenderId);
    if (iosBundleId != null) {
      await prefs.setString(_keyIosBundleId, iosBundleId);
    }
  }

  Future<Map<String, String?>> getFirebaseConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'databaseUrl': prefs.getString(_keyDatabaseUrl),
      'apiKey': prefs.getString(_keyApiKey),
      'appId': prefs.getString(_keyAppId),
      'messagingSenderId': prefs.getString(_keyMessagingSenderId),
      'iosBundleId': prefs.getString(_keyIosBundleId),
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

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiKey);
  }

  Future<String?> getApiSecret() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiSecret);
  }

  Future<void> clearProjectId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProjectId);
    await prefs.remove(_keyApiKey);
    await prefs.remove(_keyApiSecret);
    await prefs.remove(_keyDatabaseUrl);
    await prefs.remove(_keyAppId);
    await prefs.remove(_keyMessagingSenderId);
    await prefs.remove(_keyAuthEmail);
    await prefs.remove(_keyAuthPassword);
    await prefs.remove(_keyIosBundleId);
  }
}
