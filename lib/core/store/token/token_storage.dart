/// ignore_for_file: invalid_annotation_target
/// 存储 token 抽象类
/// Token storage abstract class
/// 参数：
/// - save(String access, String? refresh): 保存访问和刷新令牌的方法
/// - red(): 读取访问和刷新令牌的方法
/// - clear(): 清除存储的令牌的方法
/// Parameters:
/// - save(String access, String? refresh): Method to save access and refresh tokens
/// - red(): Method to read access and refresh tokens
/// - clear(): Method to clear stored tokens
/// Methods:
/// - Future<'void'> save(String access, String? refresh)
/// - Future<(String? acess, String? refresh)> red()
/// - Future'<'void'> clear()
abstract class TokenStorage {
  Future<void> save(String access, String? refresh);
  Future<(String? access, String? refresh)> read();
  Future<void> clear();
}