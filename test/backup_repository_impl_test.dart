import 'package:crypto/crypto.dart';
import 'package:fin_sage/core/errors/app_error_codes.dart';
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
    final bytes = List<int>.generate(1024, (i) => i % 255);
    when(() => local.databaseBytes()).thenAnswer((_) async => bytes);
    when(() => remote.uploadBackup(bytes, any())).thenAnswer((_) async {});
    when(() => remote.uploadBackupChecksum(any(), any())).thenAnswer((_) async {});
    when(() => remote.listBackups()).thenAnswer((_) async => []);

    await repository.backupNow();

    final captured = verify(() => remote.uploadBackup(bytes, captureAny())).captured.single as String;
    expect(captured, matches(RegExp(r'^finsage-backup-\d{8}_\d{6}\.db$')));
    verify(() => remote.uploadBackupChecksum('$captured.sha256', sha256.convert(bytes).toString())).called(1);
  });

  test('backupNow removes old backups beyond retention limit', () async {
    final bytes = List<int>.generate(1024, (i) => i % 255);
    when(() => local.databaseBytes()).thenAnswer((_) async => bytes);
    when(() => remote.uploadBackup(bytes, any())).thenAnswer((_) async {});
    when(() => remote.uploadBackupChecksum(any(), any())).thenAnswer((_) async {});

    final files = <drive.File>[];
    for (var index = 0; index < 32; index++) {
      final dbName = 'finsage-backup-20260401_${(100000 + index).toString()}.db';
      files.add(
        drive.File()
          ..id = 'file-$index'
          ..name = dbName
          ..createdTime = DateTime(2026, 4, 1).add(Duration(minutes: index)),
      );
      files.add(
        drive.File()
          ..id = 'checksum-$index'
          ..name = '$dbName.sha256'
          ..createdTime = DateTime(2026, 4, 1).add(Duration(minutes: index)),
      );
    }
    when(() => remote.listBackups()).thenAnswer((_) async => files);
    when(() => remote.deleteBackup(any())).thenAnswer((_) async {});

    await repository.backupNow();

    verify(() => remote.deleteBackup('file-1')).called(1);
    verify(() => remote.deleteBackup('file-0')).called(1);
    verify(() => remote.deleteBackup('checksum-1')).called(1);
    verify(() => remote.deleteBackup('checksum-0')).called(1);
  });

  test('backupNow should still succeed when cleanup listing fails', () async {
    final bytes = List<int>.generate(1024, (i) => i % 255);
    when(() => local.databaseBytes()).thenAnswer((_) async => bytes);
    when(() => remote.uploadBackup(bytes, any())).thenAnswer((_) async {});
    when(() => remote.uploadBackupChecksum(any(), any())).thenAnswer((_) async {});
    when(() => remote.listBackups()).thenThrow(Exception('drive unavailable'));

    await repository.backupNow();

    verify(() => remote.uploadBackup(bytes, any())).called(1);
  });

  test('restorePreview filters invalid ids and sorts by newest createdAt', () async {
    final oldFile = drive.File()
      ..id = 'old'
      ..name = 'finsage-backup-20260102_120000.db'
      ..createdTime = DateTime(2026, 1, 2);
    final newFile = drive.File()
      ..id = 'new'
      ..name = 'finsage-backup-20260402_120000.db'
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
    when(() => remote.getBackupMetadata('file-1')).thenAnswer(
      (_) async => drive.File()
        ..id = 'file-1'
        ..name = 'finsage-backup-20260401_120000.db',
    );
    when(() => remote.downloadBackupChecksumByName('finsage-backup-20260401_120000.db.sha256'))
        .thenAnswer((_) async => sha256.convert(validBytes).toString());
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
        isA<AppException>().having((e) => e.code, 'code', AppErrorCodes.backupInvalidFile),
      ),
    );
    verifyNever(() => local.replaceDatabaseFile(any()));
  });

  test('restoreFromFile throws when checksum does not match', () async {
    final validBytes = List<int>.generate(1024, (i) => i % 255);
    when(() => remote.downloadBackup('file-1')).thenAnswer((_) async => validBytes);
    when(() => remote.getBackupMetadata('file-1')).thenAnswer(
      (_) async => drive.File()
        ..id = 'file-1'
        ..name = 'finsage-backup-20260401_120000.db',
    );
    when(() => remote.downloadBackupChecksumByName('finsage-backup-20260401_120000.db.sha256'))
        .thenAnswer((_) async => '0000');

    expect(
      () => repository.restoreFromFile('file-1'),
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', AppErrorCodes.backupChecksumMismatch),
      ),
    );
    verifyNever(() => local.replaceDatabaseFile(any()));
  });

  test('restoreFromFile should continue when checksum metadata cannot be loaded', () async {
    final validBytes = List<int>.generate(1024, (i) => i % 255);
    when(() => remote.downloadBackup('file-1')).thenAnswer((_) async => validBytes);
    when(() => remote.getBackupMetadata('file-1')).thenThrow(Exception('metadata unavailable'));
    when(() => local.replaceDatabaseFile(validBytes)).thenAnswer((_) async {});

    await repository.restoreFromFile('file-1');

    verify(() => local.replaceDatabaseFile(validBytes)).called(1);
  });
}
