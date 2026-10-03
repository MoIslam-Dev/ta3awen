import 'package:intl/intl.dart';

String formatDate(DateTime? date) {
  if (date == null) return '';
  try {
    return DateFormat('d MMMM y', 'ar').format(date);
  } catch (_) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

String formatDateTime(DateTime? date) {
  if (date == null) return '';
  try {
    return DateFormat('d MMMM y - HH:mm', 'ar').format(date);
  } catch (_) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
