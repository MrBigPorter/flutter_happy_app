---

# Lucky Flutter App — Copilot Working Instructions

> **Important**: Always check `## 🎯 Current Task` at the start of every conversation. Proceed according to the defined phases; do not implement features outside the current plan.

---

# Lucky Flutter App 核心规则索引

# 1. 引导指令
每次对话开始，请立即读取并严格遵守以下路径中的项目规范和任务进度：
- 核心指令文件: .github/copilot-instructions.md
- 快速启动指南: docs/AI_QUICK_START.md

# 2. 技术栈约束 (Phase F1)
- 状态管理: 必须使用 Riverpod。
- 路由系统: 必须使用 GoRouter。
- 语言要求: 严禁出现韩文，仅限中英文回复与注释。

# 3. 自动化任务
- 任务追踪: 完成任务后，更新 .github/copilot-instructions.md 中的 [ ] 状态。
- 生成代码: 修改模型后必须执行 build_runner。

# 4. AI 行为规则
## 4.1 决策框架
### 可自主执行的任务：
- ✅ 明确原因的 Bug 修复
- ✅ 文档更新
- ✅ UI 样式调整
- ✅ 依赖版本更新
- ✅ 代码格式化

### 需要询问用户的任务：
- ❓ 架构变更
- ❓ 新功能实现
- ❓ 安全相关修改
- ❓ 影响核心流程的性能优化
- ❓ 数据库结构变更

### 必须使用完整沟通协议的任务：
- 📋 所有"重大变更"（详见 docs/AI_COLLABORATION_WORKFLOW.md）
- 📋 影响多个模块的变更
- 📋 回滚策略不明确的变更
- 📋 涉及金融/支付的变更

## 4.2 响应风格
- 保持直接和技术性
- 避免对话性填充词
- 始终包含 task_progress 检查列表
- 记录命令执行结果

## 4.3 错误处理
- 首先检查 docs/ERROR_PATTERNS.md
- 检查 DEBUG_NOTES/ 目录
- 如果是新错误，记录解决方案供未来参考
- 永远不要假设成功，必须验证

## 4.4 代码质量标准
- 遵循 analysis_options.yaml 规则
- 使用有意义的变量名
- 复杂业务逻辑添加注释
- 函数保持在 50 行以内
- 金额字段必须使用 JsonNumConverter.toDouble
- build() 方法内业务逻辑不超过 3 行
- 禁止硬编码颜色/尺寸，使用生成的设计令牌

## 4.5 测试要求
- 新功能：最少 1 个 Unit + 1 个 Widget 测试
- Bug 修复：必须添加回归测试
- 模型变更：必须测试 fromJson/toJson
- 提交前运行：fvm flutter analyze && fvm flutter test


## 🎯 Current Task (Start every conversation here)

**Phase**: Phase F1 — Flutter Commercial Loop Closure  
**Last Stop**: Lucky Wheel UX Optimization Completed (2026-03-25)  
**Accomplishments**:
- [x] **Customer Service Shunting Parameterization**: `CustomerServiceHelper.startChat()` now supports `support/business` scenarios with configurable `businessId`.
- [x] **Lucky Draw API Integration**: `my-tickets` / `draw` / `my-results`.
- [x] **Lucky Draw Pages & Routing**: Ticket lists, drawing execution, history results (base skeleton).
- [x] **Flash Sale Frontend States**: Added flash sale pricing, countdown timers, inventory tracking, and "end of sale" states.
- [x] **Checkout Integration**: Implemented flash sale ID forwarding (e.g., `flashSaleProductId`, subject to backend contract) and unified payment/order price terminology.
- [x] **Testing & Error Handling**: Added minimal Provider/Widget tests and handled key edge cases for the above changes.
- [x] **OAuth Base Layer**: Integrated `Google/Facebook/Apple` API + Model + Provider (UI/SDK excluded).
- [x] **Admin Handoff Documentation**: Created `admin/FLUTTER_OAUTH_INTEGRATION_GUIDE_CN.md`.
- [x] **Startup Logo Unification Plan**: Drafted `STARTUP_LOGO_UNIFICATION_PLAN.md`.
- [x] **Automated Testing Manual**: Created `AUTOMATED_TESTING_MANUAL.md`.
- [x] **OAuth Login UI Closure**: Implemented login page third-party buttons + loading/error states + invitation code forwarding.
- [x] **OAuth Platform SDK Integration**: Google/Facebook/Apple (displayed conditionally by platform).
- [x] **OAuth Minimal Testing**: Added Provider failure states + Login page Widget branching.
- [x] **Auth Field Alignment & Cleanup**: Resolved `avatar/avartar` typos and aligned `Profile.lastLoginAt` types with the backend.
- [x] **PWA Update Fix**: Implemented build-time version injection (`{{SW_VERSION}}`) into `web/pwa_sw.js`. Modified `Makefile` dev target + `build-web` target. Added CI/CD injection step in `full_deploy.yml`. Added Flutter SW update listener in `index.html`.
- [x] **PWA Dev Environment Fix**: Dev SW now skips all interception on `localhost`. `make dev` simplified to pure `fvm flutter run $(DEV)` — no version injection, no file pollution. Production build (`build-web`) retains version injection.

