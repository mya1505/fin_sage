import 'package:fin_sage/l10n/generated/app_localizations.dart';

String localizeErrorMessage(AppLocalizations l10n, String rawMessage) {
  return switch (rawMessage) {
    'category_already_exists' => l10n.categoryExists,
    'category_in_use' => l10n.categoryInUse,
    'default_category_archive_blocked' => l10n.defaultCategoryArchiveBlocked,
    'backup_invalid_file' => l10n.backupInvalidFile,
    'backup_checksum_mismatch' => l10n.backupChecksumMismatch,
    'google_auth_headers_unavailable' => l10n.googleAuthUnavailable,
    'no_data_to_export' => l10n.noDataToExport,
    _ => rawMessage,
  };
}
