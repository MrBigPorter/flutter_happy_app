#!/bin/bash

# 给脚本加权限: chmod +x fix_android.sh

echo "💀 Killing Gradle & Java processes..."
# 安卓构建本质是 Java 进程，卡住通常是因为 Gradle 守护进程死锁
# 这一步非常重要，否则删文件会提示“Device or resource busy”
./android/gradlew --stop 2>/dev/null
killall -9 java 2>/dev/null

echo "🧹 Cleaning Flutter cache..."
flutter clean
flutter pub get

echo "🧨 Nuking Android build cache..."
cd android || exit

# 1. 删除项目下的 .gradle (这是 Gradle 的本地配置缓存，删了不疼)
rm -rf .gradle

# 2. 删除 App 的构建产物
rm -rf app/build
rm -rf build

# 3. 这里的 clean 是让 Gradle 自己再清理一遍，确保干净
echo "🔄 Running Gradle clean..."
./gradlew clean

cd ..

echo "✅ Android environment fixed! First build will be slower."