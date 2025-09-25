import 'package:flutter/material.dart';
import 'package:flutter_app/theme/token_theme.dart' as figma;
// rem：375 基准，>=768 宽固定 1:1
double rem(BuildContext context, double px, {double baseWidth = 375, double freezeAt = 768}) {
  final w = MediaQuery.of(context).size.width;
  if (w >= freezeAt) return px;
  return px * (w / baseWidth);
}

// 简写（取到 TokenTheme）
extension FigmaTokensX on BuildContext {
  figma.TokenTheme? get figmaTokens => Theme.of(this).extension<figma.TokenTheme>();
}
Color? _token(BuildContext ctx, String name) => figma.FigmaTokenX(ctx).figmaTokens?.color(name);

bool _isNumeric(String s) => double.tryParse(s) != null;

// 文本 twin：text-<token> / text-[16] / text-sm… / font-[600] / leading-[24] / leading-text_sm
TextStyle twText(BuildContext context, String classes, {TextStyle? base}) {
  base ??= const TextStyle();
  Color? textColor = base.color;
  double? fontSizePx;
  FontWeight? weight = base.fontWeight;
  double? heightMultiple = base.height;

  double? pendingLeadingPx;
  String? pendingLeadingAlias;

  for (final raw in classes.split(RegExp(r'\s+'))) {
    if (raw.isEmpty) continue;
    final c = raw.trim();
    final mColor = RegExp(r'^text-(.+)$').firstMatch(c);
    final looksLikeSize = RegExp(r'^text-(\[\d|xs|sm|base|md|lg|xl|[2-6]xl)').hasMatch(c);
    if (mColor != null && !looksLikeSize && !c.startsWith('leading-')) {
      textColor = _token(context, mColor.group(1)! ) ?? textColor;
      continue;
    }
    final mSizeB = RegExp(r'^text-\[(\d+(?:\.\d+)?)\]$').firstMatch(c);
    if (mSizeB != null) { fontSizePx = double.tryParse(mSizeB.group(1)!); continue; }
    final mSizeA = RegExp(r'^text-(xs|sm|base|md|lg|xl|[2-6]xl)$').firstMatch(c);
    if (mSizeA != null) { fontSizePx = _textPxFromAlias(mSizeA.group(1)!); continue; }

    final mW = RegExp(r'^font-\[(\d+)\]$').firstMatch(c);
    if (mW != null) { weight = _fw(int.parse(mW.group(1)!)); continue; }

    final mLHb = RegExp(r'^leading-\[(\d+(?:\.\d+)?)\]$').firstMatch(c);
    if (mLHb != null) { pendingLeadingPx = double.tryParse(mLHb.group(1)!); continue; }
    final mLHa = RegExp(r'^leading-text_(xs|sm|base|md|lg|xl|[2-6]xl)$').firstMatch(c);
    if (mLHa != null) { pendingLeadingAlias = mLHa.group(1)!; continue; }
  }

  if (pendingLeadingAlias != null) {
    final lh = _textPxFromAlias(pendingLeadingAlias);
    final fs = fontSizePx ?? lh;
    if (fs > 0) heightMultiple = lh / fs;
  } else if (pendingLeadingPx != null) {
    final fs = fontSizePx ?? pendingLeadingPx;
    if (fs > 0) heightMultiple = pendingLeadingPx / fs;
  }

  // 关键：高度=1.0 时不要显式设置，避免 Web 调试断言
  double? normalizedHeight;
  if (heightMultiple != null) {
    if ((heightMultiple - 1.0).abs() >= 1e-6) {
      normalizedHeight = double.parse(heightMultiple.toStringAsFixed(4));
    } else {
      normalizedHeight = null; // 交给默认行高
    }
  }

  return base.copyWith(
    color: textColor,
    fontSize: fontSizePx != null ? rem(context, fontSizePx) : base.fontSize,
    fontWeight: weight,
    height: normalizedHeight,
  );
}

double _textPxFromAlias(String a) => switch (a) {
  'xs' => 12, 'sm' => 14, 'base' || 'md' => 16, 'lg' => 18, 'xl' => 20,
  '2xl' => 24, '3xl' => 30, '4xl' => 36, '5xl' => 48, '6xl' => 60,
  _ => 14,
};
FontWeight _fw(int n) => n<=100?FontWeight.w100:n<=200?FontWeight.w200:n<=300?FontWeight.w300:
n<=400?FontWeight.w400:n<=500?FontWeight.w500:n<=600?FontWeight.w600:
n<=700?FontWeight.w700:n<=800?FontWeight.w800:FontWeight.w900;

// 盒子 twin：w-/h-/bg-/border-/rounded-/p-/shadow-*
class TwContainer extends StatelessWidget {
  final String classes;
  final Widget? child;
  final AlignmentGeometry? alignment;
  final VoidCallback? onTap;
  final Clip clipBehavior;
  const TwContainer({super.key, required this.classes, this.child, this.alignment, this.onTap, this.clipBehavior=Clip.none});

