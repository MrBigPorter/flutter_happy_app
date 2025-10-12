import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/components/skeleton.dart';

import 'package:flutter_app/core/models/page_request.dart';


/// List display mode: standard ListView or SliverList within CustomScrollView
/// - [listView]: Standard ListView
/// - [sliver]: SliverList within CustomScrollView
/// Used to optimize performance when combining with other slivers
/// in a CustomScrollView.
/// See also:
/// * [CustomScrollView], which allows combining multiple slivers.
/// * [SliverList], which is a sliver that places multiple box children in a linear array.
enum PageListMode { listView, sliver }

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

  final double skeletonSpace;

  /// Number of skeleton items to show while loading
  final int skeletonCount;

  /// Height of each skeleton item
  final double skeletonHeight;

  /// Number of items to load per page
  final int pageSize;

  /// An optional key to uniquely identify the request.
  final Object? requestKey;

  /// An optional stable ID to uniquely identify the list instance.
  /// This can be used to preserve the list state across rebuilds.
  final Object? stableId;

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

  final EdgeInsetsGeometry? skeletonPadding;

  final EdgeInsetsGeometry? skeletonMargin;

  /// The offset from the bottom of the list at which to trigger loading more
  /// data. When the user scrolls to within this distance from the bottom of
  /// the list, the next page of data will be loaded.
  /// Defaults to 200.0 logical pixels.
  final double loadMoreTriggerOffset;

  /// The display mode of the list: standard ListView or SliverList within
  final PageListMode mode;

  /// CustomScrollView. Use SliverList mode when combining with other slivers

  /// An optional external ScrollController to bind to the list view.
  /// If provided, the list view will use this controller instead of creating
  /// its own. This is useful when the list view is part of a larger scrollable
  final ScrollController? bindingController;

  const PageListViewLite({
    super.key,
    required this.request,
    required this.itemBuilder,
    this.noDataBuilder,
    this.preProcessData,
    this.space = 0,
    this.skeletonCount = 10,
    this.skeletonHeight = 100,
    this.skeletonSpace = 10,
    this.skeletonPadding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.skeletonMargin = const EdgeInsets.symmetric(vertical: 10.0),
    this.pageSize = 20,
    this.itemExtent,
    this.prototypeItem,
    this.cacheExtent = 250.0,
    this.padding,
    this.loadMoreTriggerOffset = 50.0,
    this.mode = PageListMode.listView,
    this.bindingController,
    this.requestKey,
    this.stableId,
  }) : assert(
         itemExtent == null || prototypeItem == null,
         'Cannot provide both itemExtent and prototypeItem.',
       );

  @override
  State<PageListViewLite<T>> createState() => _PageListViewLiteState<T>();
}

class _PageListViewLiteState<T> extends State<PageListViewLite<T>> {
  final _innerCtrl = ScrollController();

  /// Use the external controller if provided, else use the internal one
  ScrollController? _attachedCtrl;

  /// static data
  List<T> _items = [];
  int _total = 0;
  int _current = 0;

  /// loading state
  bool _loadingFirst = true;
  bool _loadingMore = false;
  Object? _firstError;
  Object? _moreError;

  /// avoid duplicate requests and
  /// race conditions when multiple requests are triggered
  Object? _currentKey;
  bool _pending = false;
  int _ticket = 0;

  /// The effective key to identify the current request.
  Object? get _effectiveKey =>
      widget.requestKey ?? widget.stableId ?? widget.request.hashCode;

  /// Initialize state and trigger the first data load
  @override
  void initState() {
    super.initState();
    _mountBestController();
  }

  @override
  void didUpdateWidget(covariant PageListViewLite<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// If the request function or key changes, reload the first page
    if (oldWidget.bindingController != widget.bindingController) {
      _mountBestController();
    }

    /// If the request function or key changes, reload the first page
    if (_effectiveKey != _currentKey) {
      _triggerLoadIfNeeded(widget.requestKey);
    }
  }

  @override
  void dispose() {
    /// Clean up the controller and listeners
    _detachController();
    /// Dispose the inner controller if used
    if (widget.mode == PageListMode.listView &&
        widget.bindingController == null) {
      _innerCtrl.dispose();
    }
    super.dispose();
  }

  /// Mount the best controller based on the mode and external controller
  void _mountBestController() {
    if (widget.mode == PageListMode.listView) {
      /// inner controller
      _attachController(widget.bindingController ?? _innerCtrl);
    } else {
      if (widget.bindingController != null) {
        _attachController(widget.bindingController);
      } else {
        _detachController();
      }
    }
  }

  /// Attach a scroll controller and listen for scroll events
  void _attachController(ScrollController? controller) {
    if (_attachedCtrl == controller) return;
    _detachController();
    _attachedCtrl = controller;
    _attachedCtrl?.addListener(_onScroll);
  }

