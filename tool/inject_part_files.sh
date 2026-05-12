#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────
# 🔧 Inject Deferred Part Files into PWA Service Worker
# ─────────────────────────────────────────────────────────────────
# 用途: 在 flutter build web --release 后执行，扫描 build/web/
#       下所有 main.dart.js_*.part.js 文件，注入到 pwa_sw.js 的
#       PRECACHE_URLS 中。
#
# 用法: bash tool/inject_part_files.sh [build_dir]
#       默认 build_dir = build/web
# ─────────────────────────────────────────────────────────────────
set -euo pipefail

BUILD_DIR="${1:-build/web}"
SW_FILE="$BUILD_DIR/pwa_sw.js"
MARKER="DEFERRED_PART_FILES_INJECT_HERE"

if [ ! -f "$SW_FILE" ]; then
  echo "❌ SW file not found: $SW_FILE"
  echo "   Run this script AFTER 'flutter build web --release'"
  exit 1
fi

# Check if marker exists
if ! grep -q "$MARKER" "$SW_FILE"; then
  echo "⚠️  Marker '$MARKER' not found in $SW_FILE — skipping (already injected?)"
  exit 0
fi

# Delegate to Python for cross-platform compatibility (macOS + Linux CI)
python3 << PYEOF
import os, re, glob

build_dir = os.path.abspath("$BUILD_DIR")
sw_file = "$SW_FILE"
marker = "$MARKER"

# Read the SW file
with open(sw_file, 'r') as f:
    content = f.read()

# Find all part.js files and sort numerically by chunk index
part_files = glob.glob(os.path.join(build_dir, 'main.dart.js_*.part.js'))
part_files.sort(key=lambda x: int(re.search(r'_(\d+)\.part\.js$', x).group(1)))

if not part_files:
    # Remove the marker line entirely (no part files to inject)
    content = re.sub(r'^.*' + re.escape(marker) + r'.*$\n?', '', content, flags=re.MULTILINE)
    print("⚠️  No .part.js files found — removed marker line")
else:
    # Build replacement lines
    lines = []
    for pf in part_files:
        lines.append("    '/%s'" % os.path.basename(pf))
    replacement = ',\n'.join(lines)
    # Replace the entire marker line with the part file entries
    content = re.sub(
        r'^(\s*)//\s*' + re.escape(marker) + r'.*$\n?',
        replacement + ',\n',
        content,
        flags=re.MULTILINE
    )
    print("✅ Injected %d .part.js files into %s" % (len(part_files), sw_file))

with open(sw_file, 'w') as f:
    f.write(content)
PYEOF
