import 'package:intl/intl.dart';

extension CurrencyFormatter on num {
  String toCurrency(String locale, {String symbol = 'Rp'}) {
    final formatter = NumberFormat.currency(locale: locale, symbol: symbol, decimalDigits: 0);
    return formatter.format(this);
  }
}

extension ByteFormatter on int {
  String toReadableBytes() {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    final decimals = size >= 10 || unitIndex == 0 ? 0 : 1;
    return '${size.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }
}
