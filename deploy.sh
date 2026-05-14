#!/bin/bash
# ─────────────────────────────────────────────────────────────────
# 🚀 JoyMini Web Production Deployment Pipeline
# ─────────────────────────────────────────────────────────────────
# 用途: 自动化 H5 生产构建 + 脱脂 + 压缩 + 审计
# 用法: bash deploy.sh [--gzip] [--no-clean]
#
# 选项:
#   --gzip       对 .js/.css/.html 二次 gzip 压缩（服务器需支持预压缩）
#   --no-clean   跳过 build/ 清理（加速增量构建）
#
# 前置条件:
#   - FVM 已安装且配置正确
#   - 已在项目根目录 (`fvm flutter pub get` 通过)
# ─────────────────────────────────────────────────────────────────
set -euo pipefail

# ===== 颜色 =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
fail()  { echo -e "${RED}[FAIL]${NC}  $1"; exit 1; }

# ===== 参数解析 =====
DO_GZIP=false
DO_CLEAN=true
for arg in "$@"; do
  case "$arg" in
    --gzip)     DO_GZIP=true ;;
    --no-clean) DO_CLEAN=false ;;
    *)          echo "未知参数: $arg"; exit 1 ;;
  esac
done

BUILD_DIR="build/web"
START_TIME=$(date +%s)

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║      🚀 JoyMini Web Production Deployment               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ─── Step 1: Clean ───────────────────────────────────────────────
if [ "$DO_CLEAN" = true ]; then
  info "Step 1/7: 清理旧构建产物..."
  rm -rf "$BUILD_DIR"
  ok "清理完成"
else
  info "Step 1/7: 跳过清理 (--no-clean)"
fi

# ─── Step 2: Build ───────────────────────────────────────────────
# flutter_bootstrap.js 自动处理加载逻辑，无需手动调用 load()
info "Step 2/7: 生产环境构建..."
fvm flutter build web --release --no-tree-shake-icons
ok "构建完成"

# ─── Step 3: Remove NOTICES ──────────────────────────────────────
info "Step 3/7: 删除 NOTICES 文件..."
if [ -f "$BUILD_DIR/assets/NOTICES" ]; then
  rm -f "$BUILD_DIR/assets/NOTICES"
  ok "已删除 assets/NOTICES (~1.7MB)"
else
  ok "NOTICES 文件不存在，无需删除"
fi

# ─── Step 4: Remove widgetbook leaked assets ─────────────────────
info "Step 4/7: 彻底清除 widgetbook 调试残留..."
if [ -d "$BUILD_DIR/assets/packages/widgetbook" ]; then
  rm -rf "$BUILD_DIR/assets/packages/widgetbook"
  ok "已删除 widgetbook 资产泄漏"
else
  ok "无 widgetbook 泄漏残留"
fi

# ─── Step 5: Inject deferred .part.js into SW ────────────────────
info "Step 5/7: 注入 deferred .part.js 到 PWA Service Worker..."
if [ -f "tool/inject_part_files.sh" ]; then
  bash tool/inject_part_files.sh "$BUILD_DIR"
  ok "Deferred chunk 注入完成"
else
  warn "tool/inject_part_files.sh 不存在，跳过"
fi

# ─── Step 5.5: Inject SW_VERSION (unique cache name per build) ───
# CI workflow (web_deploy.yml) does this via sed before build.
# Local deploy.sh needs to do it post-build for pwa_sw.js to have
# a unique SW_VERSION, ensuring old caches are cleaned on SW activate.
info "Step 5.5/7: 注入 SW_VERSION..."
SW_VERSION=$(date +%s)
sed -i '' "s/{{SW_VERSION}}/$SW_VERSION/" "$BUILD_DIR/pwa_sw.js"
ok "SW_VERSION injected: $SW_VERSION"

# ─── Step 6: Pre-compression (可选) ──────────────────────────────
if [ "$DO_GZIP" = true ]; then
  info "Step 6/7: 对静态资源进行 gzip 预压缩..."
  find "$BUILD_DIR" -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" \) \
    -exec gzip -9 -k {} \;
  ok "gzip 预压缩完成"
else
  info "Step 6/7: 跳过 gzip 预压缩 (使用 --gzip 启用)"
fi

# ─── Step 7: Size Audit ──────────────────────────────────────────
info "Step 7/7: 📊 体积审计..."
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "────────────────────────────────────────────"
echo "  📦 构建产物体积报告"
echo "────────────────────────────────────────────"
du -sh "$BUILD_DIR" 2>/dev/null || echo " (目录不存在)"

if [ -d "$BUILD_DIR" ]; then
  echo ""
  echo "  按类型分布:"
  echo "  ┌──────────────┬─────────────┐"
  printf "  │ %-12s │ %-11s │\n" "类型" "大小"

  # main.dart.js
  MAIN_JS=$(find "$BUILD_DIR" -maxdepth 1 -name "main.dart.js" -exec du -h {} \; 2>/dev/null | cut -f1)
  [ -n "$MAIN_JS" ] && printf "  │ %-12s │ %-11s │\n" "main.dart.js" "$MAIN_JS"

  # .part.js chunks
  PART_JS=$(find "$BUILD_DIR" -maxdepth 1 -name "*.part.js" -exec du -ch {} \; 2>/dev/null | tail -1 | cut -f1)
  [ -n "$PART_JS" ] && printf "  │ %-12s │ %-11s │\n" "part.js" "$PART_JS"

  # assets
  ASSETS=$(du -sh "$BUILD_DIR/assets" 2>/dev/null | cut -f1)
  [ -n "$ASSETS" ] && printf "  │ %-12s │ %-11s │\n" "assets" "$ASSETS"

  echo "  └──────────────┴─────────────┘"
fi

echo ""
echo "────────────────────────────────────────────"
echo "  ⏱️  总耗时: ${DURATION}s"
echo "────────────────────────────────────────────"
echo ""

ok "🎉 部署流水线完成!"
echo ""
echo "  部署建议:"
echo "  ┌─── ☁️  Cloudflare Brotli 压缩 (比 gzip 高 ~20%)"
echo "  ├─── 🗄️  为 *.part.js 设置 1 年缓存 (文件名含哈希)"
echo "  └─── 🚚  上传 $BUILD_DIR/ 到服务器"
echo ""
