import 'dart:async';
import 'package:flutter/material.dart';
import 'bottom_sheet_container.dart';
import 'sheet_props.dart';

class ModalService with RouteAware {
  ModalService._();
  static final ModalService instance = ModalService._();

  final navigatorKey = GlobalKey<NavigatorState>();
  final routeObserver = RouteObserver<ModalRoute>();

  ModalRoute<dynamic>? _route;
  bool _subscribed = false;

  OverlayEntry? _entry;
  Completer? _completer;
  AnimationController? _controller;

  bool get isShowing => _entry != null;

  Future<T?> showSheet<T>({
    required Widget Function(BuildContext, void Function([T? res])) builder,
    bool clickBgToClose = true,
    Duration inDuration = const Duration(milliseconds: 360),
    Duration outDuration = const Duration(milliseconds: 260),
    Curve inCurve = Curves.easeOutCubic,
    Curve outCurve = Curves.easeInCubic,
    ModalSheetConfig config = const ModalSheetConfig(),
    bool? showClose, // 兼容旧参数
  }) async {
    if (isShowing) await close();

    final nav = navigatorKey.currentState;
    if (nav == null) throw Exception('ModalService: Navigator not ready.');
    final overlay = nav.overlay!;

    final completer = Completer<T?>();
    _completer = completer;

    _controller = AnimationController(vsync: overlay, duration: inDuration);
    final curved = CurvedAnimation(parent: _controller!, curve: inCurve, reverseCurve: outCurve);

    void finish([T? value]) async {
      await _controller?.reverse();
      if (_completer != null && !_completer!.isCompleted) {
        _completer!.complete(value);
      }
      _remove();
    }

    _entry = OverlayEntry(
      builder: (ctx) {
        final r = ModalRoute.of(ctx);
        if (!_subscribed && r != null) {
          _route = r;
          routeObserver.subscribe(this, _route!);
          _subscribed = true;
        }
        // 保持旧参数 showClose 兼容到 config
        final patched = showClose == null
            ? config
            : config.copyWith(showCloseButton: showClose);

        return BottomSheetContainer<T>(
          anim: curved,
          controller: _controller!,
          clickBgToClose: clickBgToClose,
          config: patched,
          onClose: finish,
          childBuilder: (c) => builder(c, finish),
        );
      },
    );

    overlay.insert(_entry!);
    await _controller!.forward();
    return completer.future;
  }

  Future<void> close<T>([T? value]) async {
    if (_controller != null) {
      try {
        await _controller!.reverse();
      } catch (_) {}
    }
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(value);
    }
    _remove();
  }

  void _remove() {
    _entry?.remove();
    _entry = null;
    _completer = null;
    _controller?.dispose();
    _controller = null;

    if (_subscribed) {
      routeObserver.unsubscribe(this);
      _subscribed = false;
    }
  }

  @override
  void didPushNext() {
    close();
  }
}