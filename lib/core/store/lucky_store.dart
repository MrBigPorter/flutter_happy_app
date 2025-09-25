import 'package:flutter/material.dart';
import '../api/lucky_api.dart';
import '../models/index.dart';


class LuckyStore with ChangeNotifier {
  UserInfo? userInfo;
  Balance balance = Balance(realBalance: 0, coinBalance: 0);
  SysConfig sysConfig = SysConfig(kycAndPhoneVerification: "1");

  Future<UserInfo?> updateUserInfo() async {
    final res = await LuckyApi.getUserInfo();
    userInfo = res;
    notifyListeners();
    return res;
  }

  Future<Balance> updateWalletBalance() async {
    final res = await LuckyApi.getWalletBalance();
    balance = res;
    notifyListeners();
    return res;
  }

  Future<SysConfig> updateSysConfig() async {
    final res = await LuckyApi.getSysConfig();
    sysConfig = res;
    notifyListeners();
    return res;
  }
}