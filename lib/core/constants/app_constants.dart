class AppConstants {
  static const String appName = 'FinSage';
  static const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0+1');
  static const Duration autoBackupInterval = Duration(hours: 24);
  static const String dbName = 'finsage_secure.db';
  static const String dbEncryptionKey = 'db_encryption_key';
}
