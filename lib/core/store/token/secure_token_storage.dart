import 'package:flutter_app/core/store/token/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// SecureTokenStorage - Implementation of TokenStorage using FlutterSecureStorage
/// Stores access and refresh tokens securely
/// Methods:
/// - Future<'void'> save(String access, String? refresh)
/// - Future<(String? access, String? refresh)> read()
/// - Future<'void'> clear()
/// Parameters:
/// - _s: FlutterSecureStorage instance for secure storage
/// - _kAccess: Key for access token
/// - _kRefresh: Key for refresh token
/// Example:
/// ```dart
/// final storage = SecureTokenStorage();
/// await storage.save('access_token_value', 'refresh_token_value');
/// final (access, refresh) = await storage.read();
/// await storage.clear();
/// ```
class SecureTokenStorage implements TokenStorage {
  final _s = const FlutterSecureStorage();
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  @override
  Future<void> save(String access, String? refresh) async {
    await _s.write(key: _kAccess, value: access);
    if(refresh != null){
      await _s.write(key: _kRefresh, value: refresh);
    }else{
      await _s.delete(key: _kRefresh);
    }
  }

  @override
  Future<(String?, String?)> read() async{
   final access = await _s.read(key: _kAccess);
   final refresh = await _s.read(key: _kRefresh);
   return (access, refresh);
  }

  @override
  Future<void> clear() async{
    await _s.delete(key: _kAccess);
    await _s.delete(key: _kRefresh);
  }
}