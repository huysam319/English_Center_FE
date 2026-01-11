class AuthService {
  String? accessToken;
  DateTime? expiredAt;

  bool get isLoggedIn {
    if (accessToken == null || expiredAt == null) return false;
    return DateTime.now().isBefore(expiredAt!);
  }
}

final authService = AuthService();