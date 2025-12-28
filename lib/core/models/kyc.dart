import 'package:json_annotation/json_annotation.dart';

part 'kyc.g.dart';

/// ------------------------------
/// JSON helpers (防止类型漂移导致崩溃)
/// ------------------------------
double _doubleFromJson(Object? v) => (v as num?)?.toDouble() ?? 0.0;
Object _doubleToJson(double v) => v;

bool _boolFromJson(Object? v) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }
  return false;
}

/// ------------------------------
/// 1) Session
/// ------------------------------
@JsonSerializable(checked: true)
class KycSession {
  final String sessionId;

  KycSession({required this.sessionId});

  factory KycSession.fromJson(Map<String, dynamic> json) =>
      _$KycSessionFromJson(json);

  Map<String, dynamic> toJson() => _$KycSessionToJson(this);

  @override
  String toString() => toJson().toString();
}

/// ------------------------------
/// 2) KYC Me (我的 KYC / 状态查询)
/// ------------------------------
@JsonSerializable(checked: true)
class KycMe {
  @JsonKey(defaultValue: 0)
  final int kycStatus;

  final String? id;
  final String? realName;
  final String? idNumber;
  final String? rejectReason;

  final String? idCardFront;
  final String? idCardBack;
  final String? faceImage;

  KycMe({
    required this.kycStatus,
    this.id,
    this.realName,
    this.idNumber,
    this.rejectReason,
    this.idCardFront,
    this.idCardBack,
    this.faceImage,
  });

  factory KycMe.fromJson(Map<String, dynamic> json) => _$KycMeFromJson(json);

  Map<String, dynamic> toJson() => _$KycMeToJson(this);

  @override
  String toString() => toJson().toString();
}

/// ------------------------------
/// 3) KYC Status enum (与后端 0-5 对齐)
/// ------------------------------
enum KycStatusLabel {
  draft,
  reviewing,
  rejected,
  needMore,
  approved,
  autoRejected,
}

enum KycStatusEnum {
  draft(0, KycStatusLabel.draft), // 未提交
  reviewing(1, KycStatusLabel.reviewing), // 审核中
  rejected(2, KycStatusLabel.rejected), // 审核失败
  needMore(3, KycStatusLabel.needMore), // 待补充
  approved(4, KycStatusLabel.approved), // 已通过
  autoRejected(5, KycStatusLabel.autoRejected); // 系统自动拒绝

  final int status;
  final KycStatusLabel label;

  const KycStatusEnum(this.status, this.label);

  static KycStatusEnum fromStatus(int status) {
    return KycStatusEnum.values.firstWhere(
          (e) => e.status == status,
      orElse: () => KycStatusEnum.draft,
    );
  }
}

/// ------------------------------
/// 4) 支持证件类型配置（动态渲染页面）
/// 说明前后端是 int(0/1)，这里保持一致
/// ------------------------------
@JsonSerializable(checked: true)
class KycIdTypes {
  @JsonKey(defaultValue: 0)
  final int typeId;

  @JsonKey(defaultValue: '')
  final String typeName;

  /// 0/1
  @JsonKey(defaultValue: 0)
  final int requiresFront;

  /// 0/1
  @JsonKey(defaultValue: 0)
  final int requiresBack;

  /// 0/1
  @JsonKey(defaultValue: 0)
  final int requiresOcr;

  KycIdTypes({
    required this.typeId,
    required this.typeName,
    required this.requiresFront,
    required this.requiresBack,
    required this.requiresOcr,
  });

  factory KycIdTypes.fromJson(Map<String, dynamic> json) =>
      _$KycIdTypesFromJson(json);

  Map<String, dynamic> toJson() => _$KycIdTypesToJson(this);

  @override
  String toString() => toJson().toString();
}

extension KycIdTypesX on KycIdTypes {
  bool get needFront => requiresFront == 1;
  bool get needBack => requiresBack == 1;
  bool get needOcr => requiresOcr == 1;
}

/// ------------------------------
/// ------------------------------
/// 约定：
/// - type: string（比如 "PASSPORT" / "PH_DRIVER_LICENSE" / "UNKNOWN"）
/// - typeId: int（后端已映射好的可入库 int）
/// OCR 返回（对齐后端 /kyc/ocr-scan 的 data）
@JsonSerializable(checked: true)
class KycOcrResult {
  /// 后端枚举 int（UNKNOWN=0）
  @JsonKey(defaultValue: 0)
  final int type;

  /// 后端文本，例如 "PH_NATIONAL_ID" / "UNKNOWN"
  @JsonKey(defaultValue: 'UNKNOWN')
  final String typeText;

  @JsonKey(defaultValue: 'UNKNOWN')
  final String country;

  final String? idNumber;

  /// 原始全名（可能是 "WEI KEHANG"）
  final String? name;

  /// 结构化名字
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? realName;

  /// 后端是 timestamp(ms) 或 null
  final int? birthday;

  /// MALE/FEMALE/UNKNOWN
  final String? gender;

  /// 后端目前是 null（或未来可能 timestamp/string）
  final int? expiryDate;

  final String? idCardFront;
  final String? idCardBack;

  /// 风控
  @JsonKey(fromJson: _boolFromJson, defaultValue: false)
  final bool isSuspicious;

  /// 后端可能 int/double/string，这里统一 double
  @JsonKey(fromJson: _doubleFromJson, toJson: _doubleToJson, defaultValue: 0.0)
  final double fraudScore;

