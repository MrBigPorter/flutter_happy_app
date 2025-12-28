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

KycMe _$KycMeFromJson(Map<String, dynamic> json) => $checkedCreate(
  'KycMe',
  json,
  ($checkedConvert) {
    final val = KycMe(
      kycStatus: $checkedConvert('kycStatus', (v) => (v as num?)?.toInt() ?? 0),
      id: $checkedConvert('id', (v) => v as String?),
      realName: $checkedConvert('realName', (v) => v as String?),
      idNumber: $checkedConvert('idNumber', (v) => v as String?),
      rejectReason: $checkedConvert('rejectReason', (v) => v as String?),
      idCardFront: $checkedConvert('idCardFront', (v) => v as String?),
      idCardBack: $checkedConvert('idCardBack', (v) => v as String?),
      faceImage: $checkedConvert('faceImage', (v) => v as String?),
    );
    return val;
  },
);

Map<String, dynamic> _$KycMeToJson(KycMe instance) => <String, dynamic>{
  'kycStatus': instance.kycStatus,
  'id': instance.id,
  'realName': instance.realName,
  'idNumber': instance.idNumber,
  'rejectReason': instance.rejectReason,
  'idCardFront': instance.idCardFront,
  'idCardBack': instance.idCardBack,
  'faceImage': instance.faceImage,
};

