// PageListViewPro — Controller + View decoupled pagination (List/Sliver)
// Drop-in replacement for PageListViewLite with clearer architecture.
//
// ✅ Features
// - Controller-driven state machine (ValueNotifier)
// - Works as SliverList (NestedScrollView) or standalone ListView
// - Auto load-first, load-more (near-bottom), error/empty/skeleton
// - requestKey support (e.g., per-tab/month) to auto-reload data
// - Optional ScrollController binding (use PrimaryScrollController for NestedScrollView)
// - Optional preprocess hook to massage data before rendering
// - Item extent / prototype extent / padding / separator
//
// Usage (NestedScrollView body):
// final inner = PrimaryScrollController.of(ctx);
// final controller = PageListController<ActWinnersMonth>(
//   request: actWinnersMonthsRequest,
//   pageSize: 10,
//   scrollController: inner, // IMPORTANT for sliver mode
//   requestKey: currentMonth.value, // triggers reload when key changes
//   preprocess: preProcessWinnersData, // optional
// );
//
// return CustomScrollView(
//   controller: inner,
//   slivers: [
//     SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(ctx)),
//     PageListViewPro<ActWinnersMonth>(
//       controller: controller,
//       sliverMode: true,
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       itemBuilder: (context, item, index, isLast) => _WinnerListItem(item: item),
//     ),
//   ],
// );

import 'dart:async';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/dot_wave_loading.dart';
import 'package:flutter_app/ui/empty.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sliver_tools/sliver_tools.dart';
import '../core/models/page_request.dart';

// If you already have PageResult / PageRequest in your project, keep those and remove the typedef below.
// Expected PageResult<T> shape: { List<T> list; int page; int total; }
// typedef PageRequest<T> = Future<PageResult<T>> Function({required int pageSize, required int current});

// ────────────────────────────────────────────────────────────────────────────────
//  State Model
// ────────────────────────────────────────────────────────────────────────────────

enum PageStatus {
  idle,
  loading, // first load
  refreshing, // optional entry if you wire pull-to-refresh
  loadingMore,
  success,
  empty,
  error,
  noMore,
}

class PageListState<T> {
  final List<T> items;
  final PageStatus status;
  final bool hasMore;
  final Object? error;
  final int currentPage;
  final Object? requestKey; // for external grouping (e.g., month tab)

  const PageListState({
    this.items = const [],
    this.status = PageStatus.idle,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
    this.requestKey,
  });

  PageListState<T> copyWith({
    List<T>? items,
    PageStatus? status,
    bool? hasMore,
    Object? error,
    int? currentPage,
    Object? requestKey,
  }) {
    return PageListState<T>(
      items: items ?? this.items,
      status: status ?? this.status,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      requestKey: requestKey ?? this.requestKey,
    );
  }
}

/// Usage:
/// final controller = PageListController<YourItemType>(
///  request: yourPageRequestFunction,
///  pageSize: 20,
///  scrollController: yourScrollController, // optional
///  preprocess: yourPreprocessFunction, // optional
///  requestKey: yourRequestKey, // optional
///  );
///  also listen to controller for state changes if needed
///  PageListNotificationX.wrapWithNotification(
///  child:) yourScrollableWidget,
///  );
class PageListController<T> extends ValueNotifier<PageListState<T>> {
  final Future<PageResult<T>> Function({
    required int pageSize,
    required int page,
  })
  request;
  final int pageSize;
  final ScrollController?
  scrollController; // bind when used inside NestedScrollView (sliverMode)
  final List<T> Function(List<T>)? preprocess; // optional: sort/group/map
  final double loadMoreTriggerOffset; // near-bottom threshold
  bool _isDisposed = false;

  bool _pending = false; // global request lock
  int _ticket = 0; // anti-race id
  bool _noMoreFallback =
      false; // when total==0, rely on page size to detect no-more

  Object? _effectiveKey; // for auto reload on key change
  late String _debounceTag;

  String _tagFor(Object? key) =>
      'page-list-loadMore-${key ?? hashCode}';

  PageListController({
    required this.request,
    this.pageSize = 20,
    this.scrollController,
    this.preprocess,
    this.loadMoreTriggerOffset = 0,
    Object? requestKey,
  }) : super(PageListState<T>(requestKey: requestKey)) {
    _effectiveKey = requestKey ?? request.hashCode;
    scrollController?.addListener(_onScroll);
    _debounceTag = _tagFor(_effectiveKey);
    // auto first load
    // Use microtask to allow parent to finish build
    Future.microtask(loadFirst);
  }

