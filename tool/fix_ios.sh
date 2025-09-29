#!/bin/bash

# 第一次需要执行：chmod +x fix_ios.sh

echo "🔄 Cleaning Flutter build cache..."
flutter clean
flutter pub get

echo "📦 Cleaning iOS Pods and Flutter iOS artifacts..."
cd ios || exit
rm -rf Pods Podfile.lock .symlinks Flutter/Flutter.framework Flutter/Flutter.podspec

echo "📥 Pre-caching Flutter iOS engine..."
flutter precache --ios

echo "📥 Installing Pods..."
pod install --repo-update || pod install

cd ..

echo "🚀 Building iOS..."
flutter build ios

echo "✅ Done! Now open ios/Runner.xcworkspace in Xcode."