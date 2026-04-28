import 'package:fin_sage/data/datasources/local/local_database_datasource.dart';
import 'package:fin_sage/data/datasources/remote/google_drive_datasource.dart';
import 'package:fin_sage/data/repositories/impl/backup_repository_impl.dart';
import 'package:fin_sage/core/errors/app_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:mocktail/mocktail.dart';

class MockLocalDatabaseDataSource extends Mock implements LocalDatabaseDataSource {}

class MockGoogleDriveDataSource extends Mock implements GoogleDriveDataSource {}

void main() {
  late MockLocalDatabaseDataSource local;
  late MockGoogleDriveDataSource remote;
  late BackupRepositoryImpl repository;

  setUp(() {
    local = MockLocalDatabaseDataSource();
    remote = MockGoogleDriveDataSource();
    repository = BackupRepositoryImpl(local, remote);
  });

  test('backupNow uploads database bytes with normalized filename', () async {
    when(() => local.databaseBytes()).thenAnswer((_) async => [1, 2, 3]);
    when(() => remote.uploadBackup([1, 2, 3], any())).thenAnswer((_) async {});
    when(() => remote.listBackups()).thenAnswer((_) async => []);

    await repository.backupNow();

    final captured = verify(() => remote.uploadBackup([1, 2, 3], captureAny())).captured.single as String;
    expect(captured, matches(RegExp(r'^finsage-backup-\d{8}_\d{6}\.db$')));
  });

  test('backupNow removes old backups beyond retention limit', () async {
    when(() => local.databaseBytes()).thenAnswer((_) async => [1, 2, 3]);
    when(() => remote.uploadBackup([1, 2, 3], any())).thenAnswer((_) async {});

    final files = List<drive.File>.generate(32, (index) {
      return drive.File()
        ..id = 'file-$index'
        ..name = 'finsage-backup-$index.db'
        ..createdTime = DateTime(2026, 4, 1).add(Duration(minutes: index));
    });
    when(() => remote.listBackups()).thenAnswer((_) async => files);
    when(() => remote.deleteBackup(any())).thenAnswer((_) async {});

    await repository.backupNow();

    verify(() => remote.deleteBackup('file-1')).called(1);
    verify(() => remote.deleteBackup('file-0')).called(1);
  });

  test('backupNow should still succeed when cleanup listing fails', () async {
    when(() => local.databaseBytes()).thenAnswer((_) async => [1, 2, 3]);
    when(() => remote.uploadBackup([1, 2, 3], any())).thenAnswer((_) async {});
    when(() => remote.listBackups()).thenThrow(Exception('drive unavailable'));

    await repository.backupNow();

    verify(() => remote.uploadBackup([1, 2, 3], any())).called(1);
  });

  test('restorePreview filters invalid ids and sorts by newest createdAt', () async {
    final oldFile = drive.File()
      ..id = 'old'
      ..name = 'old.db'
      ..createdTime = DateTime(2026, 1, 2);
    final newFile = drive.File()
      ..id = 'new'
      ..name = 'new.db'
      ..createdTime = DateTime(2026, 4, 2);
    final invalidFile = drive.File()
      ..id = ''
      ..name = 'invalid.db';

    when(() => remote.listBackups()).thenAnswer((_) async => [oldFile, invalidFile, newFile]);

    final preview = await repository.restorePreview();

    expect(preview.length, 2);
    expect(preview.first.id, 'new');
    expect(preview.last.id, 'old');
  });

  test('restoreFromFile downloads bytes and replaces local database file', () async {
    final validBytes = List<int>.generate(1024, (i) => i % 255);
    when(() => remote.downloadBackup('file-1')).thenAnswer((_) async => validBytes);
    when(() => local.replaceDatabaseFile(validBytes)).thenAnswer((_) async {});

    await repository.restoreFromFile('file-1');

    verify(() => remote.downloadBackup('file-1')).called(1);
    verify(() => local.replaceDatabaseFile(validBytes)).called(1);
  });

  test('restoreFromFile throws when backup file is invalid', () async {
    when(() => remote.downloadBackup('file-1')).thenAnswer((_) async => [1, 2, 3]);

    expect(
      () => repository.restoreFromFile('file-1'),
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', 'backup_invalid_file'),
      ),
    );
    verifyNever(() => local.replaceDatabaseFile(any()));
  });
}
