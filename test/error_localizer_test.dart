import 'package:fin_sage/core/errors/app_error_codes.dart';
import 'package:fin_sage/core/errors/error_localizer.dart';
import 'package:fin_sage/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10nEn = AppLocalizations(const Locale('en'));
  final l10nId = AppLocalizations(const Locale('id'));

  test('localizeErrorMessage maps known codes', () {
    expect(localizeErrorMessage(l10nEn, AppErrorCodes.unexpectedError), l10nEn.unexpectedError);
    expect(localizeErrorMessage(l10nEn, AppErrorCodes.categoryAlreadyExists), l10nEn.categoryExists);
    expect(localizeErrorMessage(l10nEn, AppErrorCodes.backupInvalidFile), l10nEn.backupInvalidFile);
    expect(
      localizeErrorMessage(l10nEn, AppErrorCodes.googleAuthHeadersUnavailable),
      l10nEn.googleAuthUnavailable,
    );
    expect(localizeErrorMessage(l10nEn, AppErrorCodes.noDataToExport), l10nEn.noDataToExport);
  });

  test('localizeErrorMessage uses active locale', () {
    expect(localizeErrorMessage(l10nId, AppErrorCodes.categoryInUse), l10nId.categoryInUse);
    expect(
      localizeErrorMessage(l10nId, AppErrorCodes.defaultCategoryArchiveBlocked),
      l10nId.defaultCategoryArchiveBlocked,
    );
  });

  test('localizeErrorMessage returns raw message for unknown codes', () {
    expect(localizeErrorMessage(l10nEn, 'unknown_error_code'), 'unknown_error_code');
    expect(localizeErrorMessage(l10nEn, 'some failure text'), 'some failure text');
  });
}
