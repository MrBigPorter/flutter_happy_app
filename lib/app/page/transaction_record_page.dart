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
    
    if (params.type == UiTransactionType.deposit) {
      return PageResult(
        list: res.list
            .map((e) => e.toUiModel())
            .where((e) => e.type == UiTransactionType.deposit)
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
    // 使用 DefaultTabController 控制 Tab 切换
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // 1. 背景色：通常金融页面的底色要稍微灰一点，突出白色卡片
        backgroundColor: context.bgSecondary, // 假设这是你的浅灰背景色

        appBar: AppBar(
          title: Text(
            "Transaction History",
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: context.textPrimary900,
                fontSize: 18.sp
            ),
          ),
          centerTitle: true,
          backgroundColor: context.bgPrimary, // 导航栏背景白色
          elevation: 0, // 去掉 AppBar 自带的阴影，我们要自己控制
          iconTheme: IconThemeData(color: context.textPrimary900),
        ),

        body: Column(
          children: [
            // 2. 高大上的胶囊 TabBar 区域
            Container(
              color: context.bgPrimary, // 保持和 AppBar 一样的背景，视觉延伸
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              child: Container(
                height: 40.h, // 控制高度，显得修长
                decoration: BoxDecoration(
                  color: context.bgSecondary, // 槽位背景色 (浅灰)
                  borderRadius: BorderRadius.circular(20.r), // 大圆角
                ),
                child: TabBar(
                  // 移除点击波纹效果，更像原生控件
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  // 指示器样式：白色悬浮胶囊 + 阴影
                  indicator: BoxDecoration(
                    color: context.bgPrimary, // 激活项背景 (白)
                    borderRadius: BorderRadius.circular(18.r), // 比外层稍微小一点
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                        spreadRadius: 0,
                      )
                    ],
                  ),
                  // 调整指示器大小以匹配 Tab
                  indicatorSize: TabBarIndicatorSize.tab,
                  // 留一点内边距，让白色胶囊看起来是“嵌”在里面的
                  indicatorPadding: EdgeInsets.all(3.w),

                  // 选中态文字样式
                  labelColor: context.textBrandPrimary900, // 品牌色或深黑
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),

                  // 未选中态文字样式
                  unselectedLabelColor: context.textSecondary700, // 灰色
                  unselectedLabelStyle: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 14.sp,
                  ),

                  // 去掉原生的下划线
                  dividerColor: Colors.transparent,

                  tabs: const [
                    Tab(text: "Deposit"),
                    Tab(text: "Withdraw"),
                  ],
                ),
              ),
            ),

            // 3. 列表区域
            const Expanded(
              child: TabBarView(
                children: [
                  TransactionListView(type: UiTransactionType.deposit),
                  TransactionListView(type: UiTransactionType.withdraw),
                ],
              ),
            ),
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
                return TransactionCard(item: item, index: index,);
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