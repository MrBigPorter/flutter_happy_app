import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'modal_sheet_config.dart';

enum SheetSide { bottom }

class ModalService with RouteAware {
  ModalService._();

  static final ModalService instance = ModalService._();


  final navigatorKey = GlobalKey<NavigatorState>();
  final routeObserver = RouteObserver<ModalRoute>();

  ModalRoute<dynamic>? route;
  bool _subscribed = false;

  OverlayEntry? _entry;
  Completer? _completer;
  AnimationController? _controller;

  bool get isShowing => _entry != null;

  Future<T?> showSheet<T>({
    required Widget Function(
      BuildContext context,
      void Function([T? res]) close,
    )
    builder,
    ModalSheetConfig config = const ModalSheetConfig(),
    bool clickBgToClose = true,
    bool showClose = true,
    Duration inDuration = const Duration(milliseconds: 360),
    Duration outDuration = const Duration(milliseconds: 260),
    Curve inCurve = Curves.easeOutCubic,
    Curve outCurve = Curves.easeInCubic,
    double maxWidth = double.infinity,
  }) async {
    // Close existing modal if any
    if(isShowing) await close();

    // navigator and overlay
    // overlay is defined in the navigator,top overlay is following navigator management,lifecycle same as navigator
    final nav = navigatorKey.currentState;
    if(nav == null){
      throw Exception("ModalService: Navigator is not ready yet.");
    }
    // get overlay from navigator
    final OverlayState overlay = nav.overlay!;

    // create completer to wait for modal result, future complete when modal closed
    // it contains the future result type T to return when modal closed
    final completer = Completer<T?>();
    _completer = completer;

    _controller = AnimationController(vsync: overlay, duration: inDuration);
    final curved = CurvedAnimation(parent: _controller!, curve: inCurve, reverseCurve: outCurve);

    void finish([T? value]) async {
      close(value);
    }

    _entry = OverlayEntry(
      builder: (ctx){
        //使用 OverlayEntry.builder 的 context
        final r = ModalRoute.of(ctx);
        if(!_subscribed && r != null){
          route = r;
          routeObserver.subscribe(this, route!);
          _subscribed = true;
        }

        return _BottomSheetLayer<T>(
          config: config,
          anim: curved,
          controller: _controller!,
          clickBgToClose: clickBgToClose,
          showClose: showClose,
          maxWidth: maxWidth,
          onClose: finish,
          childBuilder:(c)=> builder(c, finish),
        );
      }
    );

    overlay.insert(_entry!);

    await _controller!.forward();
    return completer.future;
  }

  // Method to close the modal
  Future<void> close<T>([T? value]) async {
    if(_controller != null){
      await _controller!.reverse();
    }
    if(_completer != null && !_completer!.isCompleted){
      _completer!.complete(null);
    }

    _remove();
  }

  // Internal method to remove the overlay entry
  void _remove() {
    _entry?.remove();
    _entry = null;
    _completer = null;

    if(_subscribed){
      routeObserver.unsubscribe(this);
      _subscribed = false;
    }
  }

  // RouteAware overrides, close modal when navigating to another page
  @override
  void didPushNext() {
    close();
  }
}


class _BottomSheetLayer<T> extends StatelessWidget{
  final Animation<double> anim;
  final AnimationController controller;
  final bool clickBgToClose;
  final bool showClose;
  final double maxWidth;
  final void Function([T?]) onClose;
  final Widget Function(BuildContext) childBuilder;
  final ModalSheetConfig config;

  const _BottomSheetLayer({
    super.key,
    required this.anim,
    required this.controller,
    required this.clickBgToClose,
    required this.showClose,
    required this.maxWidth,
    required this.onClose,
    required this.childBuilder,
    this.config = const ModalSheetConfig(),
  });

  @override
  Widget build(BuildContext context) {
    
    final media = MediaQuery.of(context);
    final vw = media.size.width;
    final vh = media.size.height;
    // final saveBtm = media.padding.bottom; // safe area bottom
    final saveBtm = 0.0; // safe area bottom
    final sideGap = 0.0; // side gap
    // final maxSheetWidth = vw - sideGap * 2; // max sheet width
    final maxSheetWidth = vw - sideGap * 2; // max sheet width
    final maxScreenHeight = vh * config.maxHeightFactor; // max screen height

    // bg fade in
    final backdrop = AnimatedBuilder(
        animation: anim,
        builder: (_,__)=> Opacity(
          opacity: anim.value.clamp(0.01, 1.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: clickBgToClose ? () => onClose() : null,
            child: Container(
                color: config.theme.barrierColor ?? Colors.black.withValues(alpha: 0.5)
            ),
          ),
        )
    );

    // panel slide in from bottom
    final panel = Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: sideGap,
          right: sideGap,
          bottom: saveBtm,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            // 宽度 = min(屏幕宽-两侧留白, 上限)
            maxWidth: maxWidth,
            maxHeight: maxScreenHeight,
          ).tighten(
            // 额外再给一个上限，平板时更优雅
            width: vw.clamp(0, maxSheetWidth + sideGap * 2) as double?,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 0.w),
            child: AnimatedBuilder(
              animation: anim,
              builder: (_,child) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 1),end: Offset.zero).animate(anim),
                child: child,
              ),
              child: SizedBox(
                width: double.infinity,
                child: _SheetSurface(
                  config: config,
                  onClose: onClose,
                  child: childBuilder(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Stack(children: [backdrop, panel],);

  }
}

class _SheetSurface extends StatelessWidget {
  final ModalSheetConfig config;
  final VoidCallback onClose;
  final Widget child;

  const _SheetSurface({
    required this.config,
    required this.onClose,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return GestureDetector(
      onVerticalDragUpdate: config.enableDragToClose ? (details){
        if(details.delta.dy > config.dragToCloseThreshold){
          onClose();
        }
      } : null,
      child: Material(
        color: config.theme.surfaceColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(config.borderRadius)),
        elevation: 16,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: Padding(
          padding:  config.contentPadding.add(
            EdgeInsets.only(bottom: mq.padding.bottom)
          ),
          child: Stack(
            children: [
              Padding(padding: EdgeInsets.only(top: config.showCloseButton ? 16.w : 0), child: child),
              if(config.showCloseButton)
                Positioned(
                  right: 8,
                  top: 0,
                  child: IconButton(
                      onPressed: onClose,
                      icon: Icon(Icons.close, size: 24.w)
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

extension OverlayStateTicker on OverlayState {
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}