KycIdTypes _$KycIdTypesFromJson(Map<String, dynamic> json) =>
    $checkedCreate('KycIdTypes', json, ($checkedConvert) {
      final val = KycIdTypes(
        typeId: $checkedConvert('typeId', (v) => (v as num?)?.toInt() ?? 0),
        typeName: $checkedConvert('typeName', (v) => v as String? ?? ''),
        requiresFront: $checkedConvert(
          'requiresFront',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
        requiresBack: $checkedConvert(
          'requiresBack',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
        requiresOcr: $checkedConvert(
          'requiresOcr',
          (v) => (v as num?)?.toInt() ?? 0,
        ),
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

KycOcrResult _$KycOcrResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('KycOcrResult', json, ($checkedConvert) {
      final val = KycOcrResult(
        type: $checkedConvert('type', (v) => (v as num?)?.toInt() ?? 0),
        typeText: $checkedConvert('typeText', (v) => v as String? ?? 'UNKNOWN'),
        country: $checkedConvert('country', (v) => v as String? ?? 'UNKNOWN'),
        idNumber: $checkedConvert('idNumber', (v) => v as String?),
        name: $checkedConvert('name', (v) => v as String?),
        firstName: $checkedConvert('firstName', (v) => v as String?),
        middleName: $checkedConvert('middleName', (v) => v as String?),
        lastName: $checkedConvert('lastName', (v) => v as String?),
        realName: $checkedConvert('realName', (v) => v as String?),
        birthday: $checkedConvert('birthday', (v) => (v as num?)?.toInt()),
        gender: $checkedConvert('gender', (v) => v as String?),
        expiryDate: $checkedConvert('expiryDate', (v) => (v as num?)?.toInt()),
        isSuspicious: $checkedConvert(
          'isSuspicious',
          (v) => v == null ? false : _boolFromJson(v),
        ),
        fraudScore: $checkedConvert(
          'fraudScore',
          (v) => v == null ? 0.0 : _doubleFromJson(v),
        ),
        fraudReason: $checkedConvert('fraudReason', (v) => v as String?),
        rawText: $checkedConvert('rawText', (v) => v as String? ?? ''),
        idCardFront: $checkedConvert('idCardFront', (v) => v as String?),
        idCardBack: $checkedConvert('idCardBack', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$KycOcrResultToJson(KycOcrResult instance) =>
    <String, dynamic>{
      'type': instance.type,
      'typeText': instance.typeText,
      'country': instance.country,
      'idNumber': instance.idNumber,
      'name': instance.name,
      'firstName': instance.firstName,
      'middleName': instance.middleName,
      'lastName': instance.lastName,
      'realName': instance.realName,
      'birthday': instance.birthday,
      'gender': instance.gender,
      'expiryDate': instance.expiryDate,
      'idCardFront': instance.idCardFront,
      'idCardBack': instance.idCardBack,
      'isSuspicious': instance.isSuspicious,
      'fraudScore': _doubleToJson(instance.fraudScore),
      'fraudReason': instance.fraudReason,
      'rawText': instance.rawText,
    };

SubmitKycDto _$SubmitKycDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SubmitKycDto', json, ($checkedConvert) {
      final val = SubmitKycDto(
        sessionId: $checkedConvert('sessionId', (v) => v as String),
        idType: $checkedConvert('idType', (v) => (v as num).toInt()),
        idNumber: $checkedConvert('idNumber', (v) => v as String),
        realName: $checkedConvert('realName', (v) => v as String),
        firstName: $checkedConvert('firstName', (v) => v as String),
        middleName: $checkedConvert('middleName', (v) => v as String?),
        lastName: $checkedConvert('lastName', (v) => v as String),
        birthday: $checkedConvert('birthday', (v) => v as String),
        gender: $checkedConvert('gender', (v) => v as String),
        countryCode: $checkedConvert('countryCode', (v) => (v as num).toInt()),
        expiryDate: $checkedConvert('expiryDate', (v) => v as String?),
        provinceId: $checkedConvert('provinceId', (v) => (v as num).toInt()),
        cityId: $checkedConvert('cityId', (v) => (v as num).toInt()),
        barangayId: $checkedConvert('barangayId', (v) => (v as num).toInt()),
        address: $checkedConvert('address', (v) => v as String),
        postalCode: $checkedConvert('postalCode', (v) => (v as num).toInt()),
        ocrRawData: $checkedConvert(
          'ocrRawData',
          (v) => v as Map<String, dynamic>?,
        ),
        placeOfBirth: $checkedConvert('placeOfBirth', (v) => v as String?),
        nationality: $checkedConvert('nationality', (v) => v as String?),
        sourceOfIncome: $checkedConvert('sourceOfIncome', (v) => v as String?),
        natureOfWork: $checkedConvert('natureOfWork', (v) => v as String?),
        employerName: $checkedConvert('employerName', (v) => v as String?),
        idCardFront: $checkedConvert('idCardFront', (v) => v as String?),
        idCardBack: $checkedConvert('idCardBack', (v) => v as String?),
        faceImage: $checkedConvert('faceImage', (v) => v as String?),
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
      'firstName': instance.firstName,
      if (instance.middleName case final value?) 'middleName': value,
      'lastName': instance.lastName,
      'birthday': instance.birthday,
      'gender': instance.gender,
      'countryCode': instance.countryCode,
      if (instance.expiryDate case final value?) 'expiryDate': value,
      'provinceId': instance.provinceId,
      'cityId': instance.cityId,
      'barangayId': instance.barangayId,
      'address': instance.address,
      'postalCode': instance.postalCode,
      if (instance.ocrRawData case final value?) 'ocrRawData': value,
      if (instance.placeOfBirth case final value?) 'placeOfBirth': value,
      if (instance.nationality case final value?) 'nationality': value,
      if (instance.sourceOfIncome case final value?) 'sourceOfIncome': value,
      if (instance.natureOfWork case final value?) 'natureOfWork': value,
      if (instance.employerName case final value?) 'employerName': value,
      if (instance.verifyResult case final value?) 'verifyResult': value,
    };

KycUploadUrlDto _$KycUploadUrlDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('KycUploadUrlDto', json, ($checkedConvert) {
      final val = KycUploadUrlDto(
        fileName: $checkedConvert('fileName', (v) => v as String),
        fileType: $checkedConvert('fileType', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$KycUploadUrlDtoToJson(KycUploadUrlDto instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'fileType': instance.fileType,
    };

KycUploadResult _$KycUploadResultFromJson(Map<String, dynamic> json) =>
    $checkedCreate('KycUploadResult', json, ($checkedConvert) {
      final val = KycUploadResult(
        url: $checkedConvert('url', (v) => v as String),
        cdnUrl: $checkedConvert('cdnUrl', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$KycUploadResultToJson(KycUploadResult instance) =>
    <String, dynamic>{'url': instance.url, 'cdnUrl': instance.cdnUrl};

KycResponse _$KycResponseFromJson(Map<String, dynamic> json) => $checkedCreate(
  'KycResponse',
  json,
  ($checkedConvert) {
    final val = KycResponse(
      kycStatus: $checkedConvert('kycStatus', (v) => (v as num?)?.toInt() ?? 0),
    );
    return val;
  },
);

Map<String, dynamic> _$KycResponseToJson(KycResponse instance) =>
    <String, dynamic>{'kycStatus': instance.kycStatus};
