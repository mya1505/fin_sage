import 'package:fin_sage/data/datasources/local/auto_backup_telemetry_storage.dart';
import 'package:fin_sage/data/datasources/local/local_database_datasource.dart';
import 'package:fin_sage/data/datasources/local/settings_storage.dart';
import 'package:fin_sage/data/models/backup_file_model.dart';
import 'package:fin_sage/data/models/category_model.dart';
import 'package:fin_sage/data/models/transaction_model.dart';
import 'package:fin_sage/data/repositories/backup_repository.dart';
import 'package:fin_sage/data/repositories/transaction_repository.dart';
import 'package:fin_sage/logic/settings/settings_cubit.dart';
import 'package:fin_sage/logic/transactions/transaction_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockBackupRepository extends Mock implements BackupRepository {}

class MockSettingsStorage extends Mock implements SettingsStorage {}

class MockLocalDatabaseDataSource extends Mock implements LocalDatabaseDataSource {}
class MockAutoBackupTelemetryStorage extends Mock implements AutoBackupTelemetryStorage {}

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
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  testWidgets('transaction flow integration: load and create', (tester) async {
    final repository = MockTransactionRepository();
    final cubit = TransactionCubit(repository);
    addTearDown(cubit.close);

    const categories = [
      CategoryModel(id: 1, name: 'General', colorHex: '#0D3B66', icon: 'wallet'),
    ];

    var transactions = <TransactionModel>[
      TransactionModel(
        id: 1,
        title: 'Lunch',
        amount: 45000,
        date: DateTime(2026, 4, 1),
        categoryId: 1,
        type: TransactionType.expense,
      ),
    ];

    when(() => repository.fetchCategories()).thenAnswer((_) async => categories);
    when(() => repository.fetchTransactions()).thenAnswer((_) async => transactions);
    when(() => repository.saveTransaction(any())).thenAnswer((invocation) async {
      final tx = invocation.positionalArguments.first as TransactionModel;
      transactions = [
        ...transactions,
        TransactionModel(
          id: 2,
          title: tx.title,
          amount: tx.amount,
          date: tx.date,
          categoryId: tx.categoryId,
          type: tx.type,
        ),
      ];
    });

    await cubit.loadTransactions();
    expect(cubit.state.items.length, 1);
    expect(cubit.state.categories.length, 1);

    await cubit.createTransaction(
      TransactionModel(
        id: null,
        title: 'Salary',
        amount: 5000000,
        date: DateTime(2026, 4, 2),
        categoryId: 1,
        type: TransactionType.income,
      ),
    );

    verify(() => repository.saveTransaction(any())).called(1);
    expect(cubit.state.items.length, 2);
    expect(cubit.state.items.any((it) => it.title == 'Salary'), isTrue);
  });

  testWidgets('backup flow integration: backup and preview restore', (tester) async {
    final backupRepository = MockBackupRepository();
    final storage = MockSettingsStorage();
    final localDatabase = MockLocalDatabaseDataSource();
    final telemetry = MockAutoBackupTelemetryStorage();
    final cubit = SettingsCubit(backupRepository, storage, localDatabase, telemetry);
    addTearDown(cubit.close);

    when(() => storage.loadThemeMode()).thenAnswer((_) async => ThemeMode.system);
    when(() => storage.loadLocale()).thenAnswer((_) async => null);
    when(() => storage.loadNotificationsEnabled()).thenAnswer((_) async => true);
    when(() => storage.loadLastBackupAt()).thenAnswer((_) async => null);
    when(() => storage.saveLastBackupAt(any())).thenAnswer((_) async {});
    when(() => telemetry.loadTelemetry()).thenAnswer((_) async => const AutoBackupTelemetry());

    const preview = [
      BackupFileModel(
        id: 'file-1',
        name: 'finsage_backup_2026_04_28.db',
        createdAt: null,
        size: 2048,
      ),
    ];
    when(() => backupRepository.backupNow()).thenAnswer((_) async {});
    when(() => backupRepository.restorePreview()).thenAnswer((_) async => preview);
    when(() => backupRepository.restoreFromFile('file-1')).thenAnswer((_) async {});

    await cubit.loadSettings();
    await cubit.backupNow();
    await cubit.loadRestorePreview();
    await cubit.restoreByFileId('file-1');

    verify(() => backupRepository.backupNow()).called(1);
    verify(() => backupRepository.restorePreview()).called(1);
    verify(() => backupRepository.restoreFromFile('file-1')).called(1);
    expect(cubit.state.lastBackupAt, isNotNull);
    expect(cubit.state.restorePreview, preview);
    expect(cubit.state.lastCompletedOperation, SettingsOperation.restore);
  });
}
