
class SysConfig {
  final String kycAndPhoneVerification;
  final String webBaseUrl;
  final double exChangeRate;

  SysConfig({required this.kycAndPhoneVerification, required this.webBaseUrl, required this.exChangeRate});

  factory SysConfig.fromJson(Map<String, dynamic> json) {
    return SysConfig(
      kycAndPhoneVerification: json["kyc_and_phone_verification"] ?? "1",
      webBaseUrl: json["web_base_url"] ?? "",
      exChangeRate: json["ex_change_rate"]?.toDouble() ?? 1.0,
    );
  }
}