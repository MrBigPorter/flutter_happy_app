class WinnersQuantity {
  final int awardTotalQuantity;

  WinnersQuantity({
    required this.awardTotalQuantity,
  });

  factory WinnersQuantity.fromJson(Map<String, dynamic> json){
    return WinnersQuantity(
      awardTotalQuantity: json['awardTotalQuantity'] as int,
    );
  }

}