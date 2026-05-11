# ─── 环境变量 ──────────────────────────────────────────────────────────────────
# Note: Flutter 3.41.6 does not support --web-disable-service-worker.
# PWA update detection is suppressed in dev mode via kReleaseMode check in
# PwaUpdateBanner (lib/components/pwa_banners.dart).
DEV  := --dart-define-from-file=lib/core/config/env/dev.json --web-port=4000 --web-renderer html
TEST := --dart-define-from-file=lib/core/config/env/test.json
PROD := --dart-define-from-file=lib/core/config/env/prod.json

.PHONY: help \
        dev test prod \
        dev-clean test-clean prod-clean \
        clean gen gen-clean gen-watch analyze \
        ios-fix ios-nuke android-fix reset \
        dev-fix test-fix

# ══════════════════════════════════════════════════════════════════════════════
# 📋  默认目标：展示帮助（直接运行 `make` 不带参数时显示）
# ══════════════════════════════════════════════════════════════════════════════
help:
	@echo ""
	@echo "┌─────────────────────────────────────────────────────────┐"
	@echo "│              Flutter Happy App — Makefile                │"
	@echo "├─────────────────────────────────────────────────────────┤"
	@echo "│  🚀 正常运行（增量构建，速度快）                          │"
	@echo "│    make dev          dev 环境运行（端口 4000）            │"
	@echo "│    make test         test 环境运行                       │"
	@echo "│    make prod         prod 环境运行                       │"
	@echo "├─────────────────────────────────────────────────────────┤"
	@echo "│  🧹 清理后运行（构建失败时首选，比 dev 多 30-60s）        │"
	@echo "│    make dev-clean    clean + dev 运行                    │"
	@echo "│    make test-clean   clean + test 运行                   │"
	@echo "│    make prod-clean   clean + prod 运行                   │"
	@echo "├─────────────────────────────────────────────────────────┤"
	@echo "│  🔧 基础工具                                              │"
	@echo "│    make clean        flutter clean + pub get             │"
	@echo "│    make gen          build_runner 代码生成                │"
	@echo "│    make gen-clean    clean + 代码生成（解决 .g.dart 冲突）│"
	@echo "│    make gen-watch    监听模式代码生成（开发期常驻）         │"
	@echo "│    make analyze      flutter analyze 静态分析             │"
	@echo "├─────────────────────────────────────────────────────────┤"
	@echo "│  🍎 iOS 修复                                              │"
	@echo "│    make ios-fix      清理 Xcode 脏目录（最快）            │"
	@echo "│    make ios-nuke     DerivedData + CocoaPods 重装（核弹） │"
	@echo "├─────────────────────────────────────────────────────────┤"
	@echo "│  🤖 Android 修复                                          │"
	@echo "│    make android-fix  清理 Gradle 产物                    │"
	@echo "├─────────────────────────────────────────────────────────┤"
	@echo "│  💣 终极重置（全平台失败时使用，约 10 分钟）               │"
	@echo "│    make reset        所有缓存全清 + Pods 重装              │"
	@echo "└─────────────────────────────────────────────────────────┘"
	@echo ""

# ══════════════════════════════════════════════════════════════════════════════
# 🚀  正常运行（增量构建，速度快）
# ══════════════════════════════════════════════════════════════════════════════
## 开发运行（纯 flutter run，不涉及 PWA 版本注入）
## 注意：dev 环境已在 pwa_sw.js 中跳过所有 Service Worker 拦截，
##       因此不需要版本注入。生产构建（make build-web）仍保留注入。
dev:
	fvm flutter run $(DEV)

test:
	fvm flutter run $(TEST)

prod:
	fvm flutter run $(PROD)

# ══════════════════════════════════════════════════════════════════════════════
# 🧹  Clean 后运行 — 构建频繁失败时首选
#     flutter clean + pub get 能解决 90% 的增量构建问题
# ══════════════════════════════════════════════════════════════════════════════
dev-clean: clean
	fvm flutter run $(DEV)

test-clean: clean
	fvm flutter run $(TEST)

prod-clean: clean
	fvm flutter run $(PROD)

# ══════════════════════════════════════════════════════════════════════════════
# 🔧  基础工具
# ══════════════════════════════════════════════════════════════════════════════

## 彻底清理 + 重新拉依赖
clean:
	@echo "🧹 flutter clean ..."
	fvm flutter clean
	@echo "📦 flutter pub get ..."
	fvm flutter pub get
	@echo "✅ clean 完成"

## 代码生成（riverpod_generator / json_serializable）
gen:
	fvm dart run build_runner build --delete-conflicting-outputs

