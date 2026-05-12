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

# Use quoted heredoc (<< 'PYEOF') to avoid bash escaping issues.
python3 - "$BOOTSTRAP_FILE" << 'PYEOF'
import sys

bootstrap_file = sys.argv[1]

with open(bootstrap_file, 'r') as f:
    content = f.read()

MARKER = "_flutter.loader.load("
CONFIG_STR = ",config:{renderer:'html'}"

if MARKER not in content:
    print("WARNING: No _flutter.loader.load() call found - skipping")
    exit(0)

# Check if config already exists
if "config:{renderer:'html'}" in content:
    print("WARNING: config: {renderer: 'html'} already present - skipping")
    exit(0)

# Use rindex to find the LAST occurrence (avoids matching inside minified blob)
idx = content.rindex(MARKER)
paren_start = idx + len(MARKER)

# Count braces using a state machine that handles:
#   - String literals (single/double quoted)
#   - Escape sequences inside strings
#   - Block comments /* ... */ (critical: Chrome's ServiceWorker comment contains
#     single quotes like "Flutter's service worker" that would confuse simple parsing)
depth = 0
in_string = False
string_char = None

i = paren_start
while i < len(content):
    ch = content[i]

    # ── Block comment handling ──
    if ch == '/' and i + 1 < len(content) and content[i + 1] == '*':
        i += 2  # skip '/*'
        while i < len(content):
            if content[i] == '*' and i + 1 < len(content) and content[i + 1] == '/':
                i += 2  # skip '*/'
                break
            i += 1
        continue

    # ── String literal handling ──
    if in_string:
        if ch == '\\':
            i += 1  # skip escaped character
        elif ch == string_char:
            in_string = False
        i += 1
        continue

    if ch in ("'", '"'):
        in_string = True
        string_char = ch
        i += 1
        continue

    # ── Brace counting ──
    if ch == '{':
        depth += 1
    elif ch == '}':
        depth -= 1
        if depth == 0:
            # Found the matching closing brace — insert config before it
            new_content = content[:i] + CONFIG_STR + content[i:]
            with open(bootstrap_file, 'w') as f:
                f.write(new_content)
            print("Patched flutter_bootstrap.js: config: {renderer: 'html'} injected")
            exit(0)

    i += 1

print("WARNING: Could not find matching brace closure - skipping")
PYEOF
