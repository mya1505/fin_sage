import 'dart:async';

import 'package:fin_sage/data/datasources/local/auto_backup_telemetry_storage.dart';
import 'package:fin_sage/data/datasources/local/local_database_datasource.dart';
import 'package:fin_sage/data/datasources/local/settings_storage.dart';
import 'package:fin_sage/data/repositories/backup_repository.dart';
import 'package:fin_sage/logic/settings/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBackupRepository extends Mock implements BackupRepository {}
class MockSettingsStorage extends Mock implements SettingsStorage {}
class MockLocalDatabaseDataSource extends Mock implements LocalDatabaseDataSource {}
class MockAutoBackupTelemetryStorage extends Mock implements AutoBackupTelemetryStorage {}

void main() {
  late MockBackupRepository repo;
  late MockSettingsStorage storage;
  late MockLocalDatabaseDataSource localDb;
  late MockAutoBackupTelemetryStorage telemetryStorage;
  late SettingsCubit cubit;

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  setUp(() {
    repo = MockBackupRepository();
    storage = MockSettingsStorage();
    localDb = MockLocalDatabaseDataSource();
    telemetryStorage = MockAutoBackupTelemetryStorage();
    cubit = SettingsCubit(repo, storage, localDb, telemetryStorage);

    when(() => storage.loadThemeMode()).thenAnswer((_) async => ThemeMode.system);
    when(() => storage.loadLocale()).thenAnswer((_) async => null);
    when(() => storage.loadNotificationsEnabled()).thenAnswer((_) async => true);
    when(() => storage.loadLastBackupAt()).thenAnswer((_) async => null);
    when(() => telemetryStorage.loadTelemetry()).thenAnswer((_) async => const AutoBackupTelemetry());
  });

  tearDown(() async {
    await cubit.close();
  });

  test('backupNow should toggle loading state', () async {
    when(() => repo.backupNow()).thenAnswer((_) async {});
    when(() => storage.saveLastBackupAt(any())).thenAnswer((_) async {});

    await cubit.backupNow();

    expect(cubit.state.backupInProgress, false);
    expect(cubit.state.lastBackupAt, isNotNull);
    verify(() => repo.backupNow()).called(1);
    verify(() => storage.saveLastBackupAt(any())).called(1);
  });

  test('backupNow should ignore concurrent request while running', () async {
    final completer = Completer<void>();
    when(() => repo.backupNow()).thenAnswer((_) => completer.future);
    when(() => storage.saveLastBackupAt(any())).thenAnswer((_) async {});

    unawaited(cubit.backupNow());
    await Future<void>.delayed(Duration.zero);
    await cubit.backupNow();

    verify(() => repo.backupNow()).called(1);

    completer.complete();
    await Future<void>.delayed(Duration.zero);
  });

  test('loadSettings should apply saved theme, locale, and notification setting', () async {
    when(() => storage.loadThemeMode()).thenAnswer((_) async => ThemeMode.dark);
    when(() => storage.loadLocale()).thenAnswer((_) async => const Locale('id'));
    when(() => storage.loadNotificationsEnabled()).thenAnswer((_) async => false);
    when(() => storage.loadLastBackupAt()).thenAnswer((_) async => DateTime(2026, 4, 1));

    await cubit.loadSettings();

    expect(cubit.state.themeMode, ThemeMode.dark);
    expect(cubit.state.locale, const Locale('id'));
    expect(cubit.state.notificationsEnabled, false);
    expect(cubit.state.lastBackupAt, DateTime(2026, 4, 1));
  });

  test('setThemeMode should persist mode', () async {
    when(() => storage.saveThemeMode(ThemeMode.light)).thenAnswer((_) async {});

    await cubit.setThemeMode(ThemeMode.light);

    expect(cubit.state.themeMode, ThemeMode.light);
    verify(() => storage.saveThemeMode(ThemeMode.light)).called(1);
  });

  test('setLocale should persist and clear locale', () async {
    when(() => storage.saveLocale(const Locale('en'))).thenAnswer((_) async {});
    when(() => storage.saveLocale(null)).thenAnswer((_) async {});

    await cubit.setLocale(const Locale('en'));
    expect(cubit.state.locale, const Locale('en'));
    verify(() => storage.saveLocale(const Locale('en'))).called(1);

    await cubit.setLocale(null);
    expect(cubit.state.locale, isNull);
    verify(() => storage.saveLocale(null)).called(1);
  });

  test('setNotificationsEnabled should persist notifications preference', () async {
    when(() => storage.saveNotificationsEnabled(false)).thenAnswer((_) async {});

    await cubit.setNotificationsEnabled(false);

    expect(cubit.state.notificationsEnabled, false);
    verify(() => storage.saveNotificationsEnabled(false)).called(1);
  });

  test('resetLocalData should clear local db and emit reset operation', () async {
    when(() => localDb.resetLocalData()).thenAnswer((_) async {});

    await cubit.resetLocalData();

    expect(cubit.state.backupInProgress, false);
    expect(cubit.state.lastCompletedOperation, SettingsOperation.reset);
    verify(() => localDb.resetLocalData()).called(1);
  });
}
