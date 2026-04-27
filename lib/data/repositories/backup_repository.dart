abstract class BackupRepository {
  Future<void> backupNow();
  Future<List<String>> restorePreview();
  Future<void> restoreFromFile(String fileId);
}
