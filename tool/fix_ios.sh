#!/bin/bash

# 0. 先杀掉 Xcode 和 Dart，防止文件锁死导致 clean 卡住
echo "💀 Killing Xcode and Dart processes..."
killall Xcode 2>/dev/null
killall -9 dart 2>/dev/null

echo "🔄 Cleaning Flutter build cache..."
# 如果这里还卡，说明磁盘有问题，但杀掉进程通常能解决
flutter clean -v
flutter pub get

echo "📦 Cleaning iOS Pods..."
cd ios || exit
# 只删这就够了，删多了反而重新下载慢
rm -rf Pods Podfile.lock

# echo "📥 Pre-caching..."
# 这一步有时候也会卡网络，如果不需要升级引擎，可以先注释掉
# flutter precache --ios

echo "📥 Installing Pods (Fast Mode)..."
# 加上 --verbose 让你看到进度条，心里有底
pod install --verbose

cd ..

echo "✅ Done! Environment fixed."
# echo " Building..."
