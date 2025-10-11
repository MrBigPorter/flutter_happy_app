import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/components/skeleton.dart';

import 'package:flutter_app/core/models/page_result.dart';


typedef PageRequest<T> =
    Future<PageResult<T>> Function({
      required int pageSize,
      required int current,
    });

/// A lightweight paginated list view widget that supports infinite scrolling,
/// skeleton loading, error handling, and custom item rendering.
/// - [T]: The type of data items in the list.
/// - [request]: A function to fetch a page of data.
/// - [itemBuilder]: A function to build each item in the list.
/// - [noDataBuilder]: An optional function to build a widget when there is no data
/// - [preProcessData]: An optional function to preprocess the data list before displaying
/// - [space]: Space between items in the list.
/// - [skeletonCount]: Number of skeleton items to show while loading.
/// - [skeletonHeight]: Height of each skeleton item.
/// - [pageSize]: Number of items to load per page.
/// - [itemExtent]: If non-null, forces the children to have the given extent in
/// the scroll direction.
/// - [prototypeItem]: If non-null, forces the children to have the same extent
/// as the given widget in the scroll direction.
/// - [cacheExtent]: The cache extent of the list view.
/// - [padding]: The amount of space by which to inset the children.
/// - [loadMoreTriggerOffset]: The offset from the bottom of the list at which to
/// trigger loading more data.
///
class PageListViewLite<T> extends StatefulWidget {
  /// Function to request a page of data
  /// - [pageSize]: Number of items per page
  /// - [current]: Current page number
  /// Returns a Future that resolves to a PageResult containing the data
  final PageRequest<T> request;

  /// Function to build each item in the list
  /// - [context]: Build context
  /// - [item]: The data item for the current index
  /// - [index]: The index of the current item
  /// - [isLast]: Whether this item is the last in the list
  /// Returns a Widget representing the item
  final Widget Function(BuildContext context, T item, int index, bool isLast)
  itemBuilder;

  /// Optional function to build a widget when there is no data
  /// - [context]: Build context
  /// Returns a Widget to display when the list is empty
  /// Optional function to preprocess the data list before displaying
  final Widget Function(BuildContext context)? noDataBuilder;

  /// - [data]: The list of data items to preprocess
  /// Returns a processed list of data items
  /// - [data]: The list of data items to preprocess
  /// Returns a processed list of data items
  final List<T> Function(List<T> data)? preProcessData;

  /// Space between items in the list
  final double space;

  /// Number of skeleton items to show while loading
  final int skeletonCount;

  /// Height of each skeleton item
  final double skeletonHeight;

  /// Number of items to load per page
  final int pageSize;

  /// If non-null, forces the children to have the given extent in the
  /// scroll direction. This is more efficient than letting the children
  /// determine their own extent because the scrolling machinery can
  /// make use of the foreknowledge.
  /// If [itemExtent] is non-null, then [prototypeItem] must be null.
  /// See also:
  ///  * [prototypeItem], which is an alternative way to provide the
  ///    [itemExtent].
  ///  * [ListView.builder], which has an [itemExtent] argument.
  ///  * [ListView], which has an [itemExtent] argument.
  ///  * [RenderBox.hasSize], which discusses the importance of knowing the
  ///    size of a render box.
  ///  * [RenderBox.size], which discusses the importance of knowing the
  ///  size of a render box.
  final double? itemExtent;

  /// If non-null, forces the children to have the same extent as the given
  /// widget in the scroll direction. This is more efficient than letting the
  /// children determine their own extent because the scrolling machinery can
  /// make use of the foreknowledge.
  final Widget? prototypeItem;

  /// The cache extent of the list view. This is the area before and after the
  /// visible part of the list that will be cached.
  /// Defaults to 250.0 logical pixels.
  final double cacheExtent;

  /// The amount of space by which to inset the children.
  /// If non-null, the list view will add padding to each side of the list.
  /// This padding is in addition to any padding that the children may have.
  /// If the list is scrollable in the vertical direction, the padding will be
  final EdgeInsetsGeometry? padding;

  /// The offset from the bottom of the list at which to trigger loading more
  /// data. When the user scrolls to within this distance from the bottom of
  /// the list, the next page of data will be loaded.
  /// Defaults to 200.0 logical pixels.
  final double loadMoreTriggerOffset;

  const PageListViewLite({
    super.key,
    required this.request,
    required this.itemBuilder,
    this.noDataBuilder,
    this.preProcessData,
    this.space = 0,
    this.skeletonCount = 10,
    this.skeletonHeight = 50,
    this.pageSize = 20,
    this.itemExtent,
    this.prototypeItem,
    this.cacheExtent = 250.0,
    this.padding,
    this.loadMoreTriggerOffset = 200.0,
  }) : assert(
         itemExtent == null || prototypeItem == null,
         'Cannot provide both itemExtent and prototypeItem.',
       );

