import 'package:flutter_app/core/store/token/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WebPreferencesStorage - Token storage using SharedPreferences
/// Implements TokenStorage interface
/// Methods:
/// - Future<'void'> save(String access, String? refresh)
/// - Future<(String? acess, String? refresh)> red()
/// - Future<'void'> clear()
/// Parameters:
/// - _kAccess: Key for access token
/// - _kRefresh: Key for refresh token
class WebPreferencesStorage implements TokenStorage {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  @override
  Future<void> save(String access, String? refresh) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAccess, access);
    if (refresh != null) {
      await sp.setString(_kRefresh, refresh);
    }else{
      await sp.remove(_kRefresh);
    }
  }

  @override
  Future<(String?, String?)> read() async {
    final sp = await SharedPreferences.getInstance();
    final access = sp.getString(_kAccess);
    final refresh = sp.getString(_kRefresh);
    return (access, refresh);// (string? access, string? refresh)
  }

  @override
  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kAccess);
    await sp.remove(_kRefresh);
  }

}