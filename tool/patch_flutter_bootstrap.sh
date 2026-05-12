#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# 🔧 Patch Flutter Bootstrap — Force HTML Renderer
# ─────────────────────────────────────────────────────────────────
# 用途: 在 flutter build web --release 后执行，修改 flutter_bootstrap.js
#       确保 _flutter.loader.load() 传入 config: {renderer: 'html'}，
#       避免浏览器先下载 CanvasKit (~2-3MB) 再回退到 HTML renderer。
#
# 根因: Flutter 3.22+ 不再读取 window.__flutter.renderer，必须通过
#       _flutter.loader.load({config: {renderer: 'html'}}) 显式指定。
#       index.html 中的 window.__flutter = {renderer:'html'} 被忽略，
#       导致 _flutter.loader.load() 默认选择 canvaskit 构建产物。
#
# 用法: bash tool/patch_flutter_bootstrap.sh [build_dir]
#       默认 build_dir = build/web
# ─────────────────────────────────────────────────────────────────
set -euo pipefail

BUILD_DIR="${1:-build/web}"
BOOTSTRAP_FILE="$BUILD_DIR/flutter_bootstrap.js"

if [ ! -f "$BOOTSTRAP_FILE" ]; then
  echo "❌ Bootstrap file not found: $BOOTSTRAP_FILE"
  echo "   Run this script AFTER 'flutter build web --release'"
  exit 1
fi

# Delegate to Python for cross-platform compatibility (macOS + Linux CI)
python3 << PYEOF
import re

bootstrap_file = "$BOOTSTRAP_FILE"

with open(bootstrap_file, 'r') as f:
    content = f.read()

# Target pattern: _flutter.loader.load({serviceWorkerSettings:{...}})
# We need to inject config: {renderer: 'html'} before the final closing paren.
#
# Strategy: Find "_flutter.loader.load(" then find the matching "})" closure
# using brace counting, and insert the config before the final "})".
MARKER = "_flutter.loader.load("
CONFIG_STR = ",config:{renderer:'html'}"

if MARKER not in content:
    print("⚠️  No _flutter.loader.load() call found — skipping")
    exit(0)

# Check if config already exists
if "config:" in content and "renderer:" in content:
    print("⚠️  config: {renderer: ...} already present — skipping")
    exit(0)

# Find the load() call and insert config before the closing brace
idx = content.index(MARKER)
# Find the opening paren after MARKER
paren_start = content.index('(', idx) + 1
# Count braces to find the matching end
depth = 0
in_string = False
string_char = None
i = paren_start

while i < len(content):
    ch = content[i]
    # Handle string literals to avoid counting braces inside strings
    if in_string:
        if ch == '\\':
            i += 2
            continue
        elif ch == string_char:
            in_string = False
        i += 1
        continue
    
    if ch in ("'", '"'):
        in_string = True
        string_char = ch
        i += 1
        continue
    
    if ch == '{':
        depth += 1
    elif ch == '}':
        depth -= 1
        if depth == 0:
            # Found the closing brace — insert config before it
            # The pattern is: ...}) or ...})
            # We need to insert before the closing })
            insert_pos = i  # position of the final }
            new_content = content[:insert_pos] + CONFIG_STR + content[insert_pos:]
            with open(bootstrap_file, 'w') as f:
                f.write(new_content)
            print("✅ Patched flutter_bootstrap.js: config: {renderer: 'html'} injected")
            exit(0)
    i += 1

print("⚠️  Could not find matching brace closure — skipping")
PYEOF
