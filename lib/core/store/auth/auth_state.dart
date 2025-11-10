/// 登录状态
/// Represents the authentication state of the user.
class AuthState {
  final String? accessToken;
  final String? refreshToken;
  final bool isAuthenticated;

  const AuthState({
    this.accessToken,
    this.refreshToken,
    this.isAuthenticated = false,
  });

  factory AuthState.initial() => AuthState();

  AuthState copyWith({
    String? accessToken,
    String? refreshToken,
    bool? isAuthenticated,
  }) {
    return AuthState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      isAuthenticated: isAuthenticated ?? ((accessToken ?? this.accessToken) != null),
    );
  }
}