  // Set/Change request key to force reload (e.g., change tab)
  void setRequestKey(Object? requestKey) {
    final nextKey = requestKey ?? request.hashCode;
    if (nextKey == _effectiveKey) return;
    // cancel pending loadMore debounce
    EasyDebounce.cancel(_debounceTag);
    _effectiveKey = nextKey;
    // update debounce tag
    _debounceTag = _tagFor(_effectiveKey);
    value = value.copyWith(requestKey: nextKey);
    loadFirst();
  }

  Future<void> loadFirst() async {
    if (_pending) return;
    _pending = true;
    _ticket++;
    final my = _ticket;

    if (_isDisposed) return;

    value = value.copyWith(
      status: PageStatus.loading,
      items: <T>[],
      currentPage: 0,
      hasMore: true,
      error: null,
    );
    _noMoreFallback = false;

    try {
      final res = await request(pageSize: pageSize, page: 1);
      if (my != _ticket || _isDisposed) return; // race drop

      List<T> data = res.list;
      if (preprocess != null) data = preprocess!(data);

      final int totalItems = res.total;
      final bool noMoreBySize = res.list.length < pageSize;
      final bool hasMore = totalItems > 0
          ? data.length < totalItems
          : !noMoreBySize;

      _noMoreFallback = _noMoreFallback || (totalItems <= 0 && noMoreBySize);

      if (_isDisposed) return;
      value = value.copyWith(
        items: data,
        status: data.isEmpty ? PageStatus.empty : PageStatus.success,
        hasMore: hasMore,
        currentPage: 1,
        error: null,
      );
    } catch (e) {
      if (my != _ticket || _isDisposed) return;
      value = value.copyWith(status: PageStatus.error, error: e);
    } finally {
      if (my == _ticket) _pending = false;
    }
  }

  Future<void> loadMore() async {

    if (_pending || !value.hasMore) return;

    if (_isDisposed) return;
    value = value.copyWith(status: PageStatus.loadingMore);

     EasyDebounce.debounce(
       _debounceTag,
      const Duration(milliseconds: 400),
      () async {
        _pending = true;
        _ticket++;
        final my = _ticket;

        value = value.copyWith(status: PageStatus.loadingMore);

        try {
          final next = value.currentPage + 1;
          final res = await request(pageSize: pageSize, page: next);
          if (my != _ticket) return; // race drop

          List<T> nextPage = res.list;
          if (preprocess != null) nextPage = preprocess!(nextPage);

          if (_isDisposed) return;
          final merged = <T>[...value.items, ...nextPage];

          final int totalItems = res.total;
          final bool noMoreBySize = res.list.length < pageSize;
          final bool hasMore = totalItems > 0 ? merged.length < totalItems
              : !noMoreBySize;
          _noMoreFallback = _noMoreFallback || (totalItems <= 0 && noMoreBySize);

          value = value.copyWith(
            items: merged,
            status: PageStatus.success,
            hasMore: hasMore,
            currentPage: next,
            error: null,
          );
        } catch (e) {
          if (my != _ticket) return;
          value = value.copyWith(status: PageStatus.error, error: e);
        } finally {
          if (my == _ticket) _pending = false;
        }
      },
    );
  }

  void _onScroll() {
    final m = scrollController?.position;
    if (m == null) return;
    if (m.pixels >= (m.maxScrollExtent - loadMoreTriggerOffset)) {
      // do not spam while first-loading
      if (value.status != PageStatus.loading &&
          value.status != PageStatus.loadingMore) {
        loadMore();
      }
    }
  }

  Future<void> refresh() => loadFirst();

  @override
  void dispose() {
    /// Mark as disposed to avoid setState after dispose
    _isDisposed = true;
    EasyDebounce.cancel(_debounceTag);

    /// Invalidate pending requests
    _ticket++;
    scrollController?.removeListener(_onScroll);
    super.dispose();
  }
}

