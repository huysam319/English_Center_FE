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

String formatTime(String time) {
  final parts = time.trim().split(' ');
  final timeParts = parts[0].split(':');
  final period = parts[1].toUpperCase();

  int hour = int.parse(timeParts[0]);
  final int minute = int.parse(timeParts[1]);

  if (period == 'AM' && hour == 12) {
    hour = 0;
  } else if (period == 'PM' && hour != 12) {
    hour += 12;
  }

  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
}