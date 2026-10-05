import 'package:intl/intl.dart';

/// Dates render in the current UI language (Intl.defaultLocale is kept in
/// sync with the selected locale by AppSettings).
String formatDate(DateTime? date) {
  if (date == null) return '';
  try {
    return DateFormat('d MMMM y', Intl.defaultLocale ?? 'ar').format(date);
  } catch (_) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

String formatDateTime(DateTime? date) {
  if (date == null) return '';
  try {
    return DateFormat('d MMMM y - HH:mm', Intl.defaultLocale ?? 'ar')
        .format(date);
  } catch (_) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
