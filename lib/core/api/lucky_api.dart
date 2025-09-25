import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/index.dart';


class LuckyApi {
  static const baseUrl = "https://api.yourdomain.com";

  static Future<UserInfo> getUserInfo() async {
    final res = await http.get(Uri.parse("$baseUrl/user/info"));
    if (res.statusCode == 200) {
      return UserInfo.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to load user info");
  }

  static Future<Balance> getWalletBalance() async {
    final res = await http.get(Uri.parse("$baseUrl/wallet/balance"));
    if (res.statusCode == 200) {
      return Balance.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to load wallet balance");
  }

  static Future<SysConfig> getSysConfig() async {
    final res = await http.get(Uri.parse("$baseUrl/sys/config"));
    if (res.statusCode == 200) {
      return SysConfig.fromJson(jsonDecode(res.body));
    }
    throw Exception("Failed to load sys config");
  }
}