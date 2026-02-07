import 'package:intl/intl.dart';

String convertDateFormat(String date) {
  final inputFormat = DateFormat('dd/MM/yyyy');
  final outputFormat = DateFormat('yyyy-MM-dd');
  
  final dateTime = inputFormat.parse(date);
  return outputFormat.format(dateTime);
}

String formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day/$month/$year';
}