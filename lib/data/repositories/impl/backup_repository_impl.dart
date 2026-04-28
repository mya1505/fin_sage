import 'package:fin_sage/core/errors/app_exception.dart';
import 'package:fin_sage/data/datasources/local/local_database_datasource.dart';
import 'package:fin_sage/data/datasources/remote/google_drive_datasource.dart';
import 'package:fin_sage/data/models/backup_file_model.dart';
import 'package:fin_sage/core/utils/backup_file_validator.dart';
import 'package:fin_sage/data/repositories/backup_repository.dart';
import 'package:intl/intl.dart';

class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl(this._local, this._remote);

  final LocalDatabaseDataSource _local;
  final GoogleDriveDataSource _remote;

  @override
  Future<void> backupNow() async {
    final bytes = await _local.databaseBytes();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now().toUtc());
    await _remote.uploadBackup(bytes, 'finsage-backup-$timestamp.db');
  }

  @override
  Future<List<BackupFileModel>> restorePreview() async {
    final files = await _remote.listBackups();
    final mapped = files
        .where((e) => e.id != null && e.id!.isNotEmpty)
        .map(
          (e) => BackupFileModel(
            id: e.id!,
            name: e.name ?? 'backup.db',
            createdAt: e.createdTime,
            size: _parseSize(e.size),
          ),
        )
        .toList();
    mapped.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return mapped;
  }

  int _parseSize(Object? rawSize) {
    if (rawSize == null) {
      return 0;
    }
    if (rawSize is int) {
      return rawSize;
    }
    if (rawSize is num) {
      return rawSize.toInt();
    }
    if (rawSize is String) {
      return int.tryParse(rawSize) ?? 0;
    }
    return 0;
  }

  @override
  Future<void> restoreFromFile(String fileId) async {
    final bytes = await _remote.downloadBackup(fileId);
    if (!BackupFileValidator.isLikelyValidDatabaseBackup(bytes)) {
      throw const AppException(
        'Backup file invalid or corrupted',
        code: 'backup_invalid_file',
      );
    }
    await _local.replaceDatabaseFile(bytes);
  }
}
