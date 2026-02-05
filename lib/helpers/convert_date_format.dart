import 'package:intl/intl.dart';

String convertDateFormat(String date) {
  final inputFormat = DateFormat('dd/MM/yyyy');
  final outputFormat = DateFormat('yyyy-MM-dd');
  
  final dateTime = inputFormat.parse(date);
  return outputFormat.format(dateTime);
}