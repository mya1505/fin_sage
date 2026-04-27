import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('id'),
  ];

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? instance = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(instance != null, 'AppLocalizations not found in widget tree');
    return instance!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'FinSage',
      'signInGoogle': 'Continue with Google',
      'dashboardTitle': 'Dashboard',
      'totalBalance': 'Total Balance',
      'monthlyIncome': 'Monthly Income',
      'monthlyExpense': 'Monthly Expense',
      'transactionsTitle': 'Transactions',
      'budgetsTitle': 'Budgets',
      'reportsTitle': 'Reports',
      'settingsTitle': 'Settings',
      'addTransaction': 'Add Transaction',
      'emptyTransactions': 'No transactions yet',
      'titleLabel': 'Title',
      'amountLabel': 'Amount',
      'dateLabel': 'Date',
      'saveLabel': 'Save',
      'requiredField': 'This field is required',
      'amountRequired': 'Amount is required',
      'amountInvalid': 'Enter a valid amount',
      'amountMustBePositive': 'Amount must be positive',
      'amountTooLarge': 'Amount is too large',
      'dateRequired': 'Date is required',
      'dateFutureNotAllowed': 'Future date is not allowed',
      'noBudgetYet': 'No budget configured',
      'categoryLabel': 'Category',
      'usedLabel': 'Used',
      'limitLabel': 'Limit',
      'exportPdf': 'Export PDF',
      'exportCsv': 'Export CSV',
      'darkMode': 'Dark Mode',
      'languageLabel': 'Language',
      'systemDefault': 'System Default',
      'englishLanguage': 'English',
      'indonesianLanguage': 'Indonesian',
      'backupNow': 'Backup Now',
      'restorePreview': 'Restore Preview'
    },
    'id': {
      'appTitle': 'FinSage',
      'signInGoogle': 'Masuk dengan Google',
      'dashboardTitle': 'Dasbor',
      'totalBalance': 'Total Saldo',
      'monthlyIncome': 'Pemasukan Bulanan',
      'monthlyExpense': 'Pengeluaran Bulanan',
      'transactionsTitle': 'Transaksi',
      'budgetsTitle': 'Anggaran',
      'reportsTitle': 'Laporan',
      'settingsTitle': 'Pengaturan',
      'addTransaction': 'Tambah Transaksi',
      'emptyTransactions': 'Belum ada transaksi',
      'titleLabel': 'Judul',
      'amountLabel': 'Jumlah',
      'dateLabel': 'Tanggal',
      'saveLabel': 'Simpan',
      'requiredField': 'Kolom ini wajib diisi',
      'amountRequired': 'Jumlah wajib diisi',
      'amountInvalid': 'Masukkan jumlah yang valid',
      'amountMustBePositive': 'Jumlah harus lebih dari nol',
      'amountTooLarge': 'Jumlah terlalu besar',
      'dateRequired': 'Tanggal wajib diisi',
      'dateFutureNotAllowed': 'Tanggal masa depan tidak diizinkan',
      'noBudgetYet': 'Belum ada anggaran',
      'categoryLabel': 'Kategori',
      'usedLabel': 'Terpakai',
      'limitLabel': 'Batas',
      'exportPdf': 'Ekspor PDF',
      'exportCsv': 'Ekspor CSV',
      'darkMode': 'Mode Gelap',
      'languageLabel': 'Bahasa',
      'systemDefault': 'Ikuti Sistem',
      'englishLanguage': 'Inggris',
      'indonesianLanguage': 'Indonesia',
      'backupNow': 'Backup Sekarang',
      'restorePreview': 'Pratinjau Restore'
    }
  };

  String _t(String key) => _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;

  String get appTitle => _t('appTitle');
  String get signInGoogle => _t('signInGoogle');
  String get dashboardTitle => _t('dashboardTitle');
  String get totalBalance => _t('totalBalance');
  String get monthlyIncome => _t('monthlyIncome');
  String get monthlyExpense => _t('monthlyExpense');
  String get transactionsTitle => _t('transactionsTitle');
  String get budgetsTitle => _t('budgetsTitle');
  String get reportsTitle => _t('reportsTitle');
  String get settingsTitle => _t('settingsTitle');
  String get addTransaction => _t('addTransaction');
  String get emptyTransactions => _t('emptyTransactions');
  String get titleLabel => _t('titleLabel');
  String get amountLabel => _t('amountLabel');
  String get dateLabel => _t('dateLabel');
  String get saveLabel => _t('saveLabel');
  String get requiredField => _t('requiredField');
  String get amountRequired => _t('amountRequired');
  String get amountInvalid => _t('amountInvalid');
  String get amountMustBePositive => _t('amountMustBePositive');
  String get amountTooLarge => _t('amountTooLarge');
  String get dateRequired => _t('dateRequired');
  String get dateFutureNotAllowed => _t('dateFutureNotAllowed');
  String get noBudgetYet => _t('noBudgetYet');
  String get categoryLabel => _t('categoryLabel');
  String get usedLabel => _t('usedLabel');
  String get limitLabel => _t('limitLabel');
  String get exportPdf => _t('exportPdf');
  String get exportCsv => _t('exportCsv');
  String get darkMode => _t('darkMode');
  String get languageLabel => _t('languageLabel');
  String get systemDefault => _t('systemDefault');
  String get englishLanguage => _t('englishLanguage');
  String get indonesianLanguage => _t('indonesianLanguage');
  String get backupNow => _t('backupNow');
  String get restorePreview => _t('restorePreview');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'id'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