  @override
  Widget build(BuildContext context) {
    double? width, height;
    Color? bg;
    Border? border;
    BorderRadius? radius;
    EdgeInsets? padding;
    List<BoxShadow>? shadows;

    double? bw; Color? bc;
    double? pAll, pX, pY, pt, pr, pb, pl;
    Radius? rAll;

    // 尺寸
    for (final raw in classes.split(RegExp(r'\s+'))) {
      final c = raw.trim();
      final mw = RegExp(r'^w-\[(\d+(?:\.\d+)?)\]$').firstMatch(c);
      if (mw != null) { width  = rem(context, double.parse(mw.group(1)!)); continue; }
      final mh = RegExp(r'^h-\[(\d+(?:\.\d+)?)\]$').firstMatch(c);
      if (mh != null) { height = rem(context, double.parse(mh.group(1)!)); continue; }
    }

    // 其它样式
    for (final raw in classes.split(RegExp(r'\s+'))) {
      if (raw.isEmpty) continue;
      final c = raw.trim();

      // 背景：bg-[token_key] / bg-<token_key> / bg-transparent
      if (c == 'bg-transparent') { bg = Colors.transparent; continue; }
      final mBgBracket = RegExp(r'^bg-\[(.+)\]$').firstMatch(c);
      if (mBgBracket != null) { bg = _token(context, mBgBracket.group(1)!); continue; }
      if (c.startsWith('bg-') && !c.startsWith('bg-[')) {
        bg = _token(context, c.substring(3)) ?? bg; continue;
      }

      // 边框：border / border-[2] / border-[token_key] / border-2 / border-<token_key>
      if (c == 'border') { bw ??= 1; bc ??= _token(context, 'colors_border_border_primary'); continue; }

      final mBorderBracket = RegExp(r'^border-\[(.+)\]$').firstMatch(c);
      if (mBorderBracket != null) {
        final v = mBorderBracket.group(1)!;
        if (_isNumeric(v)) {
          bw = double.parse(v); bc ??= _token(context, 'colors_border_border_primary');
        } else {
          bc = _token(context, v); bw ??= 1;
        }
        continue;
      }

      final mBorderNum = RegExp(r'^border-(\d+(?:\.\d+)?)$').firstMatch(c);
      if (mBorderNum != null) { bw = double.parse(mBorderNum.group(1)!); bc ??= _token(context, 'colors_border_border_primary'); continue; }

      if (c.startsWith('border-') && !c.startsWith('border-[')) {
        // 其余一律当作 token 颜色
        bc = _token(context, c.substring(7)) ?? bc; bw ??= 1; continue;
      }

      // 圆角：rounded / rounded-[12] / rounded-sm|md|lg|xl|2xl|3xl|full
      if (c == 'rounded') { rAll ??= Radius.circular(rem(context, 8)); continue; }
      final mR = RegExp(r'^rounded-\[(\d+(?:\.\d+)?)\]$').firstMatch(c);
      if (mR != null) { rAll = Radius.circular(rem(context, double.parse(mR.group(1)!))); continue; }
      final mRalias = RegExp(r'^rounded-(sm|md|lg|xl|2xl|3xl|full)$').firstMatch(c);
      if (mRalias != null) {
        rAll = switch (mRalias.group(1)!) {
          'sm' => Radius.circular(rem(context, 6)),
          'md' => Radius.circular(rem(context, 8)),
          'lg' => Radius.circular(rem(context,10)),
          'xl' => Radius.circular(rem(context,12)),
          '2xl'=> Radius.circular(rem(context,16)),
          '3xl'=> Radius.circular(rem(context,20)),
          'full'=> const Radius.circular(9999),
          _ => Radius.circular(rem(context, 8)),
        };
        continue;
      }

      // 内边距：p-[] / px-[] / py-[] / pt/pr/pb/pl - []
      final mPAll = RegExp(r'^p-\[(\d+(?:\.\d+)?)\]$').firstMatch(c);
      if (mPAll != null) { pAll = rem(context, double.parse(mPAll.group(1)!)); continue; }
      final mPX = RegExp(r'^px-\[(\d+(?:\.\d+)?)\]$').firstMatch(c);
      if (mPX != null) { pX = rem(context, double.parse(mPX.group(1)!)); continue; }
      final mPY = RegExp(r'^py-\[(\d+(?:\.\d+)?)\]$').firstMatch(c);
      if (mPY != null) { pY = rem(context, double.parse(mPY.group(1)!)); continue; }
      final mPT = RegExp(r'^pt-\[(\d+(?:\.\d+)?)\]$').firstMatch(c);
      if (mPT != null) { pt = rem(context, double.parse(mPT.group(1)!)); continue; }
      final mPR = RegExp(r'^pr-\[(\d+(?:\.\d+)?)\]$').firstMatch(c);
      if (mPR != null) { pr = rem(context, double.parse(mPR.group(1)!)); continue; }
      final mPB = RegExp(r'^pb-\[(\d+(?:\.\d+)?)\]$').firstMatch(c);
      if (mPB != null) { pb = rem(context, double.parse(mPB.group(1)!)); continue; }
      final mPL = RegExp(r'^pl-\[(\d+(?:\.\d+)?)\]$').firstMatch(c);
      if (mPL != null) { pl = rem(context, double.parse(mPL.group(1)!)); continue; }

      // 阴影：shadow-xs|sm|md|lg|xl|2xl|3xl（走 tokens 颜色），或 shadow-[token_key]
      final mShadowBracket = RegExp(r'^shadow-\[(.+)\]$').firstMatch(c);
      if (mShadowBracket != null) {
        final col = _token(context, mShadowBracket.group(1)!);
        if (col != null) shadows = [BoxShadow(color: col, blurRadius: 10, offset: const Offset(0, 3))];
        continue;
      }
      if (c == 'shadow-xs') { shadows = [_shadowLayer(context, 'colors_effects_shadows_shadow_xs', blur: 2, dy: 1)]; continue; }
      if (c == 'shadow-sm') {
        shadows = [
          _shadowLayer(context, 'colors_effects_shadows_shadow_sm_01', blur: 6, dy: 1),
          _shadowLayer(context, 'colors_effects_shadows_shadow_sm_02', blur: 6, dy: 1),
        ]; continue;
      }
      if (c == 'shadow-md') {
        shadows = [
          _shadowLayer(context, 'colors_effects_shadows_shadow_md_01', blur: 12, dy: 3),
          _shadowLayer(context, 'colors_effects_shadows_shadow_md_02', blur: 6, dy: 2),
        ]; continue;
      }
      if (c == 'shadow-lg') {
        shadows = [
          _shadowLayer(context, 'colors_effects_shadows_shadow_lg_01', blur: 16, dy: 6),
          _shadowLayer(context, 'colors_effects_shadows_shadow_lg_02', blur: 10, dy: 4),
          _shadowLayer(context, 'colors_effects_shadows_shadow_lg_03', blur: 8, dy: 3),
        ]; continue;
      }
      if (c == 'shadow-xl') {
        shadows = [
          _shadowLayer(context, 'colors_effects_shadows_shadow_xl_01', blur: 24, dy: 8),
          _shadowLayer(context, 'colors_effects_shadows_shadow_xl_02', blur: 14, dy: 6),
          _shadowLayer(context, 'colors_effects_shadows_shadow_xl_03', blur: 10, dy: 4),
        ]; continue;
      }
      if (c == 'shadow-2xl') {
        shadows = [
          _shadowLayer(context, 'colors_effects_shadows_shadow_2xl_01', blur: 32, dy: 12),
          _shadowLayer(context, 'colors_effects_shadows_shadow_2xl_02', blur: 12, dy: 6),
        ]; continue;
      }
      if (c == 'shadow-3xl') {
        shadows = [
          _shadowLayer(context, 'colors_effects_shadows_shadow_3xl_01', blur: 48, dy: 20),
          _shadowLayer(context, 'colors_effects_shadows_shadow_3xl_02', blur: 12, dy: 6),
        ]; continue;
      }
    }

    if (bw != null || bc != null) {
      border = Border.fromBorderSide(BorderSide(
        width: bw ?? 1,
        color: bc ?? (_token(context, 'colors_border_border_primary') ?? const Color(0x1F000000)),
      ));
    }
    if (rAll != null) radius = BorderRadius.all(rAll);
    padding = EdgeInsets.fromLTRB(pl ?? pX ?? pAll ?? 0, pt ?? pY ?? pAll ?? 0, pr ?? pX ?? pAll ?? 0, pb ?? pY ?? pAll ?? 0);

    Widget content = Container(
      alignment: alignment,
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(color: bg, border: border, borderRadius: radius, boxShadow: shadows),
      clipBehavior: clipBehavior,
      child: child,
    );

    if (onTap != null) {
      content = Material(type: MaterialType.transparency, child: InkWell(borderRadius: radius, onTap: onTap, child: content));
    }
    return content;
  }

  BoxShadow _shadowLayer(BuildContext ctx, String tokenKey, {double blur = 6, double dx = 0, double dy = 1, double spread = 0}) {
    final col = _token(ctx, tokenKey) ?? Colors.black.withOpacity(0.08);
    return BoxShadow(color: col, blurRadius: blur, offset: Offset(dx, dy), spreadRadius: spread);
  }
}