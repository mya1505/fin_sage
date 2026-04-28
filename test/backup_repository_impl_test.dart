import 'package:fin_sage/data/datasources/local/local_database_datasource.dart';
import 'package:fin_sage/data/datasources/remote/google_drive_datasource.dart';
import 'package:fin_sage/data/repositories/impl/backup_repository_impl.dart';
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

    await repository.backupNow();

    final captured = verify(() => remote.uploadBackup([1, 2, 3], captureAny())).captured.single as String;
    expect(captured, matches(RegExp(r'^finsage-backup-\d{8}_\d{6}\.db$')));
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
    when(() => remote.downloadBackup('file-1')).thenAnswer((_) async => [9, 8, 7]);
    when(() => local.replaceDatabaseFile([9, 8, 7])).thenAnswer((_) async {});

    await repository.restoreFromFile('file-1');

    verify(() => remote.downloadBackup('file-1')).called(1);
    verify(() => local.replaceDatabaseFile([9, 8, 7])).called(1);
  });
}