  @override
  State<PageListViewLite<T>> createState() => _PageListViewLiteState<T>();
}

class _PageListViewLiteState<T> extends State<PageListViewLite<T>> {
  final _ctrl = ScrollController();

  /// static data
  List<T> _items = [];
  int _total = 0;
  int _current = 0;

  /// loading state
  bool _loadingFirst = true;
  bool _loadingMore = false;
  Object? _firstError;
  Object? _moreError;

  /// avoid duplicate requests
  Completer<void>? _pending;

  @override
  void initState() {
    super.initState();

    /// Listen to scroll events
    _ctrl.addListener(_onScroll);

    /// Initial load
    _loadFirst();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onScroll);
    _ctrl.dispose();
    super.dispose();
  }

  bool get _hasMore => _items.length < _total;

  Future<void> _loadFirst() async {
    if (_pending != null) return;

    setState(() {
      _loadingFirst = true;
      _firstError = null;
      _items = [];
      _total = 0;
      _current = 0;
    });

    _pending = Completer<void>();

    try {
      final res = await widget.request(pageSize: widget.pageSize, current: 1);
      var merged = res.list;

      if (widget.preProcessData != null) {
        merged = widget.preProcessData!(merged);
      }

      setState(() {
        _items = merged;
        _total = res.total;
        _current = res.page;
        _loadingFirst = false;
      });
    } catch (e) {
      setState(() {
        _firstError = e;
        _loadingFirst = false;
      });
    } finally {
      _pending?.complete();
      _pending = null;
    }
  }

  Future<void> _loadMore() async {
    if (_pending != null || !_hasMore) return;

    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    _pending = Completer<void>();

    try {
      final next = _current + 1;
      final res = await widget.request(
        pageSize: widget.pageSize,
        current: next,
      );

      var merged = [..._items, ...res.list];

      if (widget.preProcessData != null) {
        merged = widget.preProcessData!(merged);
      }

      setState(() {
        _items = merged;
        _total = res.total;
        _current = res.page;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() {
        _moreError = e;
        _loadingMore = false;
      });
    } finally {
      _pending?.complete();
      _pending = null;
    }
  }

  void _onScroll() {
    print('scroll: ${_ctrl.position.pixels}, max: ${_ctrl.position.maxScrollExtent}');
    if (!_ctrl.hasClients) return;
    final p = _ctrl.position;
    final nearBottom =
        p.pixels >= p.maxScrollExtent - widget.loadMoreTriggerOffset;

    if (nearBottom && !_loadingFirst && !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      shrinkWrap: true,
      padding: widget.padding ?? EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) {
        return Skeleton.react(
          width: double.infinity,
          height: widget.skeletonHeight,
        );
      },
      separatorBuilder: (_, __) => SizedBox(height: widget.space),
      itemCount: widget.skeletonCount,
    );
  }

  Widget _buildBottomStatus() {
    /// loading more indicator
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    /// first load error
    if (_moreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton(onPressed: _loadMore, child: const Text('Retry')),
        ),
      );
    }

    /// no more data
    /// only show when there is data
    return const SizedBox(height: 12);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingFirst) {
      return _buildSkeleton();
    }

    if (_firstError != null) {
      return Center(
        child: TextButton(onPressed: _loadFirst, child: const Text('Retry')),
      );
    }

    if (_items.isEmpty) {
      return widget.noDataBuilder?.call(context) ??
          const Center(child: Text('No data available'));
    }

    final itemCount = _items.length + 1;
    final delegate = SliverChildBuilderDelegate(
      (context, index) {
        /// bottom status already loaded whole list
        if (index == _items.length) {
          return _buildBottomStatus();
        }

        final item = _items[index];
        final isLast = index == _items.length - 1;
        final child = widget.itemBuilder(context, item, index, isLast);

        if (widget.space <= 0 && widget.padding != null) return child;

        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : widget.space),
          child: child,
        );
      },
      childCount: itemCount,

      /// Prevent unnecessary rebuilds
      addAutomaticKeepAlives: false,

      /// Prevent unnecessary rebuilds
      addRepaintBoundaries: false,

      /// Prevent unnecessary rebuilds
      addSemanticIndexes: false,
    );

    final sliver = SliverList(delegate: delegate);

    return CustomScrollView(
      controller: _ctrl,
      cacheExtent: widget.cacheExtent,
      shrinkWrap: true,
      slivers: [
        SliverPadding(
          padding: widget.padding ?? EdgeInsets.zero,
          sliver: widget.itemExtent != null
              ? SliverFixedExtentList(
                  delegate: delegate,
                  itemExtent: widget.itemExtent!,
                )
              : widget.prototypeItem != null
              ? SliverPrototypeExtentList(
                  delegate: delegate,
                  prototypeItem: widget.prototypeItem!,
                )
              : sliver,
        ),
      ],
    );
  }
}
