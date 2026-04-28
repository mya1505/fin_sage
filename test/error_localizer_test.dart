import 'package:fin_sage/core/errors/error_localizer.dart';
import 'package:fin_sage/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10nEn = AppLocalizations(const Locale('en'));
  final l10nId = AppLocalizations(const Locale('id'));

  test('localizeErrorMessage maps known codes', () {
    expect(localizeErrorMessage(l10nEn, 'category_already_exists'), l10nEn.categoryExists);
    expect(localizeErrorMessage(l10nEn, 'backup_invalid_file'), l10nEn.backupInvalidFile);
    expect(localizeErrorMessage(l10nEn, 'google_auth_headers_unavailable'), l10nEn.googleAuthUnavailable);
  });

  test('localizeErrorMessage uses active locale', () {
    expect(localizeErrorMessage(l10nId, 'category_in_use'), l10nId.categoryInUse);
    expect(
      localizeErrorMessage(l10nId, 'default_category_archive_blocked'),
      l10nId.defaultCategoryArchiveBlocked,
    );
  });

  test('localizeErrorMessage returns raw message for unknown codes', () {
    expect(localizeErrorMessage(l10nEn, 'unknown_error_code'), 'unknown_error_code');
    expect(localizeErrorMessage(l10nEn, 'some failure text'), 'some failure text');
  });
}
