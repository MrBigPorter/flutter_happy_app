/// Description: Configuration for routes that require user authentication.
class RouteAuthConfig {
  /// List of route prefixes that require user authentication.
  static const needAuthRoutes = <String>[
    '/payment',
    '/order/',
    '/me/',
  ];

  /// Determine if the given path requires user login/authentication.
  static bool needLoginForPath(String path) {
    return needAuthRoutes.any((prefix) => path.startsWith(prefix));
  }
}