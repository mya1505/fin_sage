import 'package:fin_sage/core/errors/app_error_codes.dart';
import 'package:fin_sage/l10n/generated/app_localizations.dart';

String localizeErrorMessage(AppLocalizations l10n, String rawMessage) {
  return switch (rawMessage) {
    AppErrorCodes.categoryAlreadyExists => l10n.categoryExists,
    AppErrorCodes.categoryInUse => l10n.categoryInUse,
    AppErrorCodes.defaultCategoryArchiveBlocked => l10n.defaultCategoryArchiveBlocked,
    AppErrorCodes.backupInvalidFile => l10n.backupInvalidFile,
    AppErrorCodes.backupChecksumMismatch => l10n.backupChecksumMismatch,
    AppErrorCodes.googleAuthHeadersUnavailable => l10n.googleAuthUnavailable,
    AppErrorCodes.noDataToExport => l10n.noDataToExport,
    _ => rawMessage,
  };
}
