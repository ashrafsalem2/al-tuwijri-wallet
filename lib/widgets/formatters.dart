import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

String formatMoney(double amount, String currency, {String locale = 'en'}) {
  final f = NumberFormat.currency(locale: locale, symbol: '', decimalDigits: 2);
  return '${f.format(amount).trim()} $currency';
}

String formatInt(int value, {String locale = 'en'}) =>
    NumberFormat.decimalPattern(locale).format(value);

String formatDate(DateTime date, {String locale = 'en'}) =>
    DateFormat('d MMM yyyy', locale).format(date);

String formatDateTime(DateTime date, {String locale = 'en'}) =>
    DateFormat('d MMM yyyy • h:mm a', locale).format(date);

/// Hijri (Islamic) date, e.g. "19 محرم 1448 هـ" (ar) or "19 Muharram 1448 AH".
String formatHijri(DateTime date, {String locale = 'en'}) {
  final isAr = locale == 'ar';
  HijriCalendar.setLocal(isAr ? 'ar' : 'en');
  final h = HijriCalendar.fromDate(date);
  final text = h.toFormat('dd MMMM yyyy');
  return isAr ? '${_toArabicDigits(text)} هـ' : '$text AH';
}

String _toArabicDigits(String s) {
  const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  for (var i = 0; i < 10; i++) {
    s = s.replaceAll(western[i], arabic[i]);
  }
  return s;
}
