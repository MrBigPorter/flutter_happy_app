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


## 🎯 Current Task

**Phase**: Phase F1 — Flutter Commercial Loop Closure
**Last Stop**: Fix Video Playback on Web (2026-05-13)

### Recent Accomplishments

| Date | Task | Status |
|------|------|--------|
| 2026-05-13 | **Deferred Loading Optimization (HomePage + Chat + KYC)** — Undeferred critical-path pages that should not be `DeferredPage`-wrapped: HomePage, ConversationListPage (non-deferred direct render). Undeferred KYC pages (kyc_verify, kyc_status) to eliminate black screen while `.part.js` chunks load on H5 face recognition. Removed `deferred as` imports and preload blocks from `main.dart`. | ✅ |
| 2026-05-13 | **Fix Video Playback on Web** — Platform-conditional architecture: Web → thumbnail + full-screen only; Native → full inline playback (unchanged). Removed CSS `pointer-events:none` hack, deleted `video_element_web/stub` utility files. | ✅ |
| 2026-05-13 | **Recording Overlay Bottom Bar + Timer Freeze Fix** — Full-width bottom bar at `bottom:0`; replaced `Timer.periodic`→`Ticker` for drift-free timer on Web. | ✅ |
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

### Key Technical Decisions
- **Video Playback (Web)**: No inline `VideoPlayer` — always use full-screen `VideoPlayerPage`. Native keeps full inline playback with LRU pool + pre-warming.
- **Recording Timer**: Use `Ticker` (Flutter render pipeline) instead of `Timer.periodic` (browser `setInterval`) for drift-free Web behavior.
- **Deferred Loading**: Critical-path pages (HomePage, LoginPage, ConversationListPage) are non-deferred in main bundle. Tab bar pages (ProductPage, MePage) remain deferred with shimmer skeletons. All secondary pages remain deferred.
- **PWA**: No inline SW version check on fresh page load; deferred 30s + 15s min visit duration guard.
- **App Shell**: Removed via Dart JS interop (`PwaHelper.removeAppShell()`) on Flutter's first frame — no JS timer can match paint cycle timing.
