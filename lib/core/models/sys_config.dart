class SysConfig {
  final String kycAndPhoneVerification;

  SysConfig({required this.kycAndPhoneVerification});

  factory SysConfig.fromJson(Map<String, dynamic> json) {
    return SysConfig(
      kycAndPhoneVerification: json["kyc_and_phone_verification"] ?? "1",
    );
  }
}