**Current Iteration — Lucky Draw UI Closure (2026-03-24)**:
- [x] **Lucky Draw Result Dialog**: Implemented `LuckyDrawResultDialog` with 4 prize-specific styles (Coupons/Coins/Balance/Better Luck Next Time).
- [x] **Prize Icons/Badges**: Displayed `prizeType` specific icons and colors in ticket and result lists.
- [x] **Ticket Expiry Display**: Displayed `expiredAt` fields with red highlighting for tickets expiring within 24 hours.
- [x] **Infinite Scrolling**: Enabled pagination for `luckyDrawTicketsProvider` and `luckyDrawResultsProvider`.
- [x] **Order Success Banner**: Displayed "Ticket Earned" banner on the order results page with navigation to the Draw page.
- [x] **Socket Push Loop**: Handled `lucky_draw_ticket_issued` events (Badge +1, notification card, deep-linking); implemented `group_success` fallback refresh; configured FCM `lucky_draw` cold-start routing; added red dot badge to Me page menu.
- [x] **Lucky Wheel UX Optimization**: Added entry instructions card / Drawing-in-progress layered states / Post-draw result actions / Success callback refresh / Small screen adaptation / Minimal Provider+Widget tests.
- [x] **Home Featured Image Fix**: Fixed image cropping in `home_featured.dart` — changed container from 343×288 (landscape) to 343×343 (square 1:1) to match 1024×1024 source images; added `UrlResolver.resolveImage()` for consistent URL pre-processing.
- [x] **Fixed Result Dialog Visibility**: Fixed `LuckyDrawActionResult.fromJson` to handle `isWin` field; added debug logs to track dialog display flow.
- [x] **Fixed Lucky Wheel Animation Stuck Issue**: Fixed `_LuckyWheelState._onResult` controller logic to ensure dialog appears upon animation completion.
- [x] **Fixed Animation Not Running**: Resolved vsync issues by creating a local animation controller within `_LuckyWheelState`.
- [x] **Fixed Wheel Not Rotating**: Implemented continuous rotation animation and added `_rotationAnimation` listener to update angles.
- [x] **Optimized Animation Smoothness**: Increased rotation to 8-11 laps and extended duration to 5.5s for better visual flow.
- [x] **Fixed Animation Completion Listener**: Fixed state listener to ensure dialog pops up immediately after animation ends.
- [x] **Complete Fix for Animation Failure**: Simplified listener management and removed complex reset logic to ensure animation starts correctly.
- [x] **Fixed Navigator State Errors**: Implemented safe navigation using `maybePop` and added navigator state checks to prevent crashes on empty stacks.

**New Iteration — Home Page Performance Phase 1: Image Instant-Load System (2026-03-25)**:
- [x] **Weakness Analysis**: Identified bottlenecks in image loading, network requests, rendering, and first-paint speed.
- [x] **4-Tier Cache Architecture**: Implemented L1 Memory → L2 Disk → L3 CDN → L4 Origin.
- [x] **Image Preloading System**: Implemented critical path preloading, smart concurrency control, and de-duplication.
- [x] **4-Tier Cache Manager**: Developed LRU memory cache, smart disk cache, and hit rate statistics.
- [x] **Responsive Image Service**: Implemented device adaptation, format optimization (WebP/AVIF), and quality adjustment.
- [x] **Performance Monitoring**: Developed full-link monitoring, multi-dimensional stats, and real-time reporting.
- [x] **Unified Initializer**: One-stop initialization with lazy-start and state management.
- [x] **Dependency Updates**: Added `flutter_cache_manager` and `synchronized`.
- [x] **Technical Documentation**: Created `docs/IMAGE_OPTIMIZATION_PHASE1.md`.
- [x] **Component Integration**: Updated `AppCachedImage` to use the new cache system.
- [x] **Integration Testing**: Verified performance gains on the home page.
- [x] **Performance Benchmarking**: Compared key metrics before and after optimization.

