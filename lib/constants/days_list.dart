final List<Map<String, String>> days = [
  {'id': 'Monday', 'name': 'Thứ hai', 'shortName': 'T2'},
  {'id': 'Tuesday', 'name': 'Thứ ba', 'shortName': 'T3'},
  {'id': 'Wednesday', 'name': 'Thứ tư', 'shortName': 'T4'},
  {'id': 'Thursday', 'name': 'Thứ năm', 'shortName': 'T5'},
  {'id': 'Friday', 'name': 'Thứ sáu', 'shortName': 'T6'},
  {'id': 'Saturday', 'name': 'Thứ bảy', 'shortName': 'T7'},
  {'id': 'Sunday', 'name': 'Chủ nhật', 'shortName': 'CN'},
];

String getDayShortName(String dayId) {
  final day = days.firstWhere((d) => d['id'] == dayId, orElse: () => {});
  return day['shortName'] ?? '';
}