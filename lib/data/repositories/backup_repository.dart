import 'package:fin_sage/data/models/backup_file_model.dart';

abstract class BackupRepository {
  Future<void> backupNow();
  Future<List<BackupFileModel>> restorePreview();
  Future<void> restoreFromFile(String fileId);
}
