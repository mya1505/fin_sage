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
      'unexpectedError': 'Unexpected error',
      'signInGoogle': 'Continue with Google',
      'googleSignInConfigMissing':
          'GOOGLE_SERVER_CLIENT_ID is not set. Define it in dart-define for Google Drive backup auth.',
      'googleAuthUnavailable': 'Google authentication is unavailable. Please sign in again and retry.',
      'dashboardTitle': 'Dashboard',
      'totalBalance': 'Total Balance',
      'monthlyIncome': 'Monthly Income',
      'monthlyExpense': 'Monthly Expense',
      'monthlyTransactions': 'Monthly Transactions',
      'balanceTrendChartLabel': 'Balance trend chart',
      'recentTransactions': 'Recent Transactions',
      'transactionsTitle': 'Transactions',
      'budgetsTitle': 'Budgets',
      'reportsTitle': 'Reports',
      'settingsTitle': 'Settings',
      'refreshLabel': 'Refresh',
      'addTransaction': 'Add Transaction',
      'emptyTransactions': 'No transactions yet',
      'searchTransactions': 'Search transactions',
      'noMatchingTransactions': 'No matching transactions',
      'titleLabel': 'Title',
      'amountLabel': 'Amount',
      'dateLabel': 'Date',
      'allType': 'All',
      'transactionTypeLabel': 'Transaction Type',
      'incomeType': 'Income',
      'expenseType': 'Expense',
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
      'noDataToExport': 'No data to export',
      'csvSaved': 'CSV saved: {path}',
      'selectedMonthLabel': 'Month: {month}',
      'monthlyReportTitle': 'FinSage Report - {month}',
      'reportPdfDefaultTitle': 'FinSage Financial Report',
      'reportPdfTransactionsLabel': 'Transactions',
      'reportPdfIncomeLabel': 'Income',
      'reportPdfExpenseLabel': 'Expense',
      'reportPdfNetBalanceLabel': 'Net Balance',
      'reportCsvHeaderId': 'id',
      'reportCsvHeaderTitle': 'title',
      'reportCsvHeaderAmount': 'amount',
      'reportCsvHeaderType': 'type',
      'reportCsvHeaderDate': 'date',
      'reportCsvHeaderCategoryId': 'category_id',
      'transactionCount': '{count} transactions',
      'netBalance': 'Net Balance',
      'darkMode': 'Dark Mode',
      'budgetNotificationsLabel': 'Budget Notifications',
      'languageLabel': 'Language',
      'systemDefault': 'System Default',
      'englishLanguage': 'English',
      'indonesianLanguage': 'Indonesian',
      'backupNow': 'Backup Now',
      'lastBackupLabel': 'Last backup: {value}',
      'noBackupHistory': 'No backup history yet',
      'restorePreview': 'Restore Preview',
      'noBackupFiles': 'No backup files found',
      'backupCompleted': 'Backup completed successfully',
      'autoBackupValidationScheduled': 'Auto-backup validation has been scheduled',
      'validateAutoBackupLabel': 'Validate Auto Backup',
      'autoBackupStatusTitle': 'Auto Backup Status',
      'autoBackupNeverRun': 'Last attempt: never',
      'autoBackupNoSuccessYet': 'Last success: not yet',
      'autoBackupLastAttempt': 'Last attempt: {value}',
      'autoBackupLastSuccess': 'Last success: {value}',
      'autoBackupLastError': 'Last error: {value}',
      'restorePreviewLoaded': 'Restore preview loaded',
      'restoreCompleted': 'Restore completed successfully',
      'restoreConfirmTitle': 'Confirm Restore',
      'restoreConfirmBody': 'Restoring backup will overwrite local data. Continue?',
      'backupInvalidFile': 'Backup file is invalid or corrupted',
      'backupChecksumMismatch': 'Backup integrity check failed (checksum mismatch)',
      'signOutLabel': 'Sign Out',
      'signOutConfirmBody': 'You will be returned to login screen. Continue?',
      'resetLocalDataLabel': 'Reset Local Data',
      'resetLocalDataConfirmBody':
          'This will remove local transactions, budgets, and custom categories. Continue?',
      'resetActionLabel': 'Reset',
      'localDataResetCompleted': 'Local data has been reset',
      'manageCategories': 'Manage categories',
      'addCategory': 'Add Category',
      'categoryNameLabel': 'Category Name',
      'colorHexLabel': 'Color (Hex)',
      'iconLabel': 'Icon Name',
      'categoryCreated': 'Category created',
      'categoryExists': 'Category already exists',
      'categoryInUse': 'Category is still used by transactions',
      'defaultCategoryArchiveBlocked': 'Default category cannot be archived',
      'archiveCategoryTitle': 'Archive Category',
      'archiveCategoryBody': 'Archive category "{name}"?',
      'archiveActionLabel': 'Archive',
      'categoryNameRequired': 'Category name is required',
      'categoryNameTooLong': 'Category name is too long',
      'invalidColorHex': 'Invalid hex color, use format #RRGGBB',
      'confirmDeleteTitle': 'Delete Transaction',
      'confirmDeleteBody': 'This transaction will be permanently removed. Continue?',
      'confirmDeleteBudgetTitle': 'Delete Budget',
      'confirmDeleteBudgetBody': 'This budget will be permanently removed. Continue?',
      'cancelLabel': 'Cancel',
      'deleteActionLabel': 'Delete',
      'updateActionLabel': 'Update',
      'restoreActionLabel': 'Restore'
    },
    'id': {
      'appTitle': 'FinSage',
      'unexpectedError': 'Terjadi kesalahan tak terduga',
      'signInGoogle': 'Masuk dengan Google',
      'googleSignInConfigMissing':
          'GOOGLE_SERVER_CLIENT_ID belum diisi. Tambahkan di dart-define untuk autentikasi backup Google Drive.',
      'googleAuthUnavailable': 'Autentikasi Google tidak tersedia. Silakan login ulang lalu coba lagi.',
      'dashboardTitle': 'Dasbor',
      'totalBalance': 'Total Saldo',
      'monthlyIncome': 'Pemasukan Bulanan',
      'monthlyExpense': 'Pengeluaran Bulanan',
      'monthlyTransactions': 'Transaksi Bulanan',
      'balanceTrendChartLabel': 'Grafik tren saldo',
      'recentTransactions': 'Transaksi Terbaru',
      'transactionsTitle': 'Transaksi',
      'budgetsTitle': 'Anggaran',
      'reportsTitle': 'Laporan',
      'settingsTitle': 'Pengaturan',
      'refreshLabel': 'Muat Ulang',
      'addTransaction': 'Tambah Transaksi',
      'emptyTransactions': 'Belum ada transaksi',
      'searchTransactions': 'Cari transaksi',
      'noMatchingTransactions': 'Tidak ada transaksi yang cocok',
      'titleLabel': 'Judul',
      'amountLabel': 'Jumlah',
      'dateLabel': 'Tanggal',
      'allType': 'Semua',
      'transactionTypeLabel': 'Tipe Transaksi',
      'incomeType': 'Pemasukan',
      'expenseType': 'Pengeluaran',
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
      'noDataToExport': 'Tidak ada data untuk diekspor',
      'csvSaved': 'CSV tersimpan: {path}',
      'selectedMonthLabel': 'Bulan: {month}',
      'monthlyReportTitle': 'Laporan FinSage - {month}',
      'reportPdfDefaultTitle': 'Laporan Keuangan FinSage',
      'reportPdfTransactionsLabel': 'Transaksi',
      'reportPdfIncomeLabel': 'Pemasukan',
      'reportPdfExpenseLabel': 'Pengeluaran',
      'reportPdfNetBalanceLabel': 'Saldo Bersih',
      'reportCsvHeaderId': 'id',
      'reportCsvHeaderTitle': 'judul',
      'reportCsvHeaderAmount': 'jumlah',
      'reportCsvHeaderType': 'tipe',
      'reportCsvHeaderDate': 'tanggal',
      'reportCsvHeaderCategoryId': 'kategori_id',
      'transactionCount': '{count} transaksi',
      'netBalance': 'Saldo Bersih',
      'darkMode': 'Mode Gelap',
      'budgetNotificationsLabel': 'Notifikasi Anggaran',
      'languageLabel': 'Bahasa',
      'systemDefault': 'Ikuti Sistem',
      'englishLanguage': 'Inggris',
      'indonesianLanguage': 'Indonesia',
      'backupNow': 'Backup Sekarang',
      'lastBackupLabel': 'Backup terakhir: {value}',
      'noBackupHistory': 'Belum ada riwayat backup',
      'restorePreview': 'Pratinjau Restore',
      'noBackupFiles': 'Belum ada file backup',
      'backupCompleted': 'Backup berhasil',
      'autoBackupValidationScheduled': 'Validasi auto-backup telah dijadwalkan',
      'validateAutoBackupLabel': 'Validasi Auto Backup',
      'autoBackupStatusTitle': 'Status Auto Backup',
      'autoBackupNeverRun': 'Percobaan terakhir: belum pernah',
      'autoBackupNoSuccessYet': 'Sukses terakhir: belum ada',
      'autoBackupLastAttempt': 'Percobaan terakhir: {value}',
      'autoBackupLastSuccess': 'Sukses terakhir: {value}',
      'autoBackupLastError': 'Error terakhir: {value}',
      'restorePreviewLoaded': 'Pratinjau restore berhasil dimuat',
      'restoreCompleted': 'Restore berhasil',
      'restoreConfirmTitle': 'Konfirmasi Restore',
      'restoreConfirmBody': 'Restore backup akan menimpa data lokal. Lanjutkan?',
      'backupInvalidFile': 'File backup tidak valid atau rusak',
      'backupChecksumMismatch': 'Pemeriksaan integritas backup gagal (checksum tidak cocok)',
      'signOutLabel': 'Keluar',
      'signOutConfirmBody': 'Kamu akan kembali ke layar login. Lanjutkan?',
      'resetLocalDataLabel': 'Reset Data Lokal',
      'resetLocalDataConfirmBody':
          'Ini akan menghapus transaksi, anggaran, dan kategori kustom lokal. Lanjutkan?',
      'resetActionLabel': 'Reset',
      'localDataResetCompleted': 'Data lokal berhasil di-reset',
      'manageCategories': 'Kelola kategori',
      'addCategory': 'Tambah Kategori',
      'categoryNameLabel': 'Nama Kategori',
      'colorHexLabel': 'Warna (Hex)',
      'iconLabel': 'Nama Ikon',
      'categoryCreated': 'Kategori berhasil dibuat',
      'categoryExists': 'Kategori sudah ada',
      'categoryInUse': 'Kategori masih digunakan oleh transaksi',
      'defaultCategoryArchiveBlocked': 'Kategori default tidak bisa diarsipkan',
      'archiveCategoryTitle': 'Arsipkan Kategori',
      'archiveCategoryBody': 'Arsipkan kategori "{name}"?',
      'archiveActionLabel': 'Arsipkan',
      'categoryNameRequired': 'Nama kategori wajib diisi',
      'categoryNameTooLong': 'Nama kategori terlalu panjang',
      'invalidColorHex': 'Hex warna tidak valid, gunakan format #RRGGBB',
      'confirmDeleteTitle': 'Hapus Transaksi',
      'confirmDeleteBody': 'Transaksi ini akan dihapus permanen. Lanjutkan?',
      'confirmDeleteBudgetTitle': 'Hapus Anggaran',
      'confirmDeleteBudgetBody': 'Anggaran ini akan dihapus permanen. Lanjutkan?',
      'cancelLabel': 'Batal',
      'deleteActionLabel': 'Hapus',
      'updateActionLabel': 'Perbarui',
      'restoreActionLabel': 'Restore'
    }
  };

  String _t(String key) => _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']![key] ?? key;

  String get appTitle => _t('appTitle');
  String get unexpectedError => _t('unexpectedError');
  String get signInGoogle => _t('signInGoogle');
  String get googleSignInConfigMissing => _t('googleSignInConfigMissing');
  String get googleAuthUnavailable => _t('googleAuthUnavailable');
  String get dashboardTitle => _t('dashboardTitle');
  String get totalBalance => _t('totalBalance');
  String get monthlyIncome => _t('monthlyIncome');
  String get monthlyExpense => _t('monthlyExpense');
  String get monthlyTransactions => _t('monthlyTransactions');
  String get balanceTrendChartLabel => _t('balanceTrendChartLabel');
  String get recentTransactions => _t('recentTransactions');
  String get transactionsTitle => _t('transactionsTitle');
  String get budgetsTitle => _t('budgetsTitle');
  String get reportsTitle => _t('reportsTitle');
  String get settingsTitle => _t('settingsTitle');
  String get refreshLabel => _t('refreshLabel');
  String get addTransaction => _t('addTransaction');
  String get emptyTransactions => _t('emptyTransactions');
  String get searchTransactions => _t('searchTransactions');
  String get noMatchingTransactions => _t('noMatchingTransactions');
  String get titleLabel => _t('titleLabel');
  String get amountLabel => _t('amountLabel');
  String get dateLabel => _t('dateLabel');
  String get allType => _t('allType');
  String get transactionTypeLabel => _t('transactionTypeLabel');
  String get incomeType => _t('incomeType');
  String get expenseType => _t('expenseType');
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
  String get noDataToExport => _t('noDataToExport');
  String csvSaved(String path) => _t('csvSaved').replaceAll('{path}', path);
  String selectedMonthLabel(String month) => _t('selectedMonthLabel').replaceAll('{month}', month);
  String monthlyReportTitle(String month) => _t('monthlyReportTitle').replaceAll('{month}', month);
  String get reportPdfDefaultTitle => _t('reportPdfDefaultTitle');
  String get reportPdfTransactionsLabel => _t('reportPdfTransactionsLabel');
  String get reportPdfIncomeLabel => _t('reportPdfIncomeLabel');
  String get reportPdfExpenseLabel => _t('reportPdfExpenseLabel');
  String get reportPdfNetBalanceLabel => _t('reportPdfNetBalanceLabel');
  String get reportCsvHeaderId => _t('reportCsvHeaderId');
  String get reportCsvHeaderTitle => _t('reportCsvHeaderTitle');
  String get reportCsvHeaderAmount => _t('reportCsvHeaderAmount');
  String get reportCsvHeaderType => _t('reportCsvHeaderType');
  String get reportCsvHeaderDate => _t('reportCsvHeaderDate');
  String get reportCsvHeaderCategoryId => _t('reportCsvHeaderCategoryId');
  String transactionCount(int count) => _t('transactionCount').replaceAll('{count}', count.toString());
  String get netBalance => _t('netBalance');
  String get darkMode => _t('darkMode');
  String get budgetNotificationsLabel => _t('budgetNotificationsLabel');
  String get languageLabel => _t('languageLabel');
  String get systemDefault => _t('systemDefault');
  String get englishLanguage => _t('englishLanguage');
  String get indonesianLanguage => _t('indonesianLanguage');
  String get backupNow => _t('backupNow');
  String lastBackupLabel(String value) => _t('lastBackupLabel').replaceAll('{value}', value);
  String get noBackupHistory => _t('noBackupHistory');
  String get restorePreview => _t('restorePreview');
  String get noBackupFiles => _t('noBackupFiles');
  String get backupCompleted => _t('backupCompleted');
  String get autoBackupValidationScheduled => _t('autoBackupValidationScheduled');
  String get validateAutoBackupLabel => _t('validateAutoBackupLabel');
  String get autoBackupStatusTitle => _t('autoBackupStatusTitle');
  String get autoBackupNeverRun => _t('autoBackupNeverRun');
  String get autoBackupNoSuccessYet => _t('autoBackupNoSuccessYet');
  String autoBackupLastAttempt(String value) => _t('autoBackupLastAttempt').replaceAll('{value}', value);
  String autoBackupLastSuccess(String value) => _t('autoBackupLastSuccess').replaceAll('{value}', value);
  String autoBackupLastError(String value) => _t('autoBackupLastError').replaceAll('{value}', value);
  String get restorePreviewLoaded => _t('restorePreviewLoaded');
  String get restoreCompleted => _t('restoreCompleted');
  String get restoreConfirmTitle => _t('restoreConfirmTitle');
  String get restoreConfirmBody => _t('restoreConfirmBody');
  String get backupInvalidFile => _t('backupInvalidFile');
  String get backupChecksumMismatch => _t('backupChecksumMismatch');
  String get signOutLabel => _t('signOutLabel');
  String get signOutConfirmBody => _t('signOutConfirmBody');
  String get resetLocalDataLabel => _t('resetLocalDataLabel');
  String get resetLocalDataConfirmBody => _t('resetLocalDataConfirmBody');
  String get resetActionLabel => _t('resetActionLabel');
  String get localDataResetCompleted => _t('localDataResetCompleted');
  String get manageCategories => _t('manageCategories');
  String get addCategory => _t('addCategory');
  String get categoryNameLabel => _t('categoryNameLabel');
  String get colorHexLabel => _t('colorHexLabel');
  String get iconLabel => _t('iconLabel');
  String get categoryCreated => _t('categoryCreated');
  String get categoryExists => _t('categoryExists');
  String get categoryInUse => _t('categoryInUse');
  String get defaultCategoryArchiveBlocked => _t('defaultCategoryArchiveBlocked');
  String get archiveCategoryTitle => _t('archiveCategoryTitle');
  String archiveCategoryBody(String name) => _t('archiveCategoryBody').replaceAll('{name}', name);
  String get archiveActionLabel => _t('archiveActionLabel');
  String get categoryNameRequired => _t('categoryNameRequired');
  String get categoryNameTooLong => _t('categoryNameTooLong');
  String get invalidColorHex => _t('invalidColorHex');
  String get cancelLabel => _t('cancelLabel');
  String get deleteActionLabel => _t('deleteActionLabel');
  String get updateActionLabel => _t('updateActionLabel');
  String get confirmDeleteTitle => _t('confirmDeleteTitle');
  String get confirmDeleteBody => _t('confirmDeleteBody');
  String get confirmDeleteBudgetTitle => _t('confirmDeleteBudgetTitle');
  String get confirmDeleteBudgetBody => _t('confirmDeleteBudgetBody');
  String get restoreActionLabel => _t('restoreActionLabel');
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
