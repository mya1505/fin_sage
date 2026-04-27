import 'package:fin_sage/data/datasources/local/drift_query_service.dart';
import 'package:fin_sage/data/datasources/local/local_database_datasource.dart';
import 'package:fin_sage/data/datasources/local/secure_key_service.dart';
import 'package:fin_sage/data/datasources/remote/google_drive_datasource.dart';
import 'package:fin_sage/data/repositories/auth_repository.dart';
import 'package:fin_sage/data/repositories/backup_repository.dart';
import 'package:fin_sage/data/repositories/budget_repository.dart';
import 'package:fin_sage/data/repositories/impl/auth_repository_impl.dart';
import 'package:fin_sage/data/repositories/impl/backup_repository_impl.dart';
import 'package:fin_sage/data/repositories/impl/budget_repository_impl.dart';
import 'package:fin_sage/data/repositories/impl/transaction_repository_impl.dart';
import 'package:fin_sage/data/repositories/transaction_repository.dart';
import 'package:fin_sage/logic/auth/auth_cubit.dart';
import 'package:fin_sage/logic/budgets/budget_cubit.dart';
import 'package:fin_sage/logic/dashboard/dashboard_cubit.dart';
import 'package:fin_sage/logic/reports/report_cubit.dart';
import 'package:fin_sage/logic/settings/settings_cubit.dart';
import 'package:fin_sage/logic/transactions/transaction_cubit.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GetIt sl = GetIt.instance;

class ServiceLocator {
  static Future<void> init() async {
    sl.registerLazySingleton(() => const FlutterSecureStorage());
    sl.registerLazySingleton(() => SecureKeyService(sl()));
    sl.registerLazySingleton(() => LocalDatabaseDataSource(sl()));
    sl.registerLazySingleton(() => DriftQueryService());

    sl.registerLazySingleton(
      () => GoogleSignIn(
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
    sl.registerFactory(() => BudgetCubit(sl()));
    sl.registerFactory(() => ReportCubit());
    sl.registerFactory(() => SettingsCubit(sl()));
  }
}
