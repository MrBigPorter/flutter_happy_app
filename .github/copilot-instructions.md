# Lucky Flutter App — Copilot Working Instructions

> This document guides the AI (Cline/Roo) on development decisions, quality standards, and communication style.
> Last updated: 2026-05-22

# 1. 引导指令

- 每次对话开始，先读取 `.github/copilot-instructions.md` 和 `docs/AI_QUICK_START.md` 获取上下文。
- 任务完成时，必须主动更新 `.github/copilot-instructions.md` 中的 `[ ]` 状态。

# 2. 技术栈约束 (Phase F1)

- 状态管理：必须使用 Riverpod（使用 @riverpod 注解）。
- 路由系统：必须使用 GoRouter。
- 金融/支付安全：金额字段强制使用 `JsonNumConverter.toDouble`，严禁直接使用 double 计算。

# 3. 自动化任务

## 🚀 可自主执行的任务：

- 明确的 Bug 修复
- 文档/UI 调整
- 依赖更新
- 代码格式化

## ❓ 需要询问用户的任务：

- 架构变更
- 新功能
- 数据库变更
- 性能优化
- 涉及金融/支付的逻辑修改

## 📞 必须使用完整沟通协议的任务：

- [ ] 📞 Full Communication Protocol Required

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


## 🎯 Current Task

**Phase**: Phase 0 — SamaHub Backend Monorepo Initialization (P0.0 ✅)
**Last Stop**: SamaHub monorepo created — NestJS 11 + GraphQL + Socket.IO + Prisma + AI Service (2026-06-11)

### Recent Accomplishments