  final String? fraudReason;

  @JsonKey(defaultValue: '')
  final String rawText;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final int? selectedTypeId;

  KycOcrResult({
    required this.type,
    required this.typeText,
    required this.country,
    this.idNumber,
    this.name,
    this.firstName,
    this.middleName,
    this.lastName,
    this.realName,
    this.birthday,
    this.gender,
    this.expiryDate,
    required this.isSuspicious,
    required this.fraudScore,
    this.fraudReason,
    required this.rawText,
    this.selectedTypeId,
    required this.idCardFront,
     this.idCardBack,
  });

  factory KycOcrResult.fromJson(Map<String, dynamic> json) =>
      _$KycOcrResultFromJson(json);

  Map<String, dynamic> toJson() => _$KycOcrResultToJson(this);

  /// ✅ UI 用：timestamp -> YYYY-MM-DD
  String? get birthdayYmd => _tsToYmd(birthday);

  String? get expiryYmd => _tsToYmd(expiryDate);

  KycOcrResult copyWith({
    String? idCardFront,
    String? idCardBack,
}) => KycOcrResult(
    type: type,
    typeText: typeText,
    country: country,
    idNumber: idNumber,
    name: name,
    firstName: firstName,
    middleName: middleName,
    lastName: lastName,
    realName: realName,
    birthday: birthday,
    gender: gender,
    expiryDate: expiryDate,
    isSuspicious: isSuspicious,
    fraudScore: fraudScore,
    fraudReason: fraudReason,
    rawText: rawText,
    idCardFront: idCardFront,
    idCardBack: idCardBack,
  );

  @override
  String toString() => toJson().toString();
}

String? _tsToYmd(int? ts) {
  if (ts == null || ts <= 0) return null;
  final dt = DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true).toLocal();
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// ------------------------------
/// 6) Submit DTO（最终提交）
/// ------------------------------

@JsonSerializable(checked: true, explicitToJson: true, includeIfNull: false)
class SubmitKycDto {
  final String sessionId;
  final int idType;
  final String idNumber;
  final String realName;

  final String firstName;
  final String? middleName;
  final String lastName;

  final String birthday;

  final String gender;
  final int countryCode;

  /// 可选 yyyy-MM-dd
  final String? expiryDate;

  final int provinceId;
  final int cityId;
  final int barangayId;

  final String address;
  final int postalCode;

  /// 后端是 Record<String, any>
  final Map<String, dynamic>? ocrRawData;

  final String? placeOfBirth;
  final String? nationality;
  final String? sourceOfIncome;
  final String? natureOfWork;
  final String? employerName;


  // 图片路径 (仅用于 UI 传递，发请求时要剔除)
  @JsonKey(includeToJson: false)
  final String? idCardFront;
  @JsonKey(includeToJson: false)
  final String? idCardBack;
  @JsonKey(includeToJson: false)
  final String? faceImage;

  final Map<String, dynamic>? verifyResult;

  const SubmitKycDto({
    // required: 后端必填
    required this.sessionId,
    required this.idType,
    required this.idNumber,
    required this.realName,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.birthday,
    required this.gender,
    required this.countryCode,
    this.expiryDate,
    required this.provinceId,
    required this.cityId,
    required this.barangayId,
    required this.address,
    required this.postalCode,
    this.ocrRawData,
    this.placeOfBirth,
    this.nationality,
    this.sourceOfIncome,
    this.natureOfWork,
    this.employerName,

    // legacy optional
     this.idCardFront,
    this.idCardBack,
    this.faceImage,
    this.verifyResult,
  });

  factory SubmitKycDto.fromJson(Map<String, dynamic> json) =>
      _$SubmitKycDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SubmitKycDtoToJson(this);

  @override
  String toString() => toJson().toString();
}

/// ------------------------------
/// 7) 上传：拿签名 URL
/// ------------------------------
@JsonSerializable(checked: true)
class KycUploadUrlDto {
  final String fileName;
  final String fileType;

  KycUploadUrlDto({
    required this.fileName,
    required this.fileType,
  });

  factory KycUploadUrlDto.fromJson(Map<String, dynamic> json) =>
      _$KycUploadUrlDtoFromJson(json);

  Map<String, dynamic> toJson() => _$KycUploadUrlDtoToJson(this);

  @override
  String toString() => toJson().toString();
}

/// ------------------------------
/// 8) 上传：结果
/// ------------------------------
@JsonSerializable(checked: true)
class KycUploadResult {
  final String url;

  /// CDN 访问地址（如果后端给）
  final String cdnUrl;

  KycUploadResult({
    required this.url,
    required this.cdnUrl,
  });

  factory KycUploadResult.fromJson(Map<String, dynamic> json) =>
      _$KycUploadResultFromJson(json);

  Map<String, dynamic> toJson() => _$KycUploadResultToJson(this);

  @override
  String toString() => toJson().toString();
}

/// ------------------------------
/// 9) 兼容：只返回状态的响应
/// ------------------------------
@JsonSerializable(checked: true)
class KycResponse {
  @JsonKey(defaultValue: 0)
  final int kycStatus;

  KycResponse({required this.kycStatus});

  factory KycResponse.fromJson(Map<String, dynamic> json) =>
      _$KycResponseFromJson(json);

  Map<String, dynamic> toJson() => _$KycResponseToJson(this);

  @override
  String toString() => toJson().toString();
}