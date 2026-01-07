import '../../../core/models/balance.dart';

enum UiTransactionType { deposit, withdraw }

/// 统一的 UI 展示模型
class TransactionUiModel {
  final String id;
  final String title;
  final double amount;
  final DateTime time;
  final String statusText;

  /// UI 状态映射:
  /// 1: Pending/Processing (进行中 - 黄色/蓝色)
  /// 2: Success (成功 - 绿色)
  /// 3: Failed/Rejected (失败 - 红色)
  final int statusCode;

  final UiTransactionType type;

  /// 用于 UI 层决定加载哪个本地图标资源
  final String? iconCode;

  TransactionUiModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.time,
    required this.statusText,
    required this.statusCode,
    required this.type,
    this.iconCode,
  });
}

/// ==================================================
/// 适配器：充值订单 -> UI模型
/// ==================================================
extension WalletRechargeHistoryItemExt on WalletRechargeHistoryItem {
  TransactionUiModel toUiModel() {
    String text;
    int code;

    // 1. 状态映射
    // rechargeStatus: 1-Pending, 2-Processing, 3-Success, 4-Failed, 5-Canceled
    switch (rechargeStatus) {
      case 1: // Pending
      case 2: // Processing
        text = "Processing";
        code = 1;
        break;
      case 3: // Success
        text = "Success";
        code = 2;
        break;
      case 4: // Failed
      case 5: // Canceled
        text = "Failed";
        code = 3;
        break;
      default:
        text = "Unknown";
        code = 1;
    }

    // 2. 标题逻辑 (核心修改)
    String methodTitle = paymentChannel ?? '';

    // 兜底逻辑：如果历史数据没有 channelName，则根据 paymentMethod 泛指
    if (methodTitle.isEmpty) {
      switch (paymentMethod) {
        case 1:
          methodTitle = "E-Wallet";
          break;
        case 2:
          methodTitle = "Online Banking";
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
    }

    return TransactionUiModel(
      id: rechargeNo,
      title: methodTitle, // 显示具体渠道名
      amount: double.tryParse(rechargeAmount) ?? 0.0,
      time: DateTime.fromMillisecondsSinceEpoch(createdAt.toInt()),
      statusText: text,
      statusCode: code,
      type: UiTransactionType.deposit,
      iconCode: channelCode,
    );
  }
}

/// ==================================================
/// 适配器：提现记录 -> UI模型
/// ==================================================
/// ==================================================
/// 适配器：提现记录 -> UI模型
/// ==================================================
extension WalletWithdrawHistoryItemExt on WalletWithdrawHistoryItem {
  TransactionUiModel toUiModel() {
    String text;
    int code;

    // 1. 状态映射 (保持不变)
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

    String methodTitle = channelName ?? '';

    if (methodTitle.isEmpty) {
      methodTitle = "Withdraw to $accountName"; // 最后的兜底
    }

    return TransactionUiModel(
      id: withdrawNo,
      title: methodTitle,
      amount: double.tryParse(actualAmount) ?? 0.0,
      time: DateTime.fromMillisecondsSinceEpoch(createdAt.toInt()),
      statusText: text,
      statusCode: code,
      type: UiTransactionType.withdraw,

      //  核心修改：传入 channelCode
      // 虽然目前的 UI 可能只是显示通用图标，但把数据传过去是好的实践
      iconCode: channelCode,
    );
  }
}