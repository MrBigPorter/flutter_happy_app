import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/transaction/transaction_card.dart';
import 'package:flutter_app/app/page/transaction/transaction_ui_model.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../components/list.dart';
import '../../core/models/balance.dart';
import '../../core/models/page_request.dart';

// 1. 定义一个函数类型别名 (这样报错会很清晰)
typedef TransactionRequestFunc = Future<PageResult<TransactionUiModel>> Function({
required int page,
required int pageSize
});

// 定义入参
typedef TransactionListParams = ({UiTransactionType type});

// 2. Provider 定义 (明确返回 TransactionRequestFunc)
final transactionListProvider = Provider.family<TransactionRequestFunc, TransactionListParams>((ref, params) {

  // 返回一个符合定义的函数
  return ({required int page, required int pageSize}) async {
    final dto = WalletTransactionsDto(page: page, pageSize: pageSize);
    final res = await Api.walletTransactionsApi(dto);

    // 示例占位:
    if (params.type == UiTransactionType.withdraw) {
      // 调用提现API...
      return PageResult(
        list: res.list
            .map((e) => e.toUiModel())
            .where((e) => e.type == UiTransactionType.withdraw)
            .toList(),
        total: res.total,
        count: res.count,
        page: res.page,
        pageSize: res.pageSize,
      );
    } else {
      final dto = WalletWithdrawHistoryDto(page: page, pageSize: pageSize);

      final res = await Api.walletWithdrawHistory(dto);
      return PageResult(
        list: res.list
            .map((e) => e.toUiModel())
            .toList(),
        total: res.total,
        count: res.count,
        page: res.page,
        pageSize: res.pageSize,
      );
    }
  };
});



// 页面主体
class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Transaction History"),
          elevation: 0,
          bottom:  TabBar(
            labelColor: context.textBrandPrimary900,
            unselectedLabelColor: context.textPrimary900,
            indicatorColor: context.borderBrand,
            tabs: [
              Tab(text: "Deposit"),
              Tab(text: "Withdraw"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TransactionListView(type: UiTransactionType.deposit),
            TransactionListView(type: UiTransactionType.withdraw),
          ],
        ),
      ),
    );
  }
}

// 列表视图组件
class TransactionListView extends ConsumerStatefulWidget {
  final UiTransactionType type;

  const TransactionListView({super.key, required this.type});

  @override
  ConsumerState<TransactionListView> createState() => _TransactionListViewState();
}

class _TransactionListViewState extends ConsumerState<TransactionListView>
    with AutomaticKeepAliveClientMixin {

  late PageListController<TransactionUiModel> _ctl;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _ctl = PageListController<TransactionUiModel>(
      requestKey: widget.type,
      request: ({required int pageSize, required int page}) {

        final TransactionRequestFunc requestFunc = ref.read(
            transactionListProvider((type: widget.type))
        );

        return requestFunc(
          pageSize: pageSize,
          page: page,
        );
      },
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return _ctl.wrapWithNotification(
      child: ExtendedVisibilityDetector(
        uniqueKey: Key('transaction_list_${widget.type.name}'),
        child: CustomScrollView(
          // 记住滚动位置
          key: PageStorageKey('transaction_list_storage_${widget.type.name}'),
          physics: const AlwaysScrollableScrollPhysics(), // 确保回弹
          cacheExtent: 600,
          slivers: [
            PageListViewPro<TransactionUiModel>(
              controller: _ctl,
              sliverMode: true,
              separatorSpace: 12.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              skeletonPadding: EdgeInsets.all(
                16.w
              ),

              // 渲染真实 Item
              itemBuilder: (context, item, index, isLast) {
                return TransactionCard(item: item);
              },

              // 渲染骨架屏
              skeletonBuilder: (context, {bool isLast = false}) {
                return  TransactionSkeleton();
              },
            ),
          ],
        ),
      ),
    );
  }
}