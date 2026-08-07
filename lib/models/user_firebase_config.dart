class UserFirebaseConfig {
  const UserFirebaseConfig({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    required this.databaseUrl,
  });

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String databaseUrl;
}
