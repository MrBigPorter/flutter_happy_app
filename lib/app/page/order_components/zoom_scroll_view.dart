import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ZoomScrollView extends StatefulWidget {
  const ZoomScrollView({super.key});

  @override
  State<ZoomScrollView> createState() => _ZoomScrollViewState();
}

class _ZoomScrollViewState extends State<ZoomScrollView>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _flingController;

  // Handle the end of a pan gesture to start a fling animation
  void _onPanEnd(DragEndDetails details) {
    final position = _scrollController.position;
    final velocityY = -details.velocity.pixelsPerSecond.dy;
    final simulation = BouncingScrollSimulation(
      position: _scrollController.offset,
      velocity: velocityY,
      leadingExtent: position.minScrollExtent,
      trailingExtent: position.maxScrollExtent,
      spring: const SpringDescription(mass: 1, stiffness: 300, damping: 30),
      tolerance: const Tolerance(
        velocity: 1.0,
        distance: 0.5,
      )
    );

    _flingController.value = _scrollController.offset;
    _flingController.animateWith(simulation);
  }

  // Update the scroll position during a pan gesture
  void _onPanUpdate(DragUpdateDetails details) {
    _scrollBy(details.delta.dy);
  }

  // Stop the fling animation when user starts dragging
  void _onPanStart(DragStartDetails details){
    _stopFling();
  }

  void _scrollBy(double dy) {
    if (!_scrollController.hasClients) return;
    // Calculate the new offset
    final newOffset = _scrollController.offset - dy;
    // get the scroll position,including maxScrollExtent, minScrollExtent, pixels
    final position = _scrollController.position;
    // get the clamped offset within the scroll extent, minScrollExtent to maxScrollExtent
    final clampedOffset = math.min(
      position.maxScrollExtent,
      math.max(position.minScrollExtent, newOffset),
    );
    // offset means the current scroll position
    // dy currently is the change in position, up is negative, down is positive
    _scrollController.jumpTo(clampedOffset);
  }

  // This method is called on each tick of the fling animation， updating the scroll position
  void _handleFlingTick() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final min = position.minScrollExtent;
    final max = position.maxScrollExtent;

    var value = _flingController.value;

    if(value < min || value>max){
      value = value.clamp(min,max);
      _flingController.stop();
    }

    _scrollController.jumpTo(value);
  }

  // stop the fling animation if it's running
  void _stopFling(){
    if(_flingController.isAnimating){
      _flingController.stop();
    }
  }

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    // unbounded means the controller can have any value, not limited to 0.0 to 1.0
    _flingController = AnimationController.unbounded(
      vsync: this,
    )..addListener(_handleFlingTick);
  }

  @override
  void dispose() {
    _flingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          color: Colors.yellow,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(100, (index) => Text('Item $index')),
          ),
        ),
      ),
    );
  }
}
