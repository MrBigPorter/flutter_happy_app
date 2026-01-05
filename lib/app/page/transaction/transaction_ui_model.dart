
import '../../../core/models/balance.dart';


enum UiTransactionType { deposit, withdraw }

/// 统一的 UI 展示模型
class TransactionUiModel {
  final String id;
  final String title;
  final double amount;
  final DateTime time;
  final String statusText;
  final int statusCode; // 1:Pending, 2:Success, 3:Failed
  final UiTransactionType type;

  TransactionUiModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.time,
    required this.statusText,
    required this.statusCode,
    required this.type,
  });
}

/// 适配器：充值/交易记录 -> UI模型
extension WalletTransactionItemExt on WalletTransactionItem {
  TransactionUiModel toUiModel() {
    // 假设 transactionType=1 是充值
    final isDeposit = transactionType == 1;

    return TransactionUiModel(
      id: transactionNo,
      title: description ?? (isDeposit ? "Deposit" : "Transaction"),
      amount: double.tryParse(amount) ?? 0.0,
      // 后端是 num 类型的时间戳，转 DateTime
      time: DateTime.fromMillisecondsSinceEpoch(createdAt.toInt()),
      statusText: "Success", // 流水记录一般都是成功的
      statusCode: 2, // 2 = Success
      type: UiTransactionType.deposit,
    );
  }
}

/// 适配器：提现记录 -> UI模型
extension WalletWithdrawHistoryItemExt on WalletWithdrawHistoryItem {
  TransactionUiModel toUiModel() {
    String text;
    int code;

    // 你的 DTO 注释: [ 1, 2, 3 ] for [Pending, Approved, Rejected]
    switch (withdrawStatus) {
      case 1:
        text = "Pending";
        code = 1;
        break;
      case 2:
        text = "Success";
        code = 2;
        break;
      case 3:
        text = "Rejected";
        code = 3;
        break;
      default:
        text = "Unknown";
        code = 0;
    }

    return TransactionUiModel(
      id: withdrawNo,
      title: "Withdraw to $accountName",
      amount: double.tryParse(amount) ?? 0.0,
      time: DateTime.fromMillisecondsSinceEpoch(createdAt.toInt()),
      statusText: text,
      statusCode: code,
      type: UiTransactionType.withdraw,
    );
  }
}