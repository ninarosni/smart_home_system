// THIS FILE IS AUTOMATICALLY OVERWRITTEN BY GITHUB ACTIONS DURING BUILDS.
// DO NOT ADD SECRETS HERE LOCALLY.
class FirebaseSecrets {
  static const String? apiKey = null;
  static const String? appId = null;
  static const String? messagingSenderId = null;
  static const String? projectId = null;
  static const String? databaseURL = null;
  static const String? iosBundleId = null;

  static String get diagnosticInfo {
    return 'API: ${apiKey != null ? "OK" : "MISSING"}, '
           'ID: ${appId != null ? "OK" : "MISSING"}, '
           'Project: ${projectId != null ? "OK" : "MISSING"}, '
           'Bundle: ${iosBundleId != null ? "OK" : "MISSING"}';
  }
}