## Clean 后再做代码生成（出现 .g.dart 文件冲突时使用）
gen-clean: clean gen

## 持续代码生成（监听文件变更，开发期常驻）
gen-watch:
	fvm dart run build_runner watch --delete-conflicting-outputs

## 静态分析
analyze:
	fvm flutter analyze

# ══════════════════════════════════════════════════════════════════════════════
# 🍎  iOS 专项修复（按严重程度从轻到重）
# ══════════════════════════════════════════════════════════════════════════════

## 快速修复：清理 Xcode 遗留脏目录（Xcode 26 bug: "Could not delete Debug-iphoneos"）
ios-fix:
	@echo "🍎 清理 Xcode 遗留构建产物..."
	@rm -rf build/ios/Debug-iphoneos \
	         build/ios/Debug-iphonesimulator \
	         build/ios/Release-iphoneos \
	         build/ios/XCBuildData 2>/dev/null; true
	@echo "✅ 完成，可以重新 make dev"

## 深度核弹：DerivedData 全清 + CocoaPods 重装（约 5-10 分钟，最后手段）
ios-nuke: ios-fix clean
	@echo "💣 iOS 深度清理：删除 DerivedData..."
	@rm -rf ~/Library/Developer/Xcode/DerivedData 2>/dev/null; true
	@echo "📦 重装 CocoaPods..."
	cd ios && pod deintegrate && pod install
	@echo "✅ iOS 深度清理完成，运行 make dev"

# ══════════════════════════════════════════════════════════════════════════════
# 🤖  Android 专项修复
# ══════════════════════════════════════════════════════════════════════════════

## 清理 Gradle 缓存（出现 "Gradle task assembleDebug failed" 时使用）
android-fix:
	@echo "🤖 清理 Android Gradle 产物..."
	cd android && ./gradlew clean
	@echo "✅ 完成，可以重新 make dev"

# ══════════════════════════════════════════════════════════════════════════════
# 💣  终极重置 — 所有平台全崩时的最后手段（约 10 分钟）
# ══════════════════════════════════════════════════════════════════════════════
reset: clean
	@echo "💣 终极重置：清理所有平台缓存..."
	@echo "  🍎 删除 Xcode 脏目录..."
	@rm -rf build/ios/Debug-iphoneos \
	         build/ios/Debug-iphonesimulator \
	         build/ios/Release-iphoneos \
	         build/ios/XCBuildData 2>/dev/null; true
	@echo "  🍎 删除 DerivedData..."
	@rm -rf ~/Library/Developer/Xcode/DerivedData 2>/dev/null; true
	@echo "  🍎 重装 CocoaPods..."
	cd ios && pod deintegrate && pod install
	@echo "  🤖 清理 Gradle..."
	cd android && ./gradlew clean
	@echo "✅ 终极重置完成，运行 make dev"

# ══════════════════════════════════════════════════════════════════════════════
# ⏪  旧命令保留（向后兼容）
# ══════════════════════════════════════════════════════════════════════════════
dev-fix: ios-fix
	fvm flutter run $(DEV)

test-fix: ios-fix
	fvm flutter run $(TEST)

# ══════════════════════════════════════════════════════════════════════════════
# 🌐 Web 构建（自动注入 PWA 版本号）
# ══════════════════════════════════════════════════════════════════════════════

## 生产构建 Web（自动注入 PWA 版本号，构建后自动恢复占位符）
build-web:
	@echo "🔖 Injecting production SW version..."
	SW_VERSION=$$(grep '^version: ' pubspec.yaml | sed 's/version: //g' | tr -d ' \n')-$$(git rev-parse --short HEAD); \
	sed -i '' "s/{{SW_VERSION}}/$$SW_VERSION/g" web/pwa_sw.js; \
	fvm flutter build web --release $(PROD); \
	git checkout web/pwa_sw.js
	@echo "✅ Web build complete (SW_VERSION: $$SW_VERSION)"

# ══════════════════════════════════════════════════════════════════════════════
# 🤖 CI/CD Runner 工具
# ══════════════════════════════════════════════════════════════════════════════

## 启动本地 GitHub Actions Runner（处理 JoyMini 的自动部署任务）
runner-start:
	@echo "🚀 正在启动 GitHub Actions Runner..."
	cd ~/actions-runner && ./run.sh

## 以服务模式启动 Runner（后台常驻，重启不丢）
runner-service:
	@echo "📦 以系统服务模式启动 Runner..."
	cd ~/actions-runner && sudo ./svc.sh start

## 检查 Runner 运行状态
runner-status:
	cd ~/actions-runner && ./config.sh --version
	ps aux | grep Runner.Listener | grep -v grep