/// Extension to auto-wrap scrollable with NotificationListener for load-more
///   (only needed if you don't use scrollController binding)
extension PageListNotificationX<T> on PageListController<T> {
  Widget wrapWithNotification({required Widget child}) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // 只有当状态正常且有更多数据时才触发
        if (n.metrics.pixels >=
            (n.metrics.maxScrollExtent - loadMoreTriggerOffset)) {
          if (value.status != PageStatus.loading &&
              value.status != PageStatus.loadingMore &&
              value.hasMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isDisposed) loadMore();
            });
          }
        }
        return false; // 不拦截
      },
      child: child,
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────────
//  View (stateless, driven by controller's ValueListenable)
// ────────────────────────────────────────────────────────────────────────────────

class PageListViewPro<T> extends StatelessWidget {
  final PageListController<T> controller;
  final Widget Function(BuildContext, T item, int index, bool isLast)
  itemBuilder;
  final bool sliverMode;

  // UI options
  final EdgeInsetsGeometry? padding;
  final double? itemExtent;
  final Widget? prototypeItem;
  final double separatorSpace;

  // placeholders
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget Function(BuildContext context, Object error, VoidCallback retry)?
  errorBuilder;
  final Widget Function(BuildContext context)?
  skeletonBuilder; // first-load placeholder
  final int skeletonCount;
  final double skeletonHeight;
  final double skeletonSpace;
  final EdgeInsetsGeometry skeletonPadding;
  final SliverGridDelegate? gridDelegate;
  final bool fillRemainingWhenShort;

