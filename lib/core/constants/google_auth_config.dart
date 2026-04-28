class GoogleAuthConfig {
  static const String clientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
  static const String hostedDomain = String.fromEnvironment('GOOGLE_HOSTED_DOMAIN', defaultValue: '');

  static String? get clientIdOrNull => clientId.trim().isEmpty ? null : clientId.trim();
  static String? get serverClientIdOrNull =>
      serverClientId.trim().isEmpty ? null : serverClientId.trim();
  static String? get hostedDomainOrNull => hostedDomain.trim().isEmpty ? null : hostedDomain.trim();

  static bool get hasServerClientId => serverClientIdOrNull != null;
}