  /// Detach the current scroll controller and remove listeners
  void _detachController() {
    _attachedCtrl?.removeListener(_onScroll);
    _attachedCtrl = null;
  }

  /// Whether there is more data to load
  bool get _hasMore => _items.length < _total;

  ///
  void _triggerLoadIfNeeded(Object? nextKey) {
    if (_currentKey == nextKey) return;
    _currentKey = nextKey;

    final my = ++_ticket;
    // Delay to avoid rapid successive calls
    Future.microtask(() async {
      if (!mounted || my != _ticket) return;
      await _loadFirst();
    });
  }

  /// Load the first page of data
  /// Resets the list state and fetches the first page
  Future<void> _loadFirst() async {
    if (_pending || !mounted) return;
    _pending = true;

    setState(() {
      _loadingFirst = true;
      _firstError = null;
      _items = [];
      _total = 0;
      _current = 0;
    });

    try {
      final res = await widget.request(pageSize: widget.pageSize, current: 1);
      if (!mounted) return;
      var merged = res.list;

      if (widget.preProcessData != null) {
        merged = widget.preProcessData!(merged);
      }

      if (mounted) {
        setState(() {
          _items = merged;
          _total = res.total;
          _current = res.page;
          _loadingFirst = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _firstError = e;
          _loadingFirst = false;
        });
      }
    } finally {
      _pending = false;
    }
  }

  /// Public method to reload the list
  /// Resets the list state and fetches the first page
  /// Can be called externally to refresh the list
  Future<void> reload() {
    return _loadFirst();
  }

  /// Load the next page of data
  /// Appends the new data to the existing list
  /// Only triggers if there is more data to load
  Future<void> _loadMore() async {
    if (_pending || !_hasMore || !mounted) return;

    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    _pending = true;

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

      if (mounted) {
        setState(() {
          _items = merged;
          _total = res.total;
          _current = res.page;
          _loadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _moreError = e;
          _loadingMore = false;
        });
      }
    } finally {
      _pending = false;
    }
  }

  /// Handle scroll events in listView mode
  /// to trigger loading more data when near the bottom
  /// of the list.
  /// Only triggers loading more if:
  /// - The mode is listView
  /// - There is more data to load
  /// - Not already loading
  void _onScroll() {
    final c = _attachedCtrl;

    if (c == null || !c.hasClients) return;

    final p = c.position;

    if(p.maxScrollExtent <= 0) return;

    /// pixels: current scroll position
    /// maxScrollExtent: maximum scroll extent
    /// Trigger load more when within [loadMoreTriggerOffset] of bottom
    final nearBottom =
        p.pixels >= p.maxScrollExtent - widget.loadMoreTriggerOffset;
    if (nearBottom && !_loadingFirst && !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  /// Build a skeleton loading view
  /// using the Skeleton widget
  Widget _buildSkeleton() {
    return ListView.separated(
      shrinkWrap: true,
      padding: widget.padding ?? EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, __) {
        return Container(
            padding: widget.skeletonPadding ?? EdgeInsets.zero,
            margin: widget.skeletonMargin ?? EdgeInsets.zero,
            child: Skeleton.react(
              width: double.infinity,
              height: widget.skeletonHeight,
              borderRadius: BorderRadius.circular(8.0),
            )
        );
      },
      separatorBuilder: (_, __) => SizedBox(height: widget.skeletonSpace),
      itemCount: widget.skeletonCount,
    );
  }

  /// Build the bottom status widget
  /// to show loading indicator, error message, or no more data
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
      /// show skeleton when first loading
      return _buildSkeleton();
    }

    ///  error on first load
    if (_firstError != null) {
      return Center(
        child: TextButton(onPressed: reload, child: const Text('Retry')),
      );
    }

    /// no data available
    if (_items.isEmpty) {
      return widget.noDataBuilder?.call(context) ??
          const Center(child: Text('No data available'));
    }

    /// sliver or listView mode
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

    /// The core sliver list
    /// with optional item extent optimizations
    if (widget.mode == PageListMode.sliver) {
      final sliverCore = widget.itemExtent != null
          ? SliverFixedExtentList(
              delegate: delegate,
              itemExtent: widget.itemExtent!,
            )
          : widget.prototypeItem != null
          ? SliverPrototypeExtentList(
              delegate: delegate,
              prototypeItem: widget.prototypeItem!,
            )
          : SliverList(delegate: delegate);
      return widget.padding != null
          ? SliverPadding(padding: widget.padding!, sliver: sliverCore)
          : sliverCore;
    }


    /// Standard ListView mode
    return CustomScrollView(
      controller: _attachedCtrl ?? _innerCtrl,
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
              : SliverList(delegate: delegate),
        ),
      ],
    );
  }
}
