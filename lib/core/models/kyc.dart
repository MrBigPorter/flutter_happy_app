import 'package:json_annotation/json_annotation.dart';

part 'kyc.g.dart';

@JsonSerializable(checked: true)
class KycSession {
  final String sessionId;

  KycSession({
     required this.sessionId,
  });

  factory KycSession.fromJson(Map<String, dynamic> json) => _$KycSessionFromJson(json);

  Map<String, dynamic> toJson() => _$KycSessionToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

@JsonSerializable(checked: true)
class KycMe {
  final int kycStatus;

  KycMe({
     required this.kycStatus,
  });

  factory KycMe.fromJson(Map<String, dynamic> json) => _$KycMeFromJson(json);

  Map<String,dynamic> toJson() => _$KycMeToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}


@JsonSerializable(checked: true)
class KycIdTypes {
  final int typeId;
  final String typeName;
  final bool requiresFront;
  final bool requiresBack;
  final bool requiresOcr;

  KycIdTypes({
    required this.typeId,
    required this.typeName,
    required this.requiresFront,
    required this.requiresBack,
    required this.requiresOcr,
  });

  factory KycIdTypes.fromJson(Map<String, dynamic> json) => _$KycIdTypesFromJson(json);

  Map<String,dynamic> toJson() => _$KycIdTypesToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}

@JsonSerializable(checked: true)
class KycResponse {
  final int kycStatus;

  KycResponse({
    required this.kycStatus,
  });

  factory KycResponse.fromJson(Map<String, dynamic> json) => _$KycResponseFromJson(json);

  Map<String,dynamic> toJson() => _$KycResponseToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }

}

@JsonSerializable(checked: true)
class SubmitKycDto {
  final String sessionId;
  final int idType;
  final String idNumber;
  final String realName;
  final String idCardFront;
  final String? idCardBack;
  final String faceImage;
  final double? livenessScore;
  final String? videoUrl;
  final Map<String, dynamic>? ocrRawData;
  final Map<String, dynamic>? verifyResult;

  SubmitKycDto({
    required this.sessionId,
    required this.idType,
    required this.idNumber,
    required this.realName,
    required this.idCardFront,
    this.idCardBack,
    required this.faceImage,
    this.livenessScore,
    this.videoUrl,
    this.ocrRawData,
    this.verifyResult,
  });

  factory SubmitKycDto.fromJson(Map<String, dynamic> json) => _$SubmitKycDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SubmitKycDtoToJson(this);

  @override
  String toString() {
    return toJson().toString();
  }
}
