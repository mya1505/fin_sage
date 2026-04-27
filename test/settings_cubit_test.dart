import 'package:fin_sage/data/datasources/local/settings_storage.dart';
import 'package:fin_sage/data/repositories/backup_repository.dart';
import 'package:fin_sage/logic/settings/settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBackupRepository extends Mock implements BackupRepository {}
class MockSettingsStorage extends Mock implements SettingsStorage {}

void main() {
  late MockBackupRepository repo;
  late MockSettingsStorage storage;
  late SettingsCubit cubit;

  setUp(() {
    repo = MockBackupRepository();
    storage = MockSettingsStorage();
    cubit = SettingsCubit(repo, storage);

    when(() => storage.loadThemeMode()).thenAnswer((_) async => ThemeMode.system);
    when(() => storage.loadLocale()).thenAnswer((_) async => null);
  });

  tearDown(() async {
    await cubit.close();
  });

  test('backupNow should toggle loading state', () async {
    when(() => repo.backupNow()).thenAnswer((_) async {});

    await cubit.backupNow();

    expect(cubit.state.backupInProgress, false);
    verify(() => repo.backupNow()).called(1);
  });

  test('loadSettings should apply saved theme and locale', () async {
    when(() => storage.loadThemeMode()).thenAnswer((_) async => ThemeMode.dark);
    when(() => storage.loadLocale()).thenAnswer((_) async => const Locale('id'));

    await cubit.loadSettings();

    expect(cubit.state.themeMode, ThemeMode.dark);
    expect(cubit.state.locale, const Locale('id'));
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
}
