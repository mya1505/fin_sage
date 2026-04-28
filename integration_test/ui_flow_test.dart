import 'package:fin_sage/data/datasources/local/auto_backup_telemetry_storage.dart';
import 'package:fin_sage/data/datasources/local/local_database_datasource.dart';
import 'package:fin_sage/data/datasources/local/settings_storage.dart';
import 'package:fin_sage/data/models/backup_file_model.dart';
import 'package:fin_sage/data/models/category_model.dart';
import 'package:fin_sage/data/models/transaction_model.dart';
import 'package:fin_sage/data/repositories/backup_repository.dart';
import 'package:fin_sage/data/repositories/budget_repository.dart';
import 'package:fin_sage/data/repositories/transaction_repository.dart';
import 'package:fin_sage/core/errors/app_error_codes.dart';
import 'package:fin_sage/core/errors/app_exception.dart';
import 'package:fin_sage/core/constants/app_constants.dart';
import 'package:fin_sage/features/budgets/budget_notification_service.dart';
import 'package:fin_sage/features/reports/reports_page.dart';
import 'package:fin_sage/features/settings/backup_scheduler.dart';
import 'package:fin_sage/features/settings/settings_page.dart';
import 'package:fin_sage/features/transactions/transactions_page.dart';
import 'package:fin_sage/l10n/generated/app_localizations.dart';
import 'package:fin_sage/logic/budgets/budget_cubit.dart';
import 'package:fin_sage/logic/dashboard/dashboard_cubit.dart';
import 'package:fin_sage/logic/reports/report_cubit.dart';
import 'package:fin_sage/logic/settings/settings_cubit.dart';
import 'package:fin_sage/logic/transactions/transaction_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockBackupRepository extends Mock implements BackupRepository {}

class MockSettingsStorage extends Mock implements SettingsStorage {}

class MockBudgetNotificationService extends Mock implements BudgetNotificationService {}

class MockLocalDatabaseDataSource extends Mock implements LocalDatabaseDataSource {}

