class BackupFileValidator {
  static const int _minimumSafeBytes = 512;

  static bool isLikelyValidDatabaseBackup(List<int> bytes) {
    if (bytes.length < _minimumSafeBytes) {
      return false;
    }

    final sample = bytes.take(128).toList(growable: false);

    // Guard against common API/text payloads accidentally saved as backup.
    final visible = sample.where((b) => b >= 32 && b <= 126).toList(growable: false);
    if (visible.length > 100) {
      final text = String.fromCharCodes(visible).toLowerCase();
      if (text.contains('<html') || text.contains('{"error"') || text.contains('doctype html')) {
        return false;
      }
    }

    return true;
  }
}
