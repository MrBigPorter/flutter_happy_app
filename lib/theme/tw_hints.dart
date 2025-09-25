// lib/tw/tw_hints.dart
/// 提示/补全辅助：用常量 + 字符串插值来写 class，
/// 不改你现有的 twText / TwContainer 解析逻辑。
library;

/// 入口：Tw.c（常用颜色常量）、Tw.t（字号别名）、Tw.b（class 片段构造器）
/// 用法示例：
///   final cls = [
///     Tw.b.textColor(Tw.c.textPrimary),
///     Tw.b.textSize(Tw.t.x2l),
///     Tw.b.leadingFrom(Tw.t.x2l),
///     Tw.b.font(700),
///   ].join(' ');
class Tw {
  const Tw._();
  static const c = _TwColors();    // 颜色 token（手写常用，够用；也可配合代码生成）
  static const t = _TwTextAlias(); // 文本尺寸别名
  static const b = _TwBuild();     // Tailwind 风格 class 片段构造
}

/// —— 常用颜色 token（手写版，可自行扩展字段；也支持自定义字符串）
/// 字段值就是你 JSON 里的“扁平化键名”，如 colors_text_text_primary
class _TwColors {
  const _TwColors();

  // 文本
  final String textPrimary     = 'colors_text_text_primary';
  final String textSecondary   = 'colors_text_text_secondary';
  final String textMuted       = 'colors_text_text_muted';
  final String textOnAccent    = 'colors_text_text_on_accent';
  final String textDanger      = 'colors_text_text_danger';
  final String textSuccess     = 'colors_text_text_success';
  final String textWarning     = 'colors_text_text_warning';

  // 前景 / 图标
  final String fgPrimary       = 'colors_foreground_fg_primary';
  final String fgSecondary     = 'colors_foreground_fg_secondary';
  final String fgInverse       = 'colors_foreground_fg_inverse';

  // 背景
  final String bgPage          = 'colors_background_bg_page';
  final String bgCard          = 'colors_background_bg_card';
  final String bgElevated      = 'colors_background_bg_elevated';
  final String bgAccent        = 'colors_background_bg_accent';
  final String bgSoft          = 'colors_background_bg_soft';
  final String bgHover         = 'colors_background_bg_hover';
  final String bgSelected      = 'colors_background_bg_selected';

  // 边框
  final String borderPrimary   = 'colors_border_border_primary';
  final String borderSecondary = 'colors_border_border_secondary';
  final String borderFocus     = 'colors_effects_focusrings_focus';

  // 阴影（如果有 token）
  final String shadowSmToken   = 'colors_effects_shadows_sm';
  final String shadowMdToken   = 'colors_effects_shadows_md';

  // 组件 Alpha（如果你的 JSON 有这类）
  final String alphaDisabled   = 'componentcolors_alpha_disabled';
  final String alphaOverlay    = 'componentcolors_alpha_overlay';

  /// 自定义兜底：当你需要一个暂时没写到字段里的 token，
  /// 也可以这样用：Tw.b.textColor(Tw.c.any('colors_text_text_tertiary'))
  String any(String rawToken) => rawToken;
}

/// 尺寸别名与 Tailwind 基本一致（你 twText 里就是这么解析的）
class _TwTextAlias {
  const _TwTextAlias();
  String get xs => 'xs';
  String get sm => 'sm';
  String get base => 'base';
  String get md => 'md';
  String get lg => 'lg';
  String get xl => 'xl';
  String get x2l => '2xl';
  String get x3l => '3xl';
  String get x4l => '4xl';
  String get x5l => '5xl';
  String get x6l => '6xl';
}

/// 构造 Tailwind 风格 class 字符串片段（都返回 String）
/// 和你现有解析器完全兼容
/// 这样写就有 IDE 自动补全：Tw.b.textColor(Tw.c.textPrimary)
class _TwBuild {
  const _TwBuild();

  // —— 文本类 —— //
  String textColor(String token)  => 'text-$token';            // e.g. text-colors_text_text_primary
  String textSize(String alias)   => 'text-$alias';            // e.g. text-2xl
  String textPx(num px)           => 'text-[$px]';             // e.g. text-[15]
  String font(int w)              => 'font-[$w]';              // e.g. font-[600]
  String leadingPx(num px)        => 'leading-[$px]';          // e.g. leading-[24]
  String leadingFrom(String alias)=> 'leading-text_$alias';    // e.g. leading-text_sm

  // —— 盒子类 —— //
  String bg(String token)         => 'bg-$token';              // e.g. bg-colors_background_bg_card
  String borderColor(String token)=> 'border-$token';          // e.g. border-colors_border_border_primary
  String border()                 => 'border';                 // e.g. border（宽度默认 1）
  String borderPx(num px)         => 'border-[$px]';           // e.g. border-[2]

  String roundedPx(num px)        => 'rounded-[$px]';          // e.g. rounded-[12]
  String rounded()                => 'rounded';                // 默认 8（结合你的解析器 rem 化）

  // padding / size
  String p(num px)                => 'p-[$px]';
  String px_(num px)              => 'px-[$px]';
  String py_(num px)              => 'py-[$px]';
  String pt(num px)               => 'pt-[$px]';
  String pr(num px)               => 'pr-[$px]';
  String pb(num px)               => 'pb-[$px]';
  String pl(num px)               => 'pl-[$px]';

  String w(num px)                => 'w-[$px]';
  String h(num px)                => 'h-[$px]';

  // 阴影快捷（与你的解析器匹配）
  String get shadowSm             => 'shadow-sm';
  String get shadowMd             => 'shadow-md';
}