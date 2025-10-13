import 'package:flutter/material.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

typedef PageRequest<T> = Future<PageResult<T>> Function({
required int pageSize,
required int current,
});

typedef ItemBuilder<T> = Widget Function(
    BuildContext context,
    T item,
    int index,
    bool isLast,
    );

typedef PreProcess<T> = List<T> Function(List<T> data);

enum PageListMode { listView, sliver }


class PagedListLite<T> extends StatefulWidget {
  final PageRequest<T> request;
  final ItemBuilder<T> itemBuilder;
  final PreProcess<T>? preProcessData;
  final Widget Function(BuildContext context)? noDataBuilder;
  final int pageSize;
  final double space;
  final int skeletonCount;
  final double skeletonHeight;
  final PageListMode mode;
  final EdgeInsetsGeometry? padding;

  const PagedListLite({
    super.key,
    required this.request,
    required this.itemBuilder,
    this.preProcessData,
    this.noDataBuilder,
    this.pageSize = 10,
    this.space = 10,
    this.skeletonCount = 6,
    this.skeletonHeight = 80,
    this.mode = PageListMode.listView,
    this.padding,
  });

  @override
  State<PagedListLite<T>> createState() => _PagedListLiteState<T>();
}

/// A lightweight paginated list widget using infinite_scroll_pagination
/// Supports both ListView and SliverList modes
/// Handles loading, error, and empty states
/// Allows pre-processing of fetched data
/// Example usage:
/// ```dart
/// PagedListLite<MyItem>(
///  request: myPageRequestFunction,
///  itemBuilder: (context, item, index, isLast) {
///  return ListTile(title: Text(item.name));
///  },
///  preProcessData: (data) {
///  // Optional data processing
///  return data;
///  },
///  noDataBuilder: (context) => Center(child: Text('No items found')),
///  pageSize: 20,
///  space: 8,
///  skeletonCount: 5,
///  skeletonHeight: 70,
///  mode: PageListMode.listView,
///  padding: EdgeInsets.all(16),
///  );
///  ```
class _PagedListLiteState<T> extends State<PagedListLite<T>> {
  late final PagingController<int, T> _pagingController;

  @override
  void initState() {
    super.initState();
    _pagingController = PagingController<int, T>(
      getNextPageKey: (state) =>
      state.lastPageIsEmpty ? null : state.nextIntPageKey,
      fetchPage: _fetchPage,
    );
  }

  /// Fetch a page of data
  /// Handles errors and returns the list of items
  /// @param pageKey The key for the page to fetch
  /// @return A list of items of type T
  Future<List<T>> _fetchPage(int pageKey) async {
    try {
      final res = await widget.request(
        pageSize: widget.pageSize,
        current: pageKey,
      );
      List<T> list = res.list;
      if (widget.preProcessData != null) {
        list = widget.preProcessData!(list);
      }
      return list;
    } catch (e) {
      debugPrint('❌ Error fetching page: $e');
      rethrow;
    }
  }

  void refresh() => _pagingController.refresh();

  Widget _buildSkeleton() => ListView.separated(
    padding: widget.padding ?? EdgeInsets.zero,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: widget.skeletonCount,
    itemBuilder: (_, __) => Container(
      height: widget.skeletonHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    separatorBuilder: (_, __) => SizedBox(height: widget.space),
  );

  @override
  Widget build(BuildContext context) {
    return PagingListener(
      controller: _pagingController,
      builder: (context, state, fetchNextPage) {
        final allItems = state.items ?? [];
        final builderDelegate = PagedChildBuilderDelegate<T>(
          itemBuilder: (context, item, index) => Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : widget.space),
            child: widget.itemBuilder(
              context,
              item,
              index,
              index == allItems.length - 1,
            ),
          ),
          noItemsFoundIndicatorBuilder: (context) =>
          widget.noDataBuilder?.call(context) ??
              const Center(child: Text('No Data Found')),
          firstPageProgressIndicatorBuilder: (context) => _buildSkeleton(),
          newPageProgressIndicatorBuilder: (context) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          firstPageErrorIndicatorBuilder: (context) => Center(
            child: TextButton(
              onPressed: _pagingController.refresh,
              child: const Text('Retry'),
            ),
          ),
          newPageErrorIndicatorBuilder: (context) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: TextButton(
              onPressed: _pagingController.refresh,
              child: const Text('Retry Load More'),
            ),
          ),
        );

        if (widget.mode == PageListMode.sliver) {
          return PagedSliverList<int, T>(
            state: state,
            fetchNextPage: fetchNextPage,
            builderDelegate: builderDelegate,
          );
        } else {
          return PagedListView<int, T>(
            state: state,
            fetchNextPage: fetchNextPage,
            padding: widget.padding,
            builderDelegate: builderDelegate,
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}