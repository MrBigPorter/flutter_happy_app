class Balance {
  final double realBalance;
  final double coinBalance;

  Balance({required this.realBalance, required this.coinBalance});

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      realBalance: (json["real_balance"] ?? 0).toDouble(),
      coinBalance: (json["coin_balance"] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "real_balance": realBalance,
      "coin_balance": coinBalance,
    };
  }
}