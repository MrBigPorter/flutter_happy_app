#!/bin/bash
set -e
mkdir -p lib/tw

echo "🔨 Generating token files..."
dart run tool/gen_tokens_flutter.dart assets/variables.tokens.json lib/theme

echo " Running Build Runner..."
flutter pub run build_runner build --delete-conflicting-outputs