**Phase 1 Completion Summary**:
✅ **Core Architecture Completed**: Four-tier cache, preloading, responsive images, and performance monitoring systems.
✅ **Documentation Finalized**: Detailed design docs, integration guides, and troubleshooting manuals.
✅ **Dependencies Updated**: Added necessary packages for system operation.
✅ **Compilation Errors Resolved**: Fixed errors in `image_preloader.dart`, `performance_monitor.dart`, and `responsive_image_service.dart`.
✅ **Home Page Integration Guide**: Created `docs/HOME_PAGE_IMAGE_OPTIMIZATION_INTEGRATION.md`.
✅ **Expected Results**: 50-70% reduction in image load times; 70-80% cache hit rate.

**Next Step — Phase 2: Home Page Image Optimization Implementation (Completed 2026-03-25)**:
- [x] **OptimizedImage Component**: Wrapped the new cache system while maintaining API compatibility.
- [x] **SwiperBanner Update**: Replaced image components in the carousel.
- [x] **HomeTreasures Update**: Replaced image components in the product waterfall.
- [x] **Smart Preloading**: Implemented proactive preloading of critical images during home page initialization.
- [x] **Monitoring Integration**: Added performance monitoring panel and real-time metrics to the home page.
- [x] **Responsive Service Integration**: Generates optimal image URLs based on device characteristics.
- [x] **Testing & Validation**: Created test scripts and validation reports.

**Phase 2 Completion Summary**:
✅ **Core Components Completed**: OptimizedImage component, monitoring panel, and test scripts.
✅ **Home Page Integration Completed**: SwiperBanner, HomeTreasures, and ProductItem all migrated to optimized components.
✅ **Preloading System Completed**: Intelligent home page preloading with priority scheduling.
✅ **Performance Monitoring Completed**: Real-time stats panel with multi-dimensional monitoring metrics.
✅ **Responsive Images Completed**: Device adaptation, format optimization, and quality adjustment.
✅ **Testing Validated**: Complete test suite and effect validation report.

**Phase 2 Expected Results**:
- 40-50% reduction in home page image load times.
- 30-40% reduction in first-screen load times.
- 50% reduction in perceived load time.
- Cache hit rate improved to 70-80%.
- 20-30% reduction in data consumption (via responsive images).

**Emergency Fix — Image Loading Inconsistency (Completed 2026-03-26)**:
- [x] **Root Cause Analysis**: Identified double CDN processing, overly strict data validation, and decoding errors.
- [x] **Fixed ImageCacheManager Data Size Check**: Adjusted 100-byte limit to a more reasonable value.
- [x] **Enhanced Error Handling**: Implemented better fallback strategies for decoding errors (added `errorBuilder` to `Image.memory`).
- [x] **Fixed CDN URL De-duplication**: Verified `RemoteUrlBuilder.fitAbsoluteUrl` handles this correctly.
- [x] **Enhanced Logging**: Added detailed error logging to `OptimizedImage`.
- [x] **Validation**: Verified code via Flutter analyze.

**Emergency Fix Completion Summary**:
✅ **Root Cause Identified**: Double CDN processing (collision between `RemoteUrlBuilder.fitAbsoluteUrl` in SwiperBanner and `ResponsiveImageService` inside OptimizedImage).
✅ **Core Fixes Completed**:
- Removed `RemoteUrlBuilder.fitAbsoluteUrl` from SwiperBanner to pass raw URLs.
- Added `errorBuilder` to `OptimizedImage` for graceful degradation.
- Adjusted `ImageCacheManager` validation to prevent misjudging small images.
- Enhanced `ResponsiveImageService` with CDN prefix detection to prevent double processing.
  ✅ **Debugging Enhanced**: Added detailed logs to critical paths for troubleshooting.
  ✅ **Compilation Verified**: Passed `flutter analyze` with no errors.

**Fix Results**:
- Eliminated image load failures caused by URL format confusion.
- Decoding errors no longer crash the app, but degrade gracefully to error placeholders.
- Image loading process is now more stable and reliable.

**Next Steps**:
- Continue monitoring production image performance metrics.
- Investigate CDN-side image formats if specific images still fail.
- Consider implementing an image data integrity verification mechanism.

**New Iteration — Product Detail Page Performance Optimization & Image Prefetching (Completed 2026-03-26)**:
- [x] **Weakness Analysis**: Analyzed `product_detail_page.dart` load latency, hit rates, and prefetch opportunities.
- [x] **Design Solution**: Designed a prefetch strategy tailored for product details.
- [x] **Implementation**: Migrated all image components to `OptimizedImage` (detail page already uses `OptimizedImageFactory`).
- [x] **Prefetch Mechanism**: Created `ProductDetailPreloader` to manage key detail page images.
- [x] **Lazy Loading Integration**: Confirmed `GridView` native lazy loading is sufficient.
- [x] **Monitoring Integration**: Added `performance_monitor` imports for future detailed monitoring.
- [x] **Validation**: Passed `dart analyze` with no compilation errors.
- [x] **Documentation**: Updated project docs and `copilot-instructions.md`.

