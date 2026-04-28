import 'package:fin_sage/core/constants/app_constants.dart';
import 'package:fin_sage/core/constants/google_auth_config.dart';
import 'package:fin_sage/data/datasources/local/auto_backup_telemetry_storage.dart';
import 'package:fin_sage/data/datasources/local/db_migration_service.dart';
import 'package:fin_sage/data/datasources/local/local_database_datasource.dart';
import 'package:fin_sage/data/datasources/local/secure_key_service.dart';
import 'package:fin_sage/data/datasources/remote/google_drive_datasource.dart';
import 'package:fin_sage/data/repositories/impl/backup_repository_impl.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

abstract class AutoBackupValidationScheduler {
  Future<void> scheduleValidationNow();
}

class WorkmanagerAutoBackupValidationScheduler implements AutoBackupValidationScheduler {
  const WorkmanagerAutoBackupValidationScheduler();

  @override
  Future<void> scheduleValidationNow() => BackupScheduler.scheduleValidationNow();
}

class BackupScheduler {
  static const String taskName = 'finsage.auto_backup';
  static const String validationTaskName = 'finsage.auto_backup.validation';
  static bool _initialized = false;
  static bool _periodicScheduled = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await Workmanager().initialize(_callbackDispatcher, isInDebugMode: false);
    _initialized = true;
  }

  static Future<void> scheduleEvery24Hours() async {
    if (_periodicScheduled) {
      return;
    }
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: AppConstants.autoBackupInterval,
      initialDelay: const Duration(minutes: 10),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
    _periodicScheduled = true;
  }

  static Future<void> scheduleValidationNow() async {
    await Workmanager().registerOneOffTask(
      validationTaskName,
      taskName,
      initialDelay: const Duration(seconds: 5),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
}

@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != BackupScheduler.taskName) {
      return Future<bool>.value(false);
    }
    return _performAutoBackup();
  });
}

@pragma('vm:entry-point')
Future<bool> _performAutoBackup() async {
  final now = DateTime.now().toUtc();
  try {
    WidgetsFlutterBinding.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final telemetry = SharedPrefsAutoBackupTelemetryStorage(prefs);
    await telemetry.markAttempt(now);

    const secureStorage = FlutterSecureStorage();
    final local = LocalDatabaseDataSource(SecureKeyService(secureStorage), DbMigrationService());
    final googleSignIn = GoogleSignIn(
      clientId: GoogleAuthConfig.clientIdOrNull,
      serverClientId: GoogleAuthConfig.serverClientIdOrNull,
      scopes: const [
        'email',
        'https://www.googleapis.com/auth/drive.appdata',
      ],
    );
    final remote = GoogleDriveDataSource(googleSignIn, allowInteractiveSignIn: false);
    final backupRepo = BackupRepositoryImpl(local, remote);
    await backupRepo.backupNow();
    await telemetry.markSuccess(now);
    return true;
  } catch (e) {
    try {
      final prefs = await SharedPreferences.getInstance();
      final telemetry = SharedPrefsAutoBackupTelemetryStorage(prefs);
      await telemetry.markFailure(now, e.toString());
    } catch (_) {
      // Ignore telemetry failure to keep the background task result deterministic.
    }
    return false;
  }
}
