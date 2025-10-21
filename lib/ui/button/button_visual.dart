
import 'package:flutter/cupertino.dart';

/// Button visual style
/// Used for custom button variant
/// bg: background color
/// fg: foreground color (text and icon)
/// border: border color
/// shadow: box shadow
/// Example:
/// ```dart
/// ButtonVisual(
///  bg: Colors.blue,
///  fg: Colors.white,
///  border: Colors.blueAccent,
///  shadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
///  );
/// ```
/// Used in Button widget
class ButtonVisual {
  final Color bg;
  final Color fg;
  final Color border;
  final List<BoxShadow> shadow;

  ButtonVisual({
    required this.bg,
    required this.fg,
    required this.border,
    required this.shadow,
  });
}
