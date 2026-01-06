import '../../../core/models/balance.dart';

enum UiTransactionType { deposit, withdraw }

/// 统一的 UI 展示模型
class TransactionUiModel {
  final String id;
  final String title;
  final double amount;
  final DateTime time;
  final String statusText;
  /// UI 状态映射: 1:Pending/Processing, 2:Success, 3:Failed/Rejected
  final int statusCode;
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

/// 适配器：充值订单 -> UI模型
/// 修改点：针对 WalletRechargeHistoryItem 进行适配
extension WalletRechargeHistoryItemExt on WalletRechargeHistoryItem {
  TransactionUiModel toUiModel() {
    String text;
    int code;

    // rechargeStatus: 1-Pending, 2-Processing, 3-Success, 4-Failed, 5-Canceled
    switch (rechargeStatus) {
      case 1: // Pending
      case 2: // Processing
        text = "Processing";
        code = 1; // 对应 UI 的进行中颜色
        break;
      case 3: // Success
        text = "Success";
        code = 2; // 对应 UI 的成功颜色
        break;
      case 4: // Failed
      case 5: // Canceled
        text = "Failed";
        code = 3; // 对应 UI 的失败颜色
        break;
      default:
        text = "Unknown";
        code = 1;
    }

    // 根据 paymentMethod 生成标题
    // 1-GCash, 2-PayMaya, 3-Bank Transfer, 4-Card
    String methodTitle;
    switch (paymentMethod) {
      case 1:
        methodTitle = "GCash";
        break;
      case 2:
        methodTitle = "PayMaya";
        break;
      case 3:
        methodTitle = "Bank Transfer";
        break;
      case 4:
        methodTitle = "Credit/Debit Card";
        break;
      default:
        methodTitle = "Deposit";
    }

    return TransactionUiModel(
      id: rechargeNo, // 修正：使用 rechargeNo
      title: methodTitle, // 修正：使用支付方式作为标题
      amount: double.tryParse(rechargeAmount) ?? 0.0, // 修正：后端返回的是 String
      time: DateTime.fromMillisecondsSinceEpoch(createdAt.toInt()),
      statusText: text,
      statusCode: code,
      type: UiTransactionType.deposit,
    );
  }
}

/// 适配器：提现记录 -> UI模型 (保持不变)
extension WalletWithdrawHistoryItemExt on WalletWithdrawHistoryItem {
  TransactionUiModel toUiModel() {
    String text;
    int code;

    // withdrawStatus: 1-Pending Audit, 2-Approved, 3-Processing, 4-Success, 5-Rejected, 6-Failed
    switch (withdrawStatus) {
      case 1:
        text = "Pending Audit";
        code = 1;
        break;
      case 2:
        text = "Approved";
        code = 1;
        break;
      case 3:
        text = "Processing";
        code = 1;
        break;
      case 4:
        text = "Success";
        code = 2;
        break;
      case 5:
        text = "Rejected";
        code = 3;
        break;
      case 6:
        text = "Failed";
        code = 3;
        break;
      default:
        text = "Unknown";
        code = 1;
    }

    return TransactionUiModel(
      id: withdrawNo,
      title: "Withdraw to $accountName",
      amount: double.tryParse(actualAmount) ?? 0.0,
      time: DateTime.fromMillisecondsSinceEpoch(createdAt.toInt()),
      statusText: text,
      statusCode: code,
      type: UiTransactionType.withdraw,
    );
  }
}