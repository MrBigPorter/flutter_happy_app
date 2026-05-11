class FlashSaleSession {
  final String id;
  final String title;
  final int startTime;
  final int endTime;
  final int status;
  final int productCount;
  final int remainingMs;

  const FlashSaleSession({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.productCount,
    required this.remainingMs,
  });

  factory FlashSaleSession.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

    return FlashSaleSession(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      startTime: toInt(json['startTime']),
      endTime: toInt(json['endTime']),
      status: toInt(json['status']),
      productCount: toInt(json['productCount']),
      remainingMs: toInt(json['remainingMs']),
    );
  }
}

class FlashSaleTreasureSummary {
  final String treasureId;
  final String treasureName;
  final String? productName;
  final String? treasureCoverImg;
  final String? blurhash;
  final String unitAmount;
  final String? marketAmount;

  const FlashSaleTreasureSummary({
    required this.treasureId,
    required this.treasureName,
    this.productName,
    this.treasureCoverImg,
    this.blurhash,
    required this.unitAmount,
    this.marketAmount,
  });

  factory FlashSaleTreasureSummary.fromJson(Map<String, dynamic> json) {
    return FlashSaleTreasureSummary(
      treasureId: (json['treasureId'] ?? '').toString(),
      treasureName: (json['treasureName'] ?? '').toString(),
      productName: json['productName']?.toString(),
      treasureCoverImg: json['treasureCoverImg']?.toString(),
      blurhash: json['blurhash']?.toString(),
      unitAmount: (json['unitAmount'] ?? '0').toString(),
      marketAmount: json['marketAmount']?.toString(),
    );
  }
}

class FlashSaleTreasureDetail extends FlashSaleTreasureSummary {
  final String? treasureSeq;
  final List<String> mainImageList;
  final String? desc;
  final String? ruleContent;
  final int shippingType;
  final int groupSize;
  final int state;
  final int? salesStartAt;
  final int? salesEndAt;

  const FlashSaleTreasureDetail({
    required super.treasureId,
    required super.treasureName,
    super.productName,
    super.treasureCoverImg,
    required super.unitAmount,
    super.marketAmount,
    this.treasureSeq,
    required this.mainImageList,
    this.desc,
    this.ruleContent,
    required this.shippingType,
    required this.groupSize,
    required this.state,
    this.salesStartAt,
    this.salesEndAt,
  });

  factory FlashSaleTreasureDetail.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
    int? toNullableInt(dynamic value) => value == null
        ? null
        : (value is num ? value.toInt() : int.tryParse('$value'));

    return FlashSaleTreasureDetail(
      treasureId: (json['treasureId'] ?? '').toString(),
      treasureName: (json['treasureName'] ?? '').toString(),
      productName: json['productName']?.toString(),
      treasureCoverImg: json['treasureCoverImg']?.toString(),
      unitAmount: (json['unitAmount'] ?? '0').toString(),
      marketAmount: json['marketAmount']?.toString(),
      treasureSeq: json['treasureSeq']?.toString(),
      mainImageList: (json['mainImageList'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      desc: json['desc']?.toString(),
      ruleContent: json['ruleContent']?.toString(),
      shippingType: toInt(json['shippingType']),
      groupSize: toInt(json['groupSize']),
      state: toInt(json['state']),
      salesStartAt: toNullableInt(json['salesStartAt']),
      salesEndAt: toNullableInt(json['salesEndAt']),
    );
  }
}

class FlashSaleProductItem {
  final String id;
  final String sessionId;
  final String treasureId;
  final int flashStock;
  final String flashPrice;
  final int sortOrder;
  final bool isSoldOut;
  final FlashSaleTreasureSummary product;

  const FlashSaleProductItem({
    required this.id,
    required this.sessionId,
    required this.treasureId,
    required this.flashStock,
    required this.flashPrice,
    required this.sortOrder,
    required this.isSoldOut,
    required this.product,
  });

  factory FlashSaleProductItem.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

    return FlashSaleProductItem(
      id: (json['id'] ?? '').toString(),
      sessionId: (json['sessionId'] ?? '').toString(),
      treasureId: (json['treasureId'] ?? '').toString(),
      flashStock: toInt(json['flashStock']),
      flashPrice: (json['flashPrice'] ?? '0').toString(),
      sortOrder: toInt(json['sortOrder']),
      isSoldOut: json['isSoldOut'] == true,
      product: FlashSaleTreasureSummary.fromJson(
        Map<String, dynamic>.from(json['product'] as Map? ?? const {}),
      ),
    );
  }
}

class FlashSaleSessionProducts {
  final FlashSaleSession session;
  final List<FlashSaleProductItem> list;

  const FlashSaleSessionProducts({required this.session, required this.list});

  factory FlashSaleSessionProducts.fromJson(Map<String, dynamic> json) {
    return FlashSaleSessionProducts(
      session: FlashSaleSession.fromJson(
        Map<String, dynamic>.from(json['session'] as Map? ?? const {}),
      ),
      list: (json['list'] as List<dynamic>? ?? const [])
          .map((e) => FlashSaleProductItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class FlashSaleProductDetail {
  final String id;
  final String sessionId;
  final String treasureId;
  final int flashStock;
  final String flashPrice;
  final int sortOrder;
  final bool isSoldOut;
  final FlashSaleSession session;
  final FlashSaleTreasureDetail product;

  const FlashSaleProductDetail({
    required this.id,
    required this.sessionId,
    required this.treasureId,
    required this.flashStock,
    required this.flashPrice,
    required this.sortOrder,
    required this.isSoldOut,
    required this.session,
    required this.product,
  });

  factory FlashSaleProductDetail.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

    return FlashSaleProductDetail(
      id: (json['id'] ?? '').toString(),
      sessionId: (json['sessionId'] ?? '').toString(),
      treasureId: (json['treasureId'] ?? '').toString(),
      flashStock: toInt(json['flashStock']),
      flashPrice: (json['flashPrice'] ?? '0').toString(),
      sortOrder: toInt(json['sortOrder']),
      isSoldOut: json['isSoldOut'] == true,
      session: FlashSaleSession.fromJson(
        Map<String, dynamic>.from(json['session'] as Map? ?? const {}),
      ),
      product: FlashSaleTreasureDetail.fromJson(
        Map<String, dynamic>.from(json['product'] as Map? ?? const {}),
      ),
    );
  }
}