**Product Detail Optimization Summary**:
✅ **Core Prefetch System Completed**: `ProductDetailPreloader` class, supporting product cover and group-buy avatar prefetching.
✅ **Smart Scheduling**: Supports de-duplicated prefetching, concurrency control, and batch optimization.
✅ **Seamless Integration**: Integrated into `ProductItem`; details images prefetch automatically upon product click.
✅ **Quality Assurance**: Passed static analysis with no compilation errors.
✅ **Compatibility**: Fully compatible with `OptimizedImage` and four-tier cache architecture.

**Optimization Expected Results**:
- 50-70% reduction in product detail image load times.
- 80-90% cache hit rate for critical images.
- 60-80% reduction in perceived switching latency.

**Emergency Fix — Google/Facebook Button Loading Issue (Completed 2026-03-26)**:
- [x] **Root Cause Analysis**: Identified Facebook button display logic error, incomplete initialization state management, potential loading lock-up, and insufficient diagnostic logs.
- [x] **Fix Plan**: Repair display logic, enhance diagnostic logs, fix loading state management, and optimize timeouts.
- [x] **Diagnosis & Log Collection**: Added detailed debug logs to critical paths.
- [x] **Fixed Core Initialization**: Fixed Facebook button visibility logic to ensure buttons only show if App IDs are configured.
- [x] **Fixed Loading State Management**: Cleared pending waiters, enhanced error handling, and optimized timeouts.
- [x] **Validation**: Passed unit tests and code analysis.

**OAuth Button Fix Summary**:
✅ **Root Cause Identified**: Facebook button display logic error (`OauthSignInService.canShowFacebookButton || kIsWeb`).
✅ **Core Fixes Completed**:
- Fixed Facebook button logic by removing the `|| kIsWeb` condition.
- Enhanced diagnostic logs with `_logError()` and detailed initialization logs.
- Fixed loading state management by clearing pending waiters.
- Optimized timeout from 120s to 60s.
- Enhanced error handling with proper initialization failure flags.
  ✅ **Debugging Enhanced**: Added detailed logs to critical paths.
  ✅ **Compilation Verified**: Passed `flutter analyze` and unit tests.

**Fix Results**:
- Buttons display correctly: only shows if the corresponding App ID is configured.
- Clear initialization status: success/failure now explicitly logged.
- Loading states normalized: error states now correctly reset the loading status.
- Reasonable timeouts: 60s provides a better user experience.

**Detailed Documentation**: See `DEBUG_NOTES/google_facebook_buttons_loading_fix.md`.

**Next Steps**:
- Monitor real-world effects in production.
- Add OAuth configuration check at app startup.
- Provide more user-friendly prompts for missing configurations.
- Fix failed unit test cases.

**New Iteration — Coins Feature Development & Optimization (Completed 2026-03-26)**:
- [x] **Current State Analysis**: Me page display, payment deduction, calculation logic, and API support.
- [x] **Optimization Plan**: Details page development, payment parameter optimization, and acquisition path display.
- [x] **Developed TreasureCoinsPage**: Balance display, value conversion, acquisition paths, and transaction history.
- [x] **Routing Configuration**: Added `/me/wallet/coins` route to `app_router.dart`.
- [x] **Me Page Optimization**: Changed "Details" button from a toast to a navigation to `TreasureCoinsPage`.
- [x] **Verified Payment Parameters**: Confirmed `paymentMethod` (ID: 2 for coins) is passed correctly.
- [x] **Payment UX Optimization**: Added guidance prompts when coins balance is insufficient.
- [x] **Lucky Draw Integration**: Displayed coins acquisition records from lucky draws on `TreasureCoinsPage`.

**Coins Optimization Summary**:
✅ **Core Features Completed**: Full `TreasureCoinsPage` with balance, conversion, guides, and history.
✅ **Routing Integrated**: Added `/me/wallet/coins` and enabled navigation from Me page.
✅ **Payment Flow Optimized**: Verified correct `paymentMethod` parameter and added user guidance.
✅ **Data Integration Completed**: Integrated `walletProvider` for balance and `luckyDrawResultsProvider` for history.
✅ **UX Improved**: Replaced toasts with full pages and added usage/acquisition instructions.

**Optimization Expected Results**:
- Users can fully view and manage their coins balance.
- Clear instructions on coin acquisition (draws) and usage (payment).
- Increased perceived value and usage rate of coins.
- Higher motivation for users to participate in lucky draws.
- Promotion of coin usage during checkout.

