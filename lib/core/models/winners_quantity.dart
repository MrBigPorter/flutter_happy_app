class WinnersQuantity {
  final int awardTotalQuantity;

  WinnersQuantity({
    required this.awardTotalQuantity,
  });

  factory WinnersQuantity.fromJson(Map<String, dynamic> json){
    return WinnersQuantity(
      awardTotalQuantity: json['award_total_quantity'] as int,
    );
  }

}