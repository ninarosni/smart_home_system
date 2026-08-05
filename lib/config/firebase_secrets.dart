// This file is a placeholder that will be overwritten during the CI/CD build process.
// Do not commit real secrets here.
class FirebaseSecrets {
  static const String? apiKey = null;
  static const String? appId = null;
  static const String? messagingSenderId = null;
  static const String? projectId = null;
  static const String? databaseURL = null;
  static const String? iosBundleId = null;

  static String get diagnosticInfo {
    return 'API Key: ${apiKey != null ? "FOUND" : "MISSING"}, '
           'App ID: ${appId != null ? "FOUND" : "MISSING"}, '
           'Project ID: ${projectId != null ? "FOUND" : "MISSING"}';
  }
}