**Next Steps**:
- Monitor coins usage rate trends.
- Optimize `TreasureCoinsPage` design based on user feedback.
- Consider adding more acquisition paths (e.g., check-ins, tasks).
- Add a dedicated full history page for coin transactions.

**New Iteration — Sharing Feature Configuration-Based Fix (Completed 2026-03-26)**:
- [x] **Analysis of hard-coded sharing bridge URLs**.

**New Iteration — OAuth Callback Loading UX Analysis (Completed 2026-03-29)**:
- [x] **Google OAuth callback loading delay analysis**: Identified delayed loading causes after callback redirect to `/login` (deferred recovery trigger, route-first handling, and loading hide timing).
- [x] **Solution comparison and difficulty grading**: Added Low/Medium/High方案分级（timing quick fix / dedicated processing page / full orchestration refactor）with risk and effort estimates.
- [x] **Third-party login documentation update**: Added `OAuth Callback Loading Optimization Summary` to `docs/Features & Integrations/login/THIRD_PARTY_LOGIN_TECHNICAL_GUIDE.md`.

**New Iteration — OAuth Callback Loading Quick Fix Implementation (Completed 2026-03-29)**:
- [x] **Login recovery trigger timing optimization**: Triggered recovery check directly in `LoginPage.initState` path (while keeping provider reset in microtask for Riverpod lifecycle safety).
- [x] **Reduced visual delay on login return**: Added token-existence gating and immediate local busy state to avoid late loading feedback and unnecessary flash when no recovery token exists.
- [x] **Global loading transition smoothing**: Delayed hiding global loading until shortly after route navigation to reduce pre-navigation flicker.
- [x] **Regression verification update**: Added/adjusted OAuth timing tests (`test/widgets/login_page_oauth_test.dart`) and completed targeted test run.

**New Iteration — OAuth Callback Dedicated Processing Page (Completed 2026-03-29)**:
- [x] **Dedicated callback processing route**: Added `/oauth/processing` route and redirect target for Firebase callback URLs.
- [x] **Immediate loading feedback page**: Implemented `OauthProcessingPage` with first-frame loading UI for callback recovery path.
- [x] **OAuth handler decoupling**: Refactored `GlobalOAuthHandler` to support recovery-only mode (no forced navigation/global loading).
- [x] **Auth navigation control**: Added optional `navigate` parameter to `AuthNotifier.login()` to prevent double-navigation during processing-page flow.
- [x] **Login page fallback de-duplication**: Updated login recovery behavior to avoid duplicate recovery when processing page is active.
- [x] **Regression tests updated**: Extended `test/widgets/login_page_oauth_test.dart` for updated recovery return behavior and processing-page loading rendering.

**New Iteration — App Startup Optimization Phase 1 (2026-04-02)**:
- [x] **Splash Timing Control**: Enabled `flutter_native_splash` `preserve()`/`remove()` in `main.dart`; added `flutter_native_splash:` config to `pubspec.yaml`; generated native Android/iOS/Web assets. Eliminates black/white screen gap between system Splash and Flutter first frame.
- [x] **Removed GoogleFonts.inter() redundancy**: Replaced `GoogleFonts.inter()` in `app.dart` builder with `const TextStyle(fontFamily: 'Inter')`. `ThemeData` already uses local Inter font; this eliminates unnecessary network font validation on first frame.
- [x] **initSystem Parallelization**: Refactored `AppBootstrap.initSystem()` to use `Future.wait` for Firebase/EasyLocalization/ApiCacheManager/Http/AssetManager in parallel. Estimated 100-300ms reduction in startup time.
- [x] **runApp 前移 + 预热后台化**: Removed data barrier `await` from `main.dart`; `appStartupProvider` now runs in background via `unawaited()`. Added `LocalDatabaseService.currentUserId` getter and DB-ready guard in `ChatEventProcessor` to prevent race-condition writes to guest.db. Chat pre-warming preserved; first-frame delay eliminated (300ms–1s gain).
- [x] **Fixed Firebase [core/no-app] crash**: Moved `_setupFirebase()` back into `Future.wait` (runs in parallel with other services, zero serial-time cost). Root cause: `unawaited()` background init created a race window where `fcmInitProvider` → `FcmService` → `FirebaseMessaging.instance` was called before Firebase was ready.

