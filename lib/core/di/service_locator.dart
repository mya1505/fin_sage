import 'package:fin_sage/data/datasources/local/db_migration_service.dart';
import 'package:fin_sage/data/datasources/local/drift_query_service.dart';
import 'package:fin_sage/data/datasources/local/local_database_datasource.dart';
import 'package:fin_sage/data/datasources/local/secure_key_service.dart';
import 'package:fin_sage/data/datasources/local/settings_storage.dart';
import 'package:fin_sage/data/datasources/local/auto_backup_telemetry_storage.dart';
import 'package:fin_sage/data/datasources/remote/google_drive_datasource.dart';
import 'package:fin_sage/core/constants/google_auth_config.dart';
import 'package:fin_sage/data/repositories/auth_repository.dart';
import 'package:fin_sage/data/repositories/backup_repository.dart';
import 'package:fin_sage/data/repositories/budget_repository.dart';
import 'package:fin_sage/data/repositories/impl/auth_repository_impl.dart';
import 'package:fin_sage/data/repositories/impl/backup_repository_impl.dart';
import 'package:fin_sage/data/repositories/impl/budget_repository_impl.dart';
import 'package:fin_sage/data/repositories/impl/transaction_repository_impl.dart';
import 'package:fin_sage/data/repositories/transaction_repository.dart';
import 'package:fin_sage/features/budgets/budget_notification_service.dart';
import 'package:fin_sage/features/settings/backup_scheduler.dart';
import 'package:fin_sage/logic/auth/auth_cubit.dart';
import 'package:fin_sage/logic/budgets/budget_cubit.dart';
import 'package:fin_sage/logic/dashboard/dashboard_cubit.dart';
import 'package:fin_sage/logic/reports/report_cubit.dart';
import 'package:fin_sage/logic/settings/settings_cubit.dart';
import 'package:fin_sage/logic/transactions/transaction_cubit.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GetIt sl = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    sl.registerLazySingleton(() => const FlutterSecureStorage());
    sl.registerLazySingleton<SettingsStorage>(() => SharedPrefsSettingsStorage(prefs));
    sl.registerLazySingleton<AutoBackupTelemetryStorage>(
      () => SharedPrefsAutoBackupTelemetryStorage(prefs),
    );
    sl.registerLazySingleton(() => SecureKeyService(sl()));
    sl.registerLazySingleton(() => DbMigrationService());
    sl.registerLazySingleton(() => LocalDatabaseDataSource(sl(), sl()));
    sl.registerLazySingleton(() => DriftQueryService());
    sl.registerLazySingleton(() => FlutterLocalNotificationsPlugin());
    sl.registerLazySingleton(() => BudgetNotificationService(sl()));
    sl.registerLazySingleton<AutoBackupValidationScheduler>(
      () => const WorkmanagerAutoBackupValidationScheduler(),
    );

    sl.registerLazySingleton(
      () => GoogleSignIn(
        clientId: GoogleAuthConfig.clientIdOrNull,
        serverClientId: GoogleAuthConfig.serverClientIdOrNull,
        scopes: const [
          'email',
          'https://www.googleapis.com/auth/drive.appdata',
        ],
      ),
    );
    sl.registerLazySingleton(() => GoogleDriveDataSource(sl()));

    sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
    sl.registerLazySingleton<TransactionRepository>(() => TransactionRepositoryImpl(sl(), sl()));
    sl.registerLazySingleton<BudgetRepository>(() => BudgetRepositoryImpl(sl()));
    sl.registerLazySingleton<BackupRepository>(() => BackupRepositoryImpl(sl(), sl()));

    sl.registerFactory(() => AuthCubit(sl()));
    sl.registerFactory(() => DashboardCubit(sl()));
    sl.registerFactory(() => TransactionCubit(sl()));
    sl.registerFactory(() => BudgetCubit(sl(), sl(), sl()));
    sl.registerFactory(() => ReportCubit());
    sl.registerFactory(() => SettingsCubit(sl(), sl(), sl(), sl(), sl()));
  }
}
