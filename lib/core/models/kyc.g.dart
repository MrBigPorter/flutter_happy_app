// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kyc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KycSession _$KycSessionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('KycSession', json, ($checkedConvert) {
      final val = KycSession(
        sessionId: $checkedConvert('sessionId', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$KycSessionToJson(KycSession instance) =>
    <String, dynamic>{'sessionId': instance.sessionId};

KycMe _$KycMeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('KycMe', json, ($checkedConvert) {
      final val = KycMe(
        kycStatus: $checkedConvert('kycStatus', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$KycMeToJson(KycMe instance) => <String, dynamic>{
  'kycStatus': instance.kycStatus,
};

KycIdTypes _$KycIdTypesFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('KycIdTypes', json, ($checkedConvert) {
  final val = KycIdTypes(
    typeId: $checkedConvert('typeId', (v) => (v as num).toInt()),
    typeName: $checkedConvert('typeName', (v) => v as String),
    requiresFront: $checkedConvert('requiresFront', (v) => (v as num).toInt()),
    requiresBack: $checkedConvert('requiresBack', (v) => (v as num).toInt()),
    requiresOcr: $checkedConvert('requiresOcr', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$KycIdTypesToJson(KycIdTypes instance) =>
    <String, dynamic>{
      'typeId': instance.typeId,
      'typeName': instance.typeName,
      'requiresFront': instance.requiresFront,
      'requiresBack': instance.requiresBack,
      'requiresOcr': instance.requiresOcr,
    };

KycResponse _$KycResponseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('KycResponse', json, ($checkedConvert) {
      final val = KycResponse(
        kycStatus: $checkedConvert('kycStatus', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$KycResponseToJson(KycResponse instance) =>
    <String, dynamic>{'kycStatus': instance.kycStatus};

SubmitKycDto _$SubmitKycDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SubmitKycDto', json, ($checkedConvert) {
      final val = SubmitKycDto(
        sessionId: $checkedConvert('sessionId', (v) => v as String),
        idType: $checkedConvert('idType', (v) => (v as num).toInt()),
        idNumber: $checkedConvert('idNumber', (v) => v as String),
        realName: $checkedConvert('realName', (v) => v as String),
        idCardFront: $checkedConvert('idCardFront', (v) => v as String),
        idCardBack: $checkedConvert('idCardBack', (v) => v as String?),
        faceImage: $checkedConvert('faceImage', (v) => v as String),
        livenessScore: $checkedConvert(
          'livenessScore',
          (v) => (v as num?)?.toDouble(),
        ),
        videoUrl: $checkedConvert('videoUrl', (v) => v as String?),
        ocrRawData: $checkedConvert(
          'ocrRawData',
          (v) => v as Map<String, dynamic>?,
        ),
        verifyResult: $checkedConvert(
          'verifyResult',
          (v) => v as Map<String, dynamic>?,
        ),
      );
      return val;
    });

Map<String, dynamic> _$SubmitKycDtoToJson(SubmitKycDto instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'idType': instance.idType,
      'idNumber': instance.idNumber,
      'realName': instance.realName,
      'idCardFront': instance.idCardFront,
      'idCardBack': instance.idCardBack,
      'faceImage': instance.faceImage,
      'livenessScore': instance.livenessScore,
      'videoUrl': instance.videoUrl,
      'ocrRawData': instance.ocrRawData,
      'verifyResult': instance.verifyResult,
    };