**New Iteration — Unified Error Handler Implementation (Completed 2026-03-29)**:
- [x] **Error pattern analysis**: Analyzed 228+ error handling patterns across codebase.
- [x] **Unified ErrorHandler class**: Created `lib/utils/error_handler.dart` with centralized error handling.
- [x] **User-friendly messages**: Implemented error message mapping for SocketException, TimeoutException, DioException, etc.
- [x] **Automatic retry mechanism**: Added `RetryHelper` class with configurable retry logic.
- [x] **Extension methods**: Provided `withErrorHandling()` and `withRetry()` extensions for easy usage.
- [x] **Documentation**: Created `docs/ERROR_HANDLER_USAGE.md` with usage guide and migration instructions.
- [x] **Compilation verified**: Passed `fvm flutter analyze` with no errors.

**Error Handler Features**:
- ✅ Unified error handling across the app
- ✅ User-friendly error messages (Chinese)
- ✅ Automatic retry with exponential backoff
- ✅ Dio error handling (timeout, connection, status codes)
- ✅ Extension methods for simplified usage
- ✅ Error logging and reporting integration ready

**Usage Example**:
```dart
// Automatic error handling with Toast
await apiCall().withErrorHandling(context: 'Loading data');

// Automatic retry with error handling
await apiCall().withRetry(maxRetries: 3, context: 'Upload file');
```

---

## 🎯 Current Task — Web Startup Phase 4 (2026-05-05)

**Phase**: Performance — Web First Load Optimization
**Last Stop**: Phase 1-4 已完成
**Accomplishments (Phase 1-4)**:
- [x] **Phase 1** — 移除 `runApp` 前数据屏障（`main.dart` 改为 `unawaited`）
- [x] **Phase 2** — 精简 `app_startup.dart` 职责（删除重复 DB 初始化和脆弱 JSON 解析）
- [x] **Phase 3** — Firebase Web 超时从 10s 降至 5s（`bootstrap.dart` 1行改动）
- [x] **Phase 4** — 重服务 Provider 从首帧剥离
  - 新建 `lib/app/widgets/auth_aware_service_manager.dart` — 条件性初始化 Socket/FCM/ChatEventProcessor
  - 重构 `lib/app/app.dart` — 删除 3 行无条件 `ref.watch()`，builder 内包裹 `AuthAwareServiceManager`
  - 未登录用户不再触发无用重服务初始化
  - 登录/登出自动跟随 auth 状态启停
  - 通过 `fvm flutter analyze` ✅
