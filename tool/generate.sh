#!/bin/bash
set -e
mkdir -p lib/tw

echo "🔨 Generating token files..."

# ✅  generate figma tokens documentation
dart run tool/gen_tokens_flutter.dart assets/variables.tokens.json lib/theme

# Flutter official: generate g.dart files for model and service
flutter pub run build_runner build --delete-conflicting-outputs


