import 'package:crypto/crypto.dart';
import 'package:fin_sage/core/utils/app_event_logger.dart';
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
  static const int _maxBackupFiles = 30;

  @override
  Future<void> backupNow() async {
    AppEventLogger.info('backup.manual.started');
    final bytes = await _local.databaseBytes();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now().toUtc());
    final backupFilename = 'finsage-backup-$timestamp.db';
    await _remote.uploadBackup(bytes, backupFilename);
    AppEventLogger.info(
      'backup.manual.uploaded',
      data: {
        'filename': backupFilename,
        'size_bytes': bytes.length,
      },
    );
    final checksum = _sha256Hex(bytes);
    try {
      await _remote.uploadBackupChecksum('$backupFilename.sha256', checksum);
      AppEventLogger.info(
        'backup.manual.checksum_uploaded',
        data: {'filename': '$backupFilename.sha256'},
      );
    } catch (_) {
      AppEventLogger.warning(
        'backup.manual.checksum_upload_failed',
        data: {'filename': '$backupFilename.sha256'},
      );
      // Keep backup successful even when sidecar checksum upload fails.
    }
    await _cleanupOldBackupsBestEffort();
    AppEventLogger.info('backup.manual.completed');
  }

  @override
  Future<List<BackupFileModel>> restorePreview() async {
    final files = await _remote.listBackups();
    final mapped = files
        .where((e) => e.id != null && e.id!.isNotEmpty && _isDatabaseBackupName(e.name))
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

  bool _isDatabaseBackupName(String? name) {
    if (name == null || name.isEmpty) {
      return false;
    }
    return name.startsWith('finsage-backup-') && name.endsWith('.db');
  }

  String _sha256Hex(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }

  Future<String?> _expectedChecksumForFileId(String fileId) async {
    try {
      final metadata = await _remote.getBackupMetadata(fileId);
      final backupName = metadata.name;
      if (!_isDatabaseBackupName(backupName)) {
        return null;
      }
      final checksumFilename = '$backupName.sha256';
      return _remote.downloadBackupChecksumByName(checksumFilename);
    } catch (_) {
      AppEventLogger.warning(
        'backup.restore.checksum_lookup_skipped',
        data: {'file_id': fileId},
      );
      return null;
    }
  }

  Future<void> _cleanupOldBackupsBestEffort() async {
    try {
      final files = await _remote.listBackups();
      final fileIdByName = <String, String>{
        for (final file in files)
          if (file.id != null && file.id!.isNotEmpty && file.name != null && file.name!.isNotEmpty)
            file.name!: file.id!,
      };
      final candidates = files
          .where((file) => file.id != null && file.id!.isNotEmpty && _isDatabaseBackupName(file.name))
          .toList();
      candidates.sort((a, b) {
        final aTime = a.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      if (candidates.length <= _maxBackupFiles) {
        AppEventLogger.info(
          'backup.cleanup.skipped',
          data: {'count': candidates.length},
        );
        return;
      }

      var deletedCount = 0;
      var deletedChecksumCount = 0;
      for (final file in candidates.skip(_maxBackupFiles)) {
        try {
          await _remote.deleteBackup(file.id!);
          deletedCount += 1;
        } catch (_) {
          AppEventLogger.warning(
            'backup.cleanup.delete_failed',
            data: {'file_id': file.id},
          );
          // Best-effort cleanup should never fail user-triggered backup.
        }

        final checksumName = '${file.name}.sha256';
        final checksumId = fileIdByName[checksumName];
        if (checksumId == null || checksumId.isEmpty) {
          continue;
        }
        try {
          await _remote.deleteBackup(checksumId);
          deletedChecksumCount += 1;
        } catch (_) {
          AppEventLogger.warning(
            'backup.cleanup.delete_checksum_failed',
            data: {'file_id': checksumId, 'checksum_name': checksumName},
          );
        }
      }
      AppEventLogger.info(
        'backup.cleanup.completed',
        data: {
          'deleted_count': deletedCount,
          'deleted_checksum_count': deletedChecksumCount,
          'retained_count': _maxBackupFiles,
        },
      );
    } catch (_) {
      AppEventLogger.warning('backup.cleanup.failed_to_list');
      // Best-effort cleanup should never fail user-triggered backup.
    }
  }

  @override
  Future<void> restoreFromFile(String fileId) async {
    AppEventLogger.info('backup.restore.started', data: {'file_id': fileId});
    final bytes = await _remote.downloadBackup(fileId);
    if (!BackupFileValidator.isLikelyValidDatabaseBackup(bytes)) {
      AppEventLogger.error(
        'backup.restore.invalid_file',
        data: {'file_id': fileId, 'size_bytes': bytes.length},
      );
      throw const AppException(
        'Backup file invalid or corrupted',
        code: 'backup_invalid_file',
      );
    }
    final expectedChecksum = await _expectedChecksumForFileId(fileId);
    if (expectedChecksum != null && expectedChecksum.isNotEmpty) {
      final actualChecksum = _sha256Hex(bytes);
      if (actualChecksum.toLowerCase() != expectedChecksum.toLowerCase()) {
        AppEventLogger.error(
          'backup.restore.checksum_mismatch',
          data: {
            'file_id': fileId,
            'expected_checksum': expectedChecksum,
            'actual_checksum': actualChecksum,
          },
        );
        throw const AppException(
          'Backup checksum mismatch',
          code: 'backup_checksum_mismatch',
        );
      }
      AppEventLogger.info('backup.restore.checksum_verified', data: {'file_id': fileId});
    }
    await _local.replaceDatabaseFile(bytes);
    AppEventLogger.info(
      'backup.restore.completed',
      data: {'file_id': fileId, 'size_bytes': bytes.length},
    );
  }
}