- [ ] **Phase 5** — Web 包体瘦身（独立专项，1-2周，待排期）
- [x] **CORS Preflight Redirect Fix**: Changed [`dev.json`](lib/core/config/env/dev.json:3) `API_BASE_URL` from `http://dev-api.joyminis.com` to `https://dev-api.joyminis.com`. Browser HSTS cache internally redirects HTTP→HTTPS with 307 before sending, causing CORS preflight (OPTIONS) failure. HTTPS avoids the redirect entirely.
- [x] **PWA "New Version" False Detection in Dev**: Added `kReleaseMode` check in [`PwaUpdateBanner.initState()`](lib/components/pwa_banners.dart:171) — banner only checks for updates in release mode. Also wrapped both SW registration scripts in [`index.html`](web/index.html:283) with localhost skip to prevent false "new version" detection on every hot-reload/rebuild. Removed invalid `--web-disable-service-worker` flag from [`Makefile`](Makefile:5) (doesn't exist in Flutter 3.41.6).
- [x] **Dark Theme Default**: Changed `initialThemeModeProvider` default from `ThemeMode.system` to `ThemeMode.dark`.
- [x] **Bootstrap Migration**: Added one-time migration in `loadInitialOverrides()` to clear old `'light'` saved preference, so existing users also see dark mode on first launch after update.
- [x] **Toggle Persistence**: User's future toggle choices (via settings page) are still saved and respected on subsequent restarts.

---

## 🎯 Current Task — Product Page Scroll Performance Optimization (2026-05-11)

**Phase**: Performance — Product Page Scrolling & Image Loading Optimization
**Last Stop**: Product page scrolling felt "difficult" (滑动困难) — stuttery/janky scroll experience
**Root Causes Identified**:
1. **FittedBox two-pass layout** in `ProductItem` — each card triggers two layout passes
2. **Per-item AnimationController** in `AnimatedListItem` — 20+ active controllers competing for vsync
3. **`addRepaintBoundaries: false`** on grid delegate — no repaint isolation between items
4. **No BlurHash overlay** — placeholder→image flash on every load
5. **No network-aware quality** — always loads high-quality images regardless of connection
6. **NestedScrollViewPlus physics conflict** — `platformScrollPhysics()` vs `ClampingScrollPhysics()`
7. **No device-size-aware quality** — phone loads same image dimensions as desktop
8. **Fixed card dimensions** — 166x365 regardless of viewport size

**Fixes Applied**:
- [x] **Fix 1 (FittedBox→LayoutBuilder)**: Replaced `FittedBox` with `LayoutBuilder` + `Transform.scale` in [`ProductItem`](lib/components/product_item.dart:77) — eliminates two-pass layout overhead
- [x] **Fix 2 (Fast-scroll animation skip)**: Added static `_isScrollingFast` flag + `updateScrollSpeed()` in [`AnimatedListItem`](lib/ui/animated_list_item.dart) — skips AnimationController during active scroll
- [x] **Fix 3 (addRepaintBoundaries)**: Changed `addRepaintBoundaries: false` → `true` in [`PageListViewPro` grid delegate](lib/components/list.dart:497) — enables repaint isolation
- [x] **Fix 4 (BlurHash overlay)**: Adopted front_blog BlurHash overlay pattern in [`OptimizedImage`](lib/ui/img/optimized_image.dart:331) — image at full opacity on bottom, BlurHash on top as overlay, 300ms fade-out on load
- [x] **Fix 5 (Network-aware quality)**: Added [`networkQualityProvider`](lib/core/providers/network_status_provider.dart:35) — defaults to quality=75, ready for Web Network Information API
- [x] **Fix 6 (Scroll physics)**: Changed `platformScrollPhysics()` to `const ClampingScrollPhysics()` in both [`NestedScrollViewPlus`](lib/app/page/product_page.dart:182) and [`CustomScrollView`](lib/app/page/product_page.dart:306)
- [x] **Fix 7 (Device-size-aware quality)**: Added [`deviceSizeProvider`](lib/core/providers/network_status_provider.dart:66) + device-aware width ladder in [`ResponsiveImageService._computeTargetWidth()`](lib/utils/image/responsive_image_service.dart:81) — phone/tablet/desktop width tiers
- [x] **Fix 8 (Viewport-aware card scaling)**: Added `DeviceCategory`-based `_baseWidth`/`_baseHeight` in [`ProductItem`](lib/components/product_item.dart:40) — phone=166x365, tablet=200x440, desktop=240x528; wired from `deviceSizeProvider` in [`product_page.dart`](lib/app/page/product_page.dart:298)
- [x] **Cleanup**: Removed duplicate `DeviceCategory` enum definitions from [`optimized_image.dart`](lib/ui/img/optimized_image.dart), [`responsive_image_service.dart`](lib/utils/image/responsive_image_service.dart), and [`product_item.dart`](lib/components/product_item.dart) — canonical source is [`network_status_provider.dart`](lib/core/providers/network_status_provider.dart:45)
- [x] **Fix 9 (Product detail image size)**: Fixed [`_computeTargetWidth()`](lib/utils/image/responsive_image_service.dart:81) — changed from returning inflated ladder values (480→1440px with 3x DPR) to capping `logicalWidth` at device-specific maximums (phone=480, tablet=720, desktop=1080). Changed [`OptimizedImageFactory.banner()`](lib/ui/img/optimized_image.dart) quality from `'high'` (90) to `'medium'` (80). Result: phone with 375 logical width now requests `width=1125, quality=80` instead of `width=1440, quality=90`.
- [x] **Fix 10 (RemoteUrlBuilder.imageCdn second path)**: Fixed [`RemoteUrlBuilder.imageCdn()`](lib/utils/media/remote_url_builder.dart:59) — replaced hardcoded binary 240/480 logic with device-aware capping (phone max 480, tablet 720, desktop 1080 logical pixels). This path is used by [`ProductItem`](lib/components/product_item.dart:113) via `UrlResolver.resolveImage()` and the preloader. Now `logicalWidth=166` on phone produces `width=498` instead of `width=720`.
- [x] **Fix 11 (Detail page blurhash)**: Added blurhash support to detail page banner chain — [`OptimizedImageFactory.banner()`](lib/ui/img/optimized_image.dart:412) now accepts `blurhash` parameter; passed through [`SwiperBanner`](lib/components/swiper_banner.dart:38) → [`ImageWidget`](lib/components/swiper_banner.dart:198) → [`BannerSection`](lib/app/page/product_detail/detail_sections.dart:37) → [`product_detail_page.dart`](lib/app/page/product_detail_page.dart:120) (from `detail.blurhash`)
- [x] **Fix 12 (home_featured image not covering card)**: Replaced [`AppCachedImage`](lib/ui/img/app_image.dart) with [`OptimizedImageFactory.product()`](lib/ui/img/optimized_image.dart:412) in [`home_featured.dart`](lib/app/page/home_components/home_featured.dart:103) — `AppCachedImage` uses `CachedNetworkImage` which may not consistently fill container, and image URL goes through `fitAbsoluteUrl()` (no width params) → `resolveImage()` (returns early due to existing CDN prefix), so images load at full resolution without proper CDN sizing. `OptimizedImageFactory.product()` uses custom `ImageCacheManager` + `Image.memory` with proper CDN sizing and blurhash overlay.
- [x] **Verification**: Passed `fvm flutter analyze` (0 errors) ✅ and `fvm flutter test` (75/75) ✅

---

## 🎯 Previous Task — API 503 Triple Fix (2026-05-05)

**Phase**: DevOps — Service Worker 503 (HSTS + COOP Headers)
**Last Stop**: API requests returning 503 from Service Worker, persistent even after nginx reload
**Root Cause (tiered)**:
1. **Tier 1 (COOP conflict)**: Backend NestJS sends `Cross-Origin-Opener-Policy: same-origin`, nginx adds `Cross-Origin-Opener-Policy: unsafe-none` → browser sees two conflicting values → SW fetch may fail.
2. **Tier 2 (HSTS hijack — THE REAL BLOCKER)**: Backend NestJS sends `Strict-Transport-Security: max-age=31536000; includeSubDomains`. Browser cached this HSTS entry, so even HTTP API requests to `dev-api.joyminis.com` get internally upgraded to HTTPS → no valid SSL cert → fetch fails → SW catch → 503. This is why incognito worked (no HSTS cache) but normal mode didn't.
3. **Tier 3 (Stale SW)**: Even after server fixes, old SW (v1) remained registered in browser until browser restart.

**Fixes Applied**:
- [x] **Fix A (COOP)**: Added `proxy_hide_header Cross-Origin-Opener-Policy;` to both `/api/` blocks in [`nginx.dev.conf`](../../Volumes/mySSD/work/JoyMini_Nest_Monorepo/nginx/nginx.dev.conf:140) — hides backend's conflicting `same-origin`.
- [x] **Fix B (HSTS)**: Added `proxy_hide_header Strict-Transport-Security;` to both `/api/` blocks in [`nginx.dev.conf`](../../Volumes/mySSD/work/JoyMini_Nest_Monorepo/nginx/nginx.dev.conf:141) — prevents future HSTS caching.
- [x] **Fix C (SW cache)**: Bumped `CACHE_NAME` from `joymini-shell-v1` to `joymini-shell-v2` in [`web/pwa_sw.js:7`](web/pwa_sw.js:7).
- [x] **All nginx fixes verified**: syntax ok, reloaded, curl shows clean headers ✅
- [x] **User confirmed**: Restart browser → API works, no more 503 ✅

## 🎯 Previous Task — API 503 & Dev Environment Fix (2026-05-04)

**Phase**: DevOps — Infrastructure Debugging & CORS Fix
**Last Stop**: All API requests returning 503 (Service Worker) / Network errors resolved
**Accomplishments**:
- [x] **Root Cause Analysis**: Production 503 = `Cross-Origin-Embedder-Policy: require-corp` in `web/_headers` blocking Service Worker cross-origin fetch. Dev 503 = nginx only listening on HTTPS with no valid SSL certs in `certs/`.
- [x] **Production Fix**: Changed [`web/_headers`](web/_headers:2) COEP from `require-corp` to `credentialless`.
- [x] **Dev Server Port**: Added `--web-port=4000` to [`Makefile`](Makefile:6) DEV variable.
- [x] **Dev HTTP API (Option B)**: Changed [`dev.json`](lib/core/config/env/dev.json:3) `API_BASE_URL` from `https://dev-api.joyminis.com` to `http://dev-api.joyminis.com`.
- [x] **Nginx HTTP Proxy**: Added `/api/`, `/auth/`, `/socket.io/` proxy config to HTTP server block in [`nginx.dev.conf`](../../Volumes/mySSD/work/JoyMini_Nest_Monorepo/nginx/nginx.dev.conf:223) with `resolver 127.0.0.11` for Docker DNS resolution.
- [x] **CORS Headers Fix**: Added Dio custom headers (`signature_nonce`, `currentTime`, `lang`, `x-device-id`, `x-device-model`, `x-platform`, `Cache-Control`) to `Access-Control-Allow-Headers` in both HTTP and HTTPS server blocks of [`nginx.dev.conf`](../../Volumes/mySSD/work/JoyMini_Nest_Monorepo/nginx/nginx.dev.conf:145). Root cause of "The connection errored: The XMLHttpRequest onError callback was called" — browser blocked the actual CORS request after OPTIONS preflight succeeded but `Allow-Headers` didn't match.
- [x] **Nginx Reloaded**: `docker exec lucky-nginx-dev nginx -s reload` to apply CORS config changes.
- [x] **End-to-End Verification**: User confirmed `http://localhost:4000` works after refresh — all API requests return HTTP 200.

