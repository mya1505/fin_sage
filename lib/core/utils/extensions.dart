import 'package:intl/intl.dart';

extension CurrencyFormatter on num {
  String toCurrency(String locale, {String symbol = 'Rp'}) {
    final formatter = NumberFormat.currency(locale: locale, symbol: symbol, decimalDigits: 0);
    return formatter.format(this);
  }
}