| Date | Task | Status |
|------|------|--------|
| 2026-06-11 | **SamaHub P0.0 — Monorepo Initialization** — Created `/Users/porter/Developer/SamaHub/` with npm workspaces: `apps/backend` (NestJS 11 + Apollo GraphQL + Socket.IO + Prisma 6.18 + JWT + ioredis + S3 + Zod, port 4000), `services/ai` (NestJS 11 + ioredis + openai SDK, port 5000), `packages/shared` (`@samahub/shared` with SocketEvents enum, 7 enums, DomainEvent interface). 23 files. `tsc --noEmit` passes with zero errors. See [`sama_phase0_implementation_plan.md`](../Sama/plans/sama_phase0_implementation_plan.md:91). | ✅ |
| 2026-05-22 | **Web Test Mode Login Flow** — `/?type=test` URL param detection via `TestModeService` (conditional import pattern). Auto-fills email `mrsuperportertest@gmail.com` + code `999999` on login page. Replaced toast popup with inline warning banner (amber theme tokens) — only visible in test mode. | ✅ |
| 2026-05-22 | **Fix Cloudflare Pages Deploy — Wrangler v2 → v3 Migration** — `cloudflare/pages-action@v1` (bundled Wrangler v2.21.3) deprecated by Cloudflare; API returned 500. Migrated to `cloudflare/wrangler-action@v3` in both `web_deploy.yml` and `full_deploy.yml`. Removed deprecated `directory`/`projectName`/`branch`/`gitHubToken` inputs; replaced with `command: pages deploy build/web --project-name=... --branch=...`. | ❌ |
| 2026-05-23 | **PROD Outage — Wrangler v3 + wasm deployment corrupted main.dart.js (HTTP 500, 0 bytes)** — The `cloudflare/wrangler-action@v3` with `pages deploy --branch=main --commit-dirty=true` created a corrupted production deployment: `main.dart.js` returned HTTP 500 with 0 bytes, `main.dart.wasm` was 28KB HTML error page. The CSP violation error was a red herring (Chrome extension failing on 500 error page). Fixed by triggering `web_deploy.yml` (H5 deploy without `--wasm`) which built a clean dart2js+canvaskit deployment. Root cause: Wrangler v3 `pages deploy` may not handle `--wasm` builds correctly or creates preview deployments instead of production updates. **Action**: Avoid `full_deploy.yml` (with `--wasm`) until Wrangler v3 + wasm compatibility is verified. | ✅ |
| 2026-05-13 | **H5 Build Size -42MB (70% reduction)** — Switched to HTML renderer in `web/index.html`, removed 31MB `canvaskit/` dead weight. Moved `widgetbook` (2.9MB leaked assets) + `flutter_native_splash` to `dev_dependencies`. Removed `font_awesome_flutter` (688K, 0 refs) and `app_tracking_transparency` (0 refs). Full dependency audit of 70+ packages verified. Build drops from ~60MB → ~18MB. | ✅ |
| 2026-05-13 | **Engineering Infrastructure — Widgetbook entry alias + deploy.sh + web_deploy.yml** — Created `lib/main_widgetbook.dart` standard entry point (`fvm flutter run --target lib/main_widgetbook.dart`). Created `deploy.sh` as 7-stage build pipeline (clean → build → rm NOTICES/widgetbook → inject part files → gzip → audit). Unified `web_deploy.yml` CI/CD: `--wasm` → standard build, added NOTICES/widgetbook cleanup + build size audit. | ✅ |
| 2026-05-13 | **Fix Flutter 3.22+ bootstrap loader crash** — `_flutter.loader.load()` new API requires `_flutter.buildConfig` set by build system. Fixed `web/index.html`: load `flutter_bootstrap.js` (not `flutter.js`) which includes auto-generated build config + auto `load()` call. Removed redundant manual `_flutter.loader.load()` that caused double-load error. Removed `canvaskit/` deletion from deploy.sh since current build uses CanvasKit renderer. | ✅ |
| 2026-05-14 | **Fix dual main.dart.js loading (preload + dynamic import conflict)** — `<link rel="preload" href="main.dart.js">` triggers a browser download but dynamic `_flutter.loader.load()` creates an independent fetch — preloads can only be consumed by direct `<script>` tags. Changed preload from `flutter.js` → `flutter_bootstrap.js`, removed `main.dart.js` preload entirely. Saves ~1.6MB transferred (3.3MB decompressed) in first page load. | ✅ |
| 2026-05-14 | **H5 Mobile Cache Fix — Stale flutter_bootstrap.js/main.dart.js served from 1-year immutable browser cache** — `web/_headers` had `*.js → max-age=31536000, immutable` which caught `flutter_bootstrap.js`, `flutter.js`, and `main.dart.js` — all fixed-filename files that change per build. After deployment, browsers served stale versions for 1 year, causing page load failures (old serviceWorkerVersion → 404, old main.dart.js → incompatible API). Fix: Added specific `no-cache, must-revalidate` overrides for `/flutter_bootstrap.js`, `/flutter.js`, `/main.dart.js`, `/offline.html`, `/manifest.json` BEFORE the `*.js` wildcard. Also added `SW_VERSION` injection to `deploy.sh` (timestamp-based) so local builds get unique cache names (CI already had this). | ✅ |
| 2026-05-14 | **OAuth Login Race Condition — Popup close detection vs StorageEvent race** — `Future.any([tokenFuture, popupClosedFuture])` picks the first completed future. When popup closes (auto-close after 1500ms in callback page), `_waitForPopupClose` wins the race by milliseconds, causing `DeepLinkOAuthException` even though token arrived via StorageEvent milliseconds later. Fix: Replaced `Future.any` with `Completer` + 500ms grace period after popup close — token arrivals within 500ms of popup close still succeed. Changed `_waitForPopupClose` to return `true` instead of throwing. | ✅ |
| 2026-05-14 | **Preload crossorigin mismatch fix** — `<link rel="preload" href="flutter_bootstrap.js" as="script" crossorigin>` had `crossorigin` attribute, but the actual `<script src="flutter_bootstrap.js" defer>` did not. This caused browser to discard the preload (credentials mode mismatch) and re-download `flutter_bootstrap.js`. Fix: Removed `crossorigin` from the `<link>` preload tag since `flutter_bootstrap.js` is same-origin — no CORS needed. | ✅ |
| 2026-05-14 | **OAuth Popup Close Detection — Fix loading state stuck on popup close** — When user closes OAuth popup (Google/Facebook), `listenForOAuthToken().first` never emits, leaving buttons stuck in spinner state for 5min until timeout. Fix: Capture `html.WindowBase?` popup reference from `openPopup()`, poll `popup.closed` every 500ms via new `_waitForPopupClose()` method, race token stream vs popup-closed stream with `Future.any()`. Three files modified: `deep_link_oauth_service_web.dart` (return popup ref), `deep_link_oauth_service.dart` (add `_waitForPopupClose` + `Future.any` race), `deep_link_oauth_service_web_stub.dart` (return `dynamic` to match). | ✅ |
| 2026-05-14 | **Dead Dependency Cleanup (15 packages removed)** — Comprehensive audit of 70+ pubspec.yaml deps identified 15 dead packages (0 imports in lib/). Removed: `provider`, `syncfusion_flutter_sliders/core` (32KB), `dartx`, `jiffy`, `infinite_scroll_pagination`, `pull_to_refresh_notification`, `pull_to_refresh`, `dismissible_page`, `google_mlkit_face_detection`, `firebase_performance`, `firebase_auth`, `flutter_facebook_auth`, `universal_html`, `idb_shim`. Cleaned up `firebase_service.dart` (removed unused `FirebaseAuth` import/getter). Also cleared dep tree of 25 transitive sub-deps (`firebase_auth_web`, `firebase_performance_web`, `flutter_facebook_auth_web`, etc.). | ✅ |
| 2026-05-14 | **HTML Renderer enforcement** — Added `window.flutterWebRenderer = "html"` to `web/index.html` before `flutter_bootstrap.js` load. Ensures HTML renderer (no CanvasKit WASM download) regardless of Flutter build defaults. | ✅ |
| 2026-05-13 | **Deferred Loading Optimization (HomePage + Chat + KYC)** — Undeferred critical-path pages that should not be `DeferredPage`-wrapped: HomePage, ConversationListPage (non-deferred direct render). Undeferred KYC pages (kyc_verify, kyc_status) to eliminate black screen while `.part.js` chunks load on H5 face recognition. Removed `deferred as` imports and preload blocks from `main.dart`. | ✅ |
| 2026-05-13 | **Fix Video Playback on Web** — Platform-conditional architecture: Web → thumbnail + full-screen only; Native → full inline playback (unchanged). Removed CSS `pointer-events:none` hack, deleted `video_element_web/stub` utility files. | ✅ |
| 2026-05-13 | **Recording Overlay Bottom Bar + Timer Freeze Fix** — Full-width bottom bar at `bottom:0`; replaced `Timer.periodic`→`Ticker` for drift-free timer on Web. | ✅ |
| 2026-05-13 | **Web OAuth Popup Login — Blank Popup + localStorage Fallback** — Fixed browser popup blocker rejection: open blank popup synchronously on user gesture, then navigate to OAuth URL. Added `localStorage.StorageEvent` fallback channel when `window.opener` is null due to Google's COOP headers. Created `web/oauth-popup-callback.html` static callback page with dual-channel communication (`postMessage` + `localStorage`). Graceful degradation to full-page redirect when popup is blocked. | ✅ |
| 2026-05-13 | **Web OAuth Popup — Fix new tab → popup window** — Added `width=600,height=700,scrollbars=yes` features parameter to `html.window.open()` third argument to force popup window instead of new tab. | ✅ |
| 2026-05-13 | **Web OAuth Popup — Fix login state not updating after popup close** — Changed URL param `redirect_uri` → `callback` to match backend API convention (`/auth/$provider/login` expects `callback`). | ✅ |
| 2026-05-13 | **Web OAuth Popup — Add debug logging** — Added `console.log('[OAuthPopupCallback] ...')` in callback HTML page, `debugPrint('[OAuthTokenListener] ...')` in popup listener, and `debugPrint('[DeepLinkOAuthService] ...')` in main service for full token delivery path tracing. | ✅ |
| 2026-05-12 | **Deferred .part.js Prefetch Optimization** — Moved deferred chunk caching out of SW install critical path → `requestIdleCallback` after Flutter ready. | ✅ |
| 2026-05-12 | **PWA Update Banner False Detection** — Deferred SW update check to 30s after page load; added 15s min visit duration. | ✅ |
| 2026-05-12 | **HomePage + Remaining Pages Deferred** — HomePage, Guide, 404, WinnerDetail all deferred to `.part.js` chunks. | ✅ |
| 2026-05-12 | **Market & Me Deferred with Skeleton** — ProductPage and MePage deferred with shimmer skeletons + fade-in transitions. | ✅ |
| 2026-05-12 | **PWA SW Pre-caching** — All deferred `.part.js` files pre-cached via build-time injection script. | ✅ |
| 2026-05-12 | **H5 Independent Deploy Workflow** — Created `web_deploy.yml` for ~5-8 min H5-only CI/CD. | ✅ |
| 2026-05-12 | **KYC Status Sync Before Checkout** — Cache-first-then-API-refresh to prevent infinite verify-prompt loop. | ✅ |
| 2026-05-12 | **Customer Service Chat Auto-Load Fix** — DB init in ChatViewModel + retry mechanism for direct chat entry. | ✅ |
| 2026-05-11 | **Product Page Scroll Performance** — 12 fixes: `FittedBox`→`LayoutBuilder`, fast-scroll animation skip, BlurHash, network-aware quality, device-aware sizing, scroll physics fix. | ✅ |
| 2026-05-11 | **Home Page Flash Fix** — `forceRefresh()` SWR cache recovery; Chat UX Phase A+B (emoji picker, search, swipe actions, scroll-to-bottom FAB). | ✅ |
| 2026-05-11 | **Web Startup App Shell** — Flutter-controlled App Shell removal via Dart JS interop; deferred Firebase init (~165ms saving). | ✅ |
| 2026-05-05 | **Web Startup Phase 4** — Auth-aware service manager, HTML renderer, Cache-Control headers, Brotli/Gzip, PWA false detection fix. | ✅ |
| 2026-05-05 | **API 503 Triple Fix** — COOP/HSTS nginx header fixes, SW cache bump. | ✅ |