class MockAutoBackupTelemetryStorage extends Mock implements AutoBackupTelemetryStorage {}
class MockAutoBackupValidationScheduler extends Mock implements AutoBackupValidationScheduler {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(
      TransactionModel(
        id: null,
        title: 'Fallback',
        amount: 1,
        date: DateTime(2026, 1, 1),
        categoryId: 1,
        type: TransactionType.expense,
      ),
    );
  });

  testWidgets('transactions page should submit create transaction form', (tester) async {
    final txRepo = MockTransactionRepository();
    final txCubit = TransactionCubit(txRepo);
    addTearDown(txCubit.close);

    const categories = [
      CategoryModel(id: 1, name: 'General', colorHex: '#0D3B66', icon: 'wallet'),
    ];

    when(() => txRepo.fetchTransactions()).thenAnswer((_) async => []);
    when(() => txRepo.fetchCategories()).thenAnswer((_) async => categories);
    when(() => txRepo.saveTransaction(any())).thenAnswer((_) async {});

    await txCubit.loadTransactions();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TransactionCubit>.value(value: txCubit),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TransactionsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Transaction'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Coffee');
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '25000');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => txRepo.saveTransaction(any())).called(1);
  });

  testWidgets('settings restore should refresh transaction, budget, and dashboard data', (tester) async {
    final txRepo = MockTransactionRepository();
    final budgetRepo = MockBudgetRepository();
    final backupRepo = MockBackupRepository();
    final settingsStorage = MockSettingsStorage();
    final localDb = MockLocalDatabaseDataSource();
    final notificationService = MockBudgetNotificationService();
    final telemetryStorage = MockAutoBackupTelemetryStorage();
    final validationScheduler = MockAutoBackupValidationScheduler();

    final txCubit = TransactionCubit(txRepo);
    final budgetCubit = BudgetCubit(budgetRepo, notificationService, settingsStorage);
    final dashboardCubit = DashboardCubit(txRepo);
    final settingsCubit =
        SettingsCubit(backupRepo, settingsStorage, localDb, telemetryStorage, validationScheduler);

    addTearDown(txCubit.close);
    addTearDown(budgetCubit.close);
    addTearDown(dashboardCubit.close);
    addTearDown(settingsCubit.close);

    when(() => txRepo.fetchCategories()).thenAnswer(
      (_) async => const [CategoryModel(id: 1, name: 'General', colorHex: '#0D3B66', icon: 'wallet')],
    );
    when(() => txRepo.fetchTransactions()).thenAnswer((_) async => []);
    when(() => txRepo.monthlySummary()).thenAnswer((_) async => {'income': 0, 'expense': 0});

    when(() => budgetRepo.fetchBudgets()).thenAnswer((_) async => []);
    when(() => settingsStorage.loadNotificationsEnabled()).thenAnswer((_) async => true);

    when(() => settingsStorage.loadThemeMode()).thenAnswer((_) async => ThemeMode.system);
    when(() => settingsStorage.loadLocale()).thenAnswer((_) async => null);
    when(() => settingsStorage.loadLastBackupAt()).thenAnswer((_) async => null);
    when(() => telemetryStorage.loadTelemetry()).thenAnswer((_) async => const AutoBackupTelemetry());
    when(() => validationScheduler.scheduleValidationNow()).thenAnswer((_) async {});

    when(() => backupRepo.restorePreview()).thenAnswer(
      (_) async => const [
        BackupFileModel(
          id: 'file-1',
          name: 'finsage-backup-20260428_120000.db',
          createdAt: null,
          size: 1024,
        ),
      ],
    );
    when(() => backupRepo.restoreFromFile('file-1')).thenAnswer((_) async {});

    await settingsCubit.loadSettings();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TransactionCubit>.value(value: txCubit),
          BlocProvider<BudgetCubit>.value(value: budgetCubit),
          BlocProvider<DashboardCubit>.value(value: dashboardCubit),
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore Preview'));
    await tester.pumpAndSettle();

    expect(find.text('finsage-backup-20260428_120000.db'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.download).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    verify(() => backupRepo.restoreFromFile('file-1')).called(1);
    verify(() => txRepo.fetchTransactions()).called(greaterThanOrEqualTo(1));
    verify(() => txRepo.fetchCategories()).called(greaterThanOrEqualTo(1));
    verify(() => budgetRepo.fetchBudgets()).called(greaterThanOrEqualTo(1));
    verify(() => txRepo.monthlySummary()).called(greaterThanOrEqualTo(1));
  });

  testWidgets('settings restore should show invalid backup message', (tester) async {
    final txRepo = MockTransactionRepository();
    final budgetRepo = MockBudgetRepository();
    final backupRepo = MockBackupRepository();
    final settingsStorage = MockSettingsStorage();
    final localDb = MockLocalDatabaseDataSource();
    final notificationService = MockBudgetNotificationService();
    final telemetryStorage = MockAutoBackupTelemetryStorage();
    final validationScheduler = MockAutoBackupValidationScheduler();

    final txCubit = TransactionCubit(txRepo);
    final budgetCubit = BudgetCubit(budgetRepo, notificationService, settingsStorage);
    final dashboardCubit = DashboardCubit(txRepo);
    final settingsCubit =
        SettingsCubit(backupRepo, settingsStorage, localDb, telemetryStorage, validationScheduler);

    addTearDown(txCubit.close);
    addTearDown(budgetCubit.close);
    addTearDown(dashboardCubit.close);
    addTearDown(settingsCubit.close);

    when(() => txRepo.fetchCategories()).thenAnswer(
      (_) async => const [CategoryModel(id: 1, name: 'General', colorHex: '#0D3B66', icon: 'wallet')],
    );
    when(() => txRepo.fetchTransactions()).thenAnswer((_) async => []);
    when(() => txRepo.monthlySummary()).thenAnswer((_) async => {'income': 0, 'expense': 0});

    when(() => budgetRepo.fetchBudgets()).thenAnswer((_) async => []);
    when(() => settingsStorage.loadNotificationsEnabled()).thenAnswer((_) async => true);

    when(() => settingsStorage.loadThemeMode()).thenAnswer((_) async => ThemeMode.system);
    when(() => settingsStorage.loadLocale()).thenAnswer((_) async => null);
    when(() => settingsStorage.loadLastBackupAt()).thenAnswer((_) async => null);
    when(() => telemetryStorage.loadTelemetry()).thenAnswer((_) async => const AutoBackupTelemetry());
    when(() => validationScheduler.scheduleValidationNow()).thenAnswer((_) async {});

    when(() => backupRepo.restorePreview()).thenAnswer(
      (_) async => const [
        BackupFileModel(
          id: 'file-1',
          name: 'finsage-backup-20260428_120000.db',
          createdAt: null,
          size: 1024,
        ),
      ],
    );
    when(() => backupRepo.restoreFromFile('file-1')).thenThrow(
      const AppException('Backup file invalid or corrupted', code: AppErrorCodes.backupInvalidFile),
    );

    await settingsCubit.loadSettings();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TransactionCubit>.value(value: txCubit),
          BlocProvider<BudgetCubit>.value(value: budgetCubit),
          BlocProvider<DashboardCubit>.value(value: dashboardCubit),
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore Preview'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.download).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(find.text('Backup file is invalid or corrupted'), findsOneWidget);
  });

  testWidgets('settings backup should show localized google auth unavailable error', (tester) async {
    final txRepo = MockTransactionRepository();
    final budgetRepo = MockBudgetRepository();
    final backupRepo = MockBackupRepository();
    final settingsStorage = MockSettingsStorage();
    final localDb = MockLocalDatabaseDataSource();
    final notificationService = MockBudgetNotificationService();
    final telemetryStorage = MockAutoBackupTelemetryStorage();
    final validationScheduler = MockAutoBackupValidationScheduler();

    final txCubit = TransactionCubit(txRepo);
    final budgetCubit = BudgetCubit(budgetRepo, notificationService, settingsStorage);
    final dashboardCubit = DashboardCubit(txRepo);
    final settingsCubit =
        SettingsCubit(backupRepo, settingsStorage, localDb, telemetryStorage, validationScheduler);

    addTearDown(txCubit.close);
    addTearDown(budgetCubit.close);
    addTearDown(dashboardCubit.close);
    addTearDown(settingsCubit.close);

    when(() => txRepo.fetchCategories()).thenAnswer(
      (_) async => const [CategoryModel(id: 1, name: 'General', colorHex: '#0D3B66', icon: 'wallet')],
    );
    when(() => txRepo.fetchTransactions()).thenAnswer((_) async => []);
    when(() => txRepo.monthlySummary()).thenAnswer((_) async => {'income': 0, 'expense': 0});
    when(() => budgetRepo.fetchBudgets()).thenAnswer((_) async => []);
    when(() => settingsStorage.loadNotificationsEnabled()).thenAnswer((_) async => true);
    when(() => settingsStorage.loadThemeMode()).thenAnswer((_) async => ThemeMode.system);
    when(() => settingsStorage.loadLocale()).thenAnswer((_) async => null);
    when(() => settingsStorage.loadLastBackupAt()).thenAnswer((_) async => null);
    when(() => telemetryStorage.loadTelemetry()).thenAnswer((_) async => const AutoBackupTelemetry());
    when(() => validationScheduler.scheduleValidationNow()).thenAnswer((_) async {});
    when(() => backupRepo.backupNow()).thenThrow(
      const AppException(
        'Google auth headers unavailable',
        code: AppErrorCodes.googleAuthHeadersUnavailable,
      ),
    );

    await settingsCubit.loadSettings();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TransactionCubit>.value(value: txCubit),
          BlocProvider<BudgetCubit>.value(value: budgetCubit),
          BlocProvider<DashboardCubit>.value(value: dashboardCubit),
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Backup Now'));
    await tester.pumpAndSettle();

    expect(find.text('Google authentication is unavailable. Please sign in again and retry.'), findsOneWidget);
  });

  testWidgets('reports page should show localized no-data export error', (tester) async {
    final txRepo = MockTransactionRepository();
    final txCubit = TransactionCubit(txRepo);
    final reportCubit = ReportCubit();
    addTearDown(txCubit.close);
    addTearDown(reportCubit.close);

    when(() => txRepo.fetchTransactions()).thenAnswer((_) async => []);
    when(() => txRepo.fetchCategories()).thenAnswer((_) async => const []);
    await txCubit.loadTransactions();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TransactionCubit>.value(value: txCubit),
          BlocProvider<ReportCubit>.value(value: reportCubit),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ReportsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Export PDF'));
    await tester.pumpAndSettle();

    expect(find.text('No data to export'), findsOneWidget);
  });

  testWidgets('settings page should show app info card', (tester) async {
    final txRepo = MockTransactionRepository();
    final budgetRepo = MockBudgetRepository();
    final backupRepo = MockBackupRepository();
    final settingsStorage = MockSettingsStorage();
    final localDb = MockLocalDatabaseDataSource();
    final notificationService = MockBudgetNotificationService();
    final telemetryStorage = MockAutoBackupTelemetryStorage();
    final validationScheduler = MockAutoBackupValidationScheduler();

    final txCubit = TransactionCubit(txRepo);
    final budgetCubit = BudgetCubit(budgetRepo, notificationService, settingsStorage);
    final dashboardCubit = DashboardCubit(txRepo);
    final settingsCubit =
        SettingsCubit(backupRepo, settingsStorage, localDb, telemetryStorage, validationScheduler);

    addTearDown(txCubit.close);
    addTearDown(budgetCubit.close);
    addTearDown(dashboardCubit.close);
    addTearDown(settingsCubit.close);

    when(() => txRepo.fetchCategories()).thenAnswer((_) async => const []);
    when(() => txRepo.fetchTransactions()).thenAnswer((_) async => const []);
    when(() => txRepo.monthlySummary()).thenAnswer((_) async => {'income': 0, 'expense': 0});
    when(() => budgetRepo.fetchBudgets()).thenAnswer((_) async => const []);
    when(() => settingsStorage.loadNotificationsEnabled()).thenAnswer((_) async => true);
    when(() => settingsStorage.loadThemeMode()).thenAnswer((_) async => ThemeMode.system);
    when(() => settingsStorage.loadLocale()).thenAnswer((_) async => null);
    when(() => settingsStorage.loadLastBackupAt()).thenAnswer((_) async => null);
    when(() => telemetryStorage.loadTelemetry()).thenAnswer((_) async => const AutoBackupTelemetry());
    when(() => validationScheduler.scheduleValidationNow()).thenAnswer((_) async {});

    await settingsCubit.loadSettings();

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TransactionCubit>.value(value: txCubit),
          BlocProvider<BudgetCubit>.value(value: budgetCubit),
          BlocProvider<DashboardCubit>.value(value: dashboardCubit),
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('App Info'), findsOneWidget);
    expect(find.text('Version: ${AppConstants.appVersion}'), findsOneWidget);
  });
}
