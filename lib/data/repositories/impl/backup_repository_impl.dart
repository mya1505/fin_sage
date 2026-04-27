import 'package:fin_sage/data/datasources/local/local_database_datasource.dart';
import 'package:fin_sage/data/datasources/remote/google_drive_datasource.dart';
import 'package:fin_sage/data/repositories/backup_repository.dart';

class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(this._local, this._remote);

  final LocalDatabaseDataSource _local;
  final GoogleDriveDataSource _remote;

  @override
  Future<void> backupNow() async {
    final bytes = await _local.databaseBytes();
    final timestamp = DateTime.now().toIso8601String();
    await _remote.uploadBackup(bytes, 'finsage-backup-$timestamp.db');
  }

  @override
  Future<List<String>> restorePreview() async {
    final files = await _remote.listBackups();
    return files
        .map((e) => '${e.id ?? ''}|${e.name ?? ''}|${e.createdTime?.toIso8601String() ?? ''}|${e.size ?? 0}')
        .toList();
  }

  @override
  Future<void> restoreFromFile(String fileId) async {
    final bytes = await _remote.downloadBackup(fileId);
    await _local.replaceDatabaseFile(bytes);
  }
}