  const PageListViewPro({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.sliverMode = false,
    this.padding,
    this.itemExtent,
    this.prototypeItem,
    this.separatorSpace = 0,
    this.emptyBuilder,
    this.errorBuilder,
    this.skeletonBuilder,
    this.skeletonCount = 8,
    this.skeletonHeight = 100,
    this.skeletonSpace = 12,
    this.skeletonPadding = const EdgeInsets.symmetric(horizontal: 10),
    this.gridDelegate,
    this.fillRemainingWhenShort = true,
  }) : assert(
         itemExtent == null || prototypeItem == null,
         'Provide either itemExtent or prototypeItem.',
       );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PageListState<T>>(
      valueListenable: controller,
      builder: (context, state, _) {
        switch (state.status) {
          case PageStatus.loading:
            return _buildSkeleton(context);
          case PageStatus.empty:
            return _buildEmpty(context);
          case PageStatus.error:
            return _buildError(context, state.error);
          default:
            return _buildList(context, state);
        }
      },
    );
  }

  // ── UI builders ──────────────────────────────────────────────────────────────

  Widget _buildSkeleton(BuildContext context) {
    if (gridDelegate != null) {
      final grid = SliverGrid(
        gridDelegate: gridDelegate!,
        delegate: SliverChildBuilderDelegate(
              (_, __) => skeletonBuilder?.call(context) ?? _DefaultSkeleton(height: skeletonHeight, padding: EdgeInsets.zero),
          childCount: skeletonCount,
        ),
      );
      return padding != null
          ? SliverPadding(padding: padding!, sliver: grid)
          : grid;
    }
    return ListView.separated(
      padding: padding ?? EdgeInsets.zero,
      itemCount: skeletonCount,
      separatorBuilder: (_, __) => SizedBox(height: separatorSpace.w),
      itemBuilder: (_, __) =>
      skeletonBuilder?.call(context) ?? _DefaultSkeleton(height: skeletonHeight, padding: skeletonPadding),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final w = emptyBuilder?.call(context) ?? const _DefaultEmpty();
    return sliverMode ? SliverFillRemaining(hasScrollBody: false, child: w) : w;
  }

  Widget _buildError(BuildContext context, Object? error) {
    final w = (errorBuilder != null)
        ? errorBuilder!(context, error ?? 'Unknown error', controller.loadFirst)
        : _DefaultError(onRetry: controller.loadFirst, error: error);
    return sliverMode ? SliverFillRemaining(hasScrollBody: false, child: w) : w;
  }

  Widget _buildList(BuildContext context, PageListState<T> state) {
    final list = state.items;
    

    // 是否显示底部状态（loadingMore / error / hasMore）
    final bool showBottom =
        state.hasMore ||
            state.status == PageStatus.loadingMore ||
            state.status == PageStatus.error;

    // ========== A) Grid 模式 ==========
    if (gridDelegate != null) {
      final grid = SliverGrid(
        gridDelegate: gridDelegate!,
        delegate: SliverChildBuilderDelegate(
              (ctx, index) {
            final item = list[index];
            final isLast = index == list.length - 1;
            return itemBuilder(ctx, item, index, isLast);
          },
          childCount: list.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          addSemanticIndexes: false,
        ),
      );

      //  底部状态整行显示 + 不足一屏填满
      final tail = <Widget>[
        if (showBottom)
          SliverToBoxAdapter(
            child: _BottomStatus(
              loadingMore: state.status == PageStatus.loadingMore,
              hasMore: state.hasMore,
              onRetry: controller.loadMore,
              isError: state.status == PageStatus.error,
            ),
          ),
        if (fillRemainingWhenShort)
          const SliverFillRemaining(hasScrollBody: false, child: SizedBox()),
      ];

      if (sliverMode) {
        final gridCore = padding != null
            ? SliverPadding(padding: padding!, sliver: grid)
            : grid;

        return MultiSliver(children: [
          gridCore,
          ...tail,
        ]);
      }


      Widget listCore = CustomScrollView(
        controller: controller.scrollController,
        primary: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          if (padding != null) SliverPadding(padding: padding!),
          grid,
        ],
      );
      if (controller.scrollController == null) {
        listCore = controller.wrapWithNotification(child: listCore);
      }
      return listCore;
    }


    final totalCount = list.length;

    final delegate = SliverChildBuilderDelegate(
          (ctx, index) {
        final item = list[index];
        final isLast = index == list.length - 1;
        final child = itemBuilder(ctx, item, index, isLast);
        if (separatorSpace <= 0 && padding != null) return child;
        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : separatorSpace.w),
          child: child,
        );
      },
      childCount: totalCount,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      addSemanticIndexes: false,
    );

    if (sliverMode) {
      final core = itemExtent != null
          ? SliverFixedExtentList(delegate: delegate, itemExtent: itemExtent!)
          : (prototypeItem != null
          ? SliverPrototypeExtentList(
          delegate: delegate, prototypeItem: prototypeItem!)
          : SliverList(delegate: delegate));
      if (fillRemainingWhenShort) {
        return MultiSliver(children: [
          padding != null ? SliverPadding(padding: padding!, sliver: core) : core,
          const SliverFillRemaining(hasScrollBody: false, child: SizedBox()),
        ]);
      }
      return padding != null
          ? SliverPadding(padding: padding!, sliver: core)
          : core;
    }


    return CustomScrollView(
      controller: controller.scrollController,
      primary: false,
      shrinkWrap: false,
      physics: !sliverMode ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
      slivers: [
        if (padding != null) SliverPadding(padding: padding!),
        if (itemExtent != null)
          SliverFixedExtentList(delegate: delegate, itemExtent: itemExtent!)
        else if (prototypeItem != null)
          SliverPrototypeExtentList(delegate: delegate, prototypeItem: prototypeItem!)
        else
          SliverList(delegate: delegate),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────────
//  Default UI pieces (replace in your app theme if desired)
// ────────────────────────────────────────────────────────────────────────────────

class _DefaultSkeleton extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;

  const _DefaultSkeleton({required this.height, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Skeleton.react(width: double.infinity, height: height.w),
    );
  }
}

class _DefaultEmpty extends StatelessWidget {
  const _DefaultEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [Empty()]),
    );
  }
}

class _DefaultError extends StatelessWidget {
  final VoidCallback onRetry;
  final Object? error;

  const _DefaultError({required this.onRetry, this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40),
          const SizedBox(height: 8),
          Text('Load failed', style: Theme.of(context).textTheme.bodyMedium),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text('$error', style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _BottomStatus extends StatelessWidget {
  final bool loadingMore;
  final bool hasMore;
  final bool isError;
  final VoidCallback onRetry;

  const _BottomStatus({
    required this.loadingMore,
    required this.hasMore,
    required this.onRetry,
    required this.isError,
  });

  @override
  Widget build(BuildContext context) {
    if (loadingMore) {
      return  Container(
        padding: EdgeInsets.only(top: 12.w),
        margin: EdgeInsets.only(bottom: 30.w),
        child: Center(
          child: DotsWaveLoading(),
        ),
      );
    }
    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(child: Text('— No more —')),
      );
    }
    if (isError) {
      // hasMore but not loading (e.g., after error)
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: TextButton(onPressed: onRetry, child: const Text('Retry')),
        ),
      );
    }
    return SizedBox(height: 10.w);
  }
}
