import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// RollingNumber
/// --------------
/// A “jackpot-style” rolling number widget.
///
/// - Animates **from old value to new value** whenever [value] changes
/// - Each digit scrolls vertically from old digit → new digit
/// - Supports thousand separators (commas) between digits
/// - Supports optional [prefix] widget (e.g. currency icon)
/// - Supports custom [textStyle], [itemHeight], [itemWidth]
class RollingNumber extends StatefulWidget {
  /// Target value to display.
  /// Every time this value changes, the digits will animate
  /// from the previous value to this new value.
  final int value;

  /// Height of each digit cell (one row = one digit).
  final double itemHeight;

  /// Width of each digit cell.
  final double itemWidth;

  /// Duration of the rolling animation for each change.
  final Duration duration;

  /// Whether to show thousand separators, e.g. 12,345,678.
  /// If true, a comma will be inserted between digit groups.
  final bool? enableComma;

  /// Text style for digits (and commas).
  /// If null, a default style will be used.
  final TextStyle? textStyle;

  /// Optional prefix widget, e.g.:
  ///  - an icon
  ///  - a currency symbol
  ///  - a small label
  ///
  /// This widget will be rendered on the left of the number.
  final Widget? prefix;

  const RollingNumber({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 600),
    this.itemHeight = 40.0,
    this.itemWidth = 12.0,
    this.enableComma,
    this.textStyle,
    this.prefix,
  });

  @override
  State<RollingNumber> createState() => RollingNumberState();
}

class RollingNumberState extends State<RollingNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  /// Last value before the latest change.
  /// We animate **from oldValue → widget.value**.
  int oldValue = 0;

  @override
  void initState() {
    super.initState();

    oldValue = widget.value;

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _anim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(covariant RollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When the external [value] changes, trigger a new animation.
    if (oldWidget.value != widget.value) {
      // Store previous value so we can animate from old → new.
      oldValue = oldWidget.value;

      _controller
        ..stop()
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        // Convert both old & new values to positive strings.
        // (If you need minus sign, you can handle prefix '-'.)
        final oldStr = oldValue.abs().toString();
        final newStr = widget.value.abs().toString();

        // Use the **max length** between old & new values.
        // This prevents layout glitches when length changes,
        // e.g. 999 → 1000 (3 digits → 4 digits).
        final len = oldStr.length > newStr.length ? oldStr.length : newStr.length;

        // Pad both sides with leading zeros so they have the same length.
        final o = oldStr.padLeft(len, '0');
        final n = newStr.padLeft(len, '0');

        // Convert each character into a digit int.
        final oldDigits = o.split('').map(int.parse).toList();
        final newDigits = n.split('').map(int.parse).toList();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Optional prefix (e.g. ₱, icon, label...)
            if (widget.prefix != null) ...[
              widget.prefix!,
            ],

            // Loop over each digit position.
            for (var i = 0; i < len; i++) ...[
              // Insert thousand-separator commas if:
              // - not the first digit
              // - and (len - i) is divisible by 3
              //   (i.e. we are at a thousands boundary from the right)
              if (i > 0 &&
                  (len - i) % 3 == 0 &&
                  (widget.enableComma ?? false))
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 1.w),
                  child: Text(
                    ',',
                    style: (TextStyle(
                      fontSize: context.textSm,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )).merge(widget.textStyle),
                  ),
                ),

              // Render a single rolling digit column for this position.
              RollingDigitSmooth(
                from: oldDigits[i],
                to: newDigits[i],
                progress: _anim.value,
                height: widget.itemHeight,
                width: widget.itemWidth,
                textStyle: widget.textStyle,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// RollingDigitSmooth
/// ------------------
/// A **single digit column** that smoothly scrolls from [from] → [to].
///
/// - Displays digits 0–9 stacked vertically in a column
/// - Uses [progress] (0 ~ 1) to interpolate vertical offset
/// - [height] is the visible window height (one digit high)
/// - [width] is the digit cell width
class RollingDigitSmooth extends StatelessWidget {
  /// Start digit (0–9) before the animation.
  final int from;

  /// Target digit (0–9) after the animation.
  final int to;

  /// Animation progress between 0 and 1.
  ///  - 0.0 = exactly [from]
  ///  - 1.0 = exactly [to]
  final double progress;

  /// Height of one digit cell.
  final double height;

  /// Width of one digit cell.
  final double width;

  /// Text style for the digits.
  final TextStyle? textStyle;

  const RollingDigitSmooth({
    super.key,
    required this.progress,
    required this.from,
    required this.to,
    required this.height,
    required this.width,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final itemHeight = height;

    // Digits 0–9 to build the vertical column.
    final numbers = List.generate(10, (i) => i);

    // Vertical offset for [from] & [to] positions.
    // Example: itemHeight = 40
    //  - digit 3 at offset = -3 * 40 = -120
    final start = -from * itemHeight;
    final end = -to * itemHeight;

    // Interpolate offset according to progress.
    // progress=0 → start
    // progress=1 → end
    final dy = start + (end - start) * progress;

    return ClipRect(
      // Clip to show only one digit row height.
      child: SizedBox(
        width: width,
        height: itemHeight,
        child: OverflowBox(
          // Allow child to have a fixed tall height (10 * itemHeight),
          // but we only show the clipped viewport area above.
          alignment: Alignment.topCenter,
          minHeight: itemHeight * 10,
          maxHeight: itemHeight * 10,
          child: Transform.translate(
            // Shift the whole column up/down according to [dy].
            offset: Offset(0, dy),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final n in numbers)
                  SizedBox(
                    height: itemHeight,
                    child: Center(
                      child: Text(
                        '$n',
                        style: (TextStyle(
                          fontSize: context.textSm,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        )).merge(textStyle),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}