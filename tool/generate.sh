#!/bin/bash
set -e
mkdir -p lib/tw

echo "🔨 Generating token files..."

# ✅ generate dark  theme css
dart run tool/gen_token_keys.dart assets/figma-tokens.light.json lib/tw/tw_light_tokens.g.dart

# ✅  generate light  theme css
dart run tool/gen_token_keys.dart assets/figma-tokens.dark.json  lib/tw/tw_dark_tokens.g.dart

# ✅ generate rem conversion utility
dart run tool/gen_metrics.dart assets/tw_metrics.json lib/tw/tw_metrics.dart

#  Generate alias file
dart run tool/gen_token_alias.dart assets/figma-tokens.light.json lib/theme/tokens_alias.dart

# Flutter official: generate g.dart files for model and service
flutter pub run build_runner build --delete-conflicting-outputs

echo "✅ All token files generated successfully!"