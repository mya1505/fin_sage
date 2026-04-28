import 'package:fin_sage/core/constants/app_constants.dart';
import 'package:fin_sage/data/datasources/local/db_migration_service.dart';
import 'package:fin_sage/data/datasources/local/local_database_datasource.dart';
import 'package:fin_sage/data/datasources/local/secure_key_service.dart';
import 'package:fin_sage/data/datasources/remote/google_drive_datasource.dart';
import 'package:fin_sage/data/repositories/impl/backup_repository_impl.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:workmanager/workmanager.dart';

class BackupScheduler {
  static const String taskName = 'finsage.auto_backup';

  static Future<void> initialize() async {
    await Workmanager().initialize(_callbackDispatcher, isInDebugMode: false);
  }

  static Future<void> scheduleEvery24Hours() async {
    await Workmanager().registerPeriodicTask(
      taskName,
      taskName,
      frequency: AppConstants.autoBackupInterval,
      initialDelay: const Duration(minutes: 10),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.keep,
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
  try {
    WidgetsFlutterBinding.ensureInitialized();
    const secureStorage = FlutterSecureStorage();
    final local = LocalDatabaseDataSource(SecureKeyService(secureStorage), DbMigrationService());
    final googleSignIn = GoogleSignIn(
      scopes: const [
        'email',
        'https://www.googleapis.com/auth/drive.appdata',
      ],
    );
    final remote = GoogleDriveDataSource(googleSignIn, allowInteractiveSignIn: false);
    final backupRepo = BackupRepositoryImpl(local, remote);
    await backupRepo.backupNow();
    return true;
  } catch (_) {
    return false;
  }
}