| | 2026-05-14 | **PWA Mobile Update — Reduce SW update check from 30s → 2s** — The 30-second delay in `reg.update()` caused a timing mismatch with `PwaUpdateBanner`'s 15-second minimum visit check. On mobile, where there's no 'Update on reload' DevTools option, users had to clear site data to get the new deployment. Now the update check runs at 2s, giving the banner enough time to detect the new SW version and show the 'Reload' button. The 15-second minimum visit guard in `PwaUpdateBanner` (Dart-side) already prevents false 'new version' banners on payment gateway returns, so the 30s JS delay was redundant. Committed as `f6d266b`. | ✅ |
| | 2026-05-14 | **True Root Cause: Chrome StorageEvent Throttling on Background Tabs** — Discovered why the initial OAuth fix (sync StreamController + 1000ms) worked on localhost but failed in production: Chrome delays/delivers StorageEvent when the main tab is in the background during OAuth popup flow. Fixed with 3-part redundancy: (1) postMessage (fastest, when `window.opener` exists), (2) StorageEvent (when COOP headers nullify opener), (3) localStorage polling every 200ms (bypasses ALL browser event system delays). Replaced `Stream.first` with explicit `StreamSubscription` + `finally` cleanup. Extended grace period to 5000ms. Committed as `72a2ac9`. | ✅ |
| | 2026-05-14 | **Update DEEP_LINK_OAUTH_IMPLEMENTATION_GUIDE.md to v3.0** — Updated main OAuth technical guide with Web popup login flow, 3-channel token redundancy (postMessage + StorageEvent + localStoragePoll), Completer race condition fix, popup close detection with 5000ms grace period, and Chrome background tab throttling workaround. Also updated `plans/web_oauth_popup_flow.md` and `plans/web_oauth_flow_explained.md` with the same fixes. | ✅ |
| | 2026-05-22 | **Widgetbook dependency warnings fixed** — Excluded `lib/widgetbook/**` from flutter analyze via `analysis_options.yaml`. The 3 `depend_on_referenced_packages` info warnings about widgetbook (in dev_dependencies) are now suppressed. `widgetbook` stays in `dev_dependencies` to avoid 2.9MB production build bloat. | ✅ |

### Key Technical Decisions
- **Video Playback (Web)**: No inline `VideoPlayer` — always use full-screen `VideoPlayerPage`. Native keeps full inline playback with LRU pool + pre-warming.
- **Recording Timer**: Use `Ticker` (Flutter render pipeline) instead of `Timer.periodic` (browser `setInterval`) for drift-free Web behavior.
- **Deferred Loading**: Critical-path pages (HomePage, LoginPage, ConversationListPage) are non-deferred in main bundle. Tab bar pages (ProductPage, MePage) remain deferred with shimmer skeletons. All secondary pages remain deferred.
- **PWA**: No inline SW version check on fresh page load; deferred 2s + 15s min visit duration guard (reduced from 30s to fix mobile cache issue).
- **App Shell**: Removed via Dart JS interop (`PwaHelper.removeAppShell()`) on Flutter's first frame — no JS timer can match paint cycle timing.
