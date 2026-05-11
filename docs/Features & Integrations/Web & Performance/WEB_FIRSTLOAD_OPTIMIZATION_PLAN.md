# Web 首次加载优化改造规划

> **文档版本**: v1.2
> **创建日期**: 2026-05-05
> **状态**: Phase 1-4 已实施 ✅ | Phase 5 待排期
> **优先级**: P0（直接影响用户留存）  
> **关联分析文档**: `app start analy.md`

---

## 一、问题定性

当前 JoyMini Web 端首次加载慢的**根本原因不是某一行代码**，而是**启动链路的职责边界错误**：

> **把"基础设施初始化"、"领域数据预热"、"首帧渲染"三件完全不同生命周期的事情串在同一条阻塞链上。**

用户在浏览器打开页面后，经历完整的串行等待链，然后才能看到第一帧 UI：

```
下载 Flutter WASM
  → Firebase init（最多等 10 秒）
  → SharedPreferences × 2 次读
  → Sembast/IndexedDB 开盘
  → 联系人列表 API（网络请求 #1）
  → 会话列表 API（网络请求 #2）
  → 联系人实体 API（网络请求 #3）
  → ← 全部完成才 runApp()，用户才看到第一帧
```

Web 环境下（网络延迟 + IndexedDB），这条链耗时 **500ms–3000ms**，全部落在白屏窗口内。

---

## 二、瓶颈清单

### 🔴 P0 — 直接阻塞首帧（每次冷启动必然触发）

#### 问题 1：`runApp` 前的数据屏障

| 属性 | 值 |
|------|---|
| **位置** | `lib/main.dart:54` |
| **代码** | `await container.read(appStartupProvider.future)` |
| **白屏耗时** | 认证用户 **500ms–2000ms**（依网络/设备IO） |

`appStartupProvider` 内部依次：
- 第2次 `SharedPreferences.getInstance()`（已有一次在 `loadInitialOverrides()`）
- `LocalDatabaseService.init(userId)`（Web 端 = IndexedDB 开盘）
- `ref.read(contactListProvider)` — 网络请求 #1
- `ref.read(conversationListProvider)` — 网络请求 #2
- `ref.read(contactEntitiesProvider)` — 网络请求 #3

所有这些 IO 必须完成，`runApp()` 才会被调用。

#### 问题 2：Firebase Web 超时上限 10 秒

| 属性 | 值 |
|------|---|
| **位置** | `lib/app/bootstrap.dart:123` |
| **代码** | `.timeout(const Duration(seconds: 10))` |
| **风险场景** | 弱网 / VPN / 离线时 Firebase JS SDK 挂起，整个 `initSystem()` 卡满 10 秒 |

---

### 🟡 P1 — 首帧渲染时多余工作

#### 问题 3：首帧 `build()` 同时启动三个重服务

| 属性 | 值 |
|------|---|
| **位置** | `lib/app/app.dart:47–55` |

```dart
ref.watch(socketServiceProvider);      // Socket.io 握手
ref.watch(chatEventProcessorProvider); // 监听 Socket 流
ref.watch(fcmInitProvider);            // FCM 权限弹窗 + getToken()
```

**影响**：
- **未登录用户**：首帧触发三次无用初始化
- **登录用户**：首帧三个重 Provider 并发构建，容易引发 Jank
- `fcmInitProvider` 会触发浏览器权限弹窗，与页面渲染竞争

#### 问题 4：`app_startup.dart` 重复初始化 DB

| 路径 | 说明 |
|------|------|
| `lib/app/app_startup.dart:76` | 从 `lucky_state` JSON 手动解析 userId 后调用 `LocalDatabaseService.init()` |
| `lib/core/store/user_store.dart:36` | `fetchProfile()` 登录后也调用 `LocalDatabaseService.init(user.id)` |

两处均调用 DB 初始化，且 `app_startup.dart` 的路径依赖一个脆弱的手动 JSON 解析（`lucky_state` key 一旦变更就静默失效）。

---

### 🟢 P2 — Web 包体积（中长期）

#### 问题 5：Native 重包污染 WASM 快照

涉及包：`ffmpeg_kit_flutter_new`、`flutter_webrtc`、`google_mlkit_text_recognition`、`google_mlkit_face_detection`、`camera`

这些包的 Dart 代码在 Web 构建时仍被编译进 `.wasm` 快照（即使运行时走 stub），增加下载和解析时间，**预计影响 WASM 体积 20–40%**。

#### 问题 6：`app_router.dart` 63 行全量 eager import

路由初始化时 Dart VM 解析所有页面类（KYC、Liveness、WebRTC 视频通话等），即使用户从不访问这些路由，AOT 快照体积也会偏大。

---

## 三、改造规划

### Phase 1 — 移除 `runApp` 前的数据屏障

**改动范围**: `lib/main.dart`，2 行改动  
**预计耗时**: 30 分钟  
**风险等级**: 🟢 极低  
**预期收益**: Web 首屏减少 **500ms–2000ms**

**改前**：
```dart
// main.dart:51–58
try {
  await container.read(appStartupProvider.future);
  debugPrint(' [架构日志] 所有底层数据预热完毕，准备渲染 UI！');
} catch (e, stackTrace) {
  debugPrint(' [架构日志] AppStartup 初始化出现异常: $e');
}
```

**改后**：
```dart
// 数据预热改为后台运行，不阻塞 runApp
// 鉴权守卫由 GoRouter redirect（已有 isAuthenticated 检查）负责
unawaited(
  container.read(appStartupProvider.future).catchError((e) {
    debugPrint(' [架构日志] AppStartup 后台初始化异常: $e');
  }),
);
```

**安全性说明**：

`authProvider` 在 `ProviderContainer(overrides: overrides)` 创建时已**同步**从 `initialTokensProvider` 读取 token（无网络 IO），`isAuthenticated` 在第一帧就是正确值。`GoRouter redirect`（`app_router.dart:579–630`）完全能兜底路由鉴权跳转，不依赖 `appStartupProvider` 完成。

数据预热（联系人、会话）延后只影响聊天模块**首次进入**时的加载 Loading，不影响首页、商品、订单等主流程。

---

### Phase 2 — 精简 `app_startup.dart` 职责

**改动范围**: `lib/app/app_startup.dart`，删除约 40 行  
**预计耗时**: 30 分钟  
**风险等级**: 🟢 低  
**预期收益**: 消除脆弱解析路径；DB 初始化有唯一正确入口

**删除以下内容**：

```dart
// ❌ 删除：手动从 lucky_state 解析 userId（脆弱，key 变更后静默失效）
final prefs = await SharedPreferences.getInstance();
final String? jsonStr = prefs.getString('lucky_state');
...
userId = data['userInfo']['id'];

// ❌ 删除：DB 初始化（唯一正确入口是 user_store.fetchProfile()，在登录时调用）
await LocalDatabaseService.init(userId);

// ✅ 保留但改为 fire-and-forget（不 await，不阻塞 appStartupProvider 完成）
Future.microtask(() {
  ref.read(contactListProvider);
  ref.read(conversationListProvider);
  ref.read(contactEntitiesProvider);
});
```

**改后 `appStartup` 职责精简为 3 件事**：
1. `ref.watch(authProvider)` — 确保认证状态 Provider 保活
2. `Future.microtask()` 后台拉取远程系统配置（已有）
3. 认证用户：`Future.microtask()` fire-and-forget 触发聊天数据预热

---

### Phase 3 — Firebase Web 超时优化

**改动范围**: `lib/app/bootstrap.dart`，1 行改动  
**预计耗时**: 10 分钟  
**风险等级**: 🟢 极低  
**预期收益**: 弱网场景节省最多 5 秒等待

**改前**：
```dart
await FirebaseService.initialize()
    .timeout(const Duration(seconds: 10));
```

**改后**：
```dart
await FirebaseService.initialize()
    .timeout(kIsWeb ? const Duration(seconds: 5) : const Duration(seconds: 10));
```

Web 端超时缩短至 5 秒。超时后 Firebase 初始化失败（已有 catch 兜底，App 继续运行），FCM 功能降级，但不影响业务主流程。

---

### Phase 4 — 重服务 Provider 从首帧剥离（下一轮）

**改动范围**: `lib/app/app.dart` + 新建 `lib/app/widgets/auth_aware_service_manager.dart`  
**预计耗时**: 半天  
**风险等级**: 🟡 中（涉及 Socket 生命周期，需验证登录→使用聊天→登出→重登录流程）

**目标架构**：

```
MyApp.build()
  └─ MaterialApp.router
       └─ builder:
            └─ BotToastInit
                 └─ Column
                      ├─ PwaUpdateBanner
                      └─ AuthAwareServiceManager（新增）
                           ├─ isAuthenticated == true
                           │    → ref.watch(socketServiceProvider)
                           │    → ref.watch(chatEventProcessorProvider)
                           │    → ref.watch(fcmInitProvider)
                           └─ isAuthenticated == false
                                → 什么都不做（SizedBox.shrink）
```

**核心新增文件** `auth_aware_service_manager.dart`：
```dart
class AuthAwareServiceManager extends ConsumerWidget {
  const AuthAwareServiceManager({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuth = ref.watch(authProvider.select((s) => s.isAuthenticated));
    if (isAuth) {
      ref.watch(socketServiceProvider);
      ref.watch(chatEventProcessorProvider);
      ref.watch(fcmInitProvider);
    }
    return child;
  }
}
```

**测试场景（必须验证）**：
- [ ] 未登录用户打开首页 → 无 Socket/FCM 初始化
- [ ] 登录 → Socket 自动连接、FCM Token 正常上传
- [ ] 使用聊天功能、接收消息正常
- [ ] 登出 → Socket 断连
- [ ] 重新登录 → Socket 重连，聊天功能正常

---

### Phase 5 — Web 包体瘦身（独立专项）

**改动范围**: `pubspec.yaml` + 20+ 处 conditional import  
**预计耗时**: 1–2 周  
**风险等级**: 🔴 高（涉及文件多，需逐包验证）

**策略**：
1. 为 `ffmpeg_kit_flutter_new`、`flutter_webrtc`、`camera`、`google_mlkit_*` 建立 Web stub 层
2. 通过 `dart.library.io` conditional import 在 Web 编译时排除 Native-only 代码
3. 目标：Web WASM 快照体积减少 20–40%，对应 TTFB→FCP 可缩短 300–800ms

**此阶段独立排期，不与 Phase 1–4 混做，避免改动量叠加增加回归成本。**

---

## 四、实施顺序与时间线

```
Day 1（今天可做）
├─ Phase 1  移除数据屏障         1h
├─ Phase 2  精简 app_startup     30min
├─ Phase 3  Firebase 超时优化    10min
└─ 验证     Chrome DevTools 冷启动 FCP 对比截图

Day 3–5
├─ Phase 4  重服务 Provider 剥离
└─ 测试     登录全流程回归（以上 5 个场景）

独立专项（按人力排期）
└─ Phase 5  包体瘦身
```

---

## 五、验收标准

| 指标 | 优化前（估算） | Phase 1-3 目标 | Phase 4 目标 | 测量方法 |
|------|--------------|---------------|-------------|---------|
| Web 冷启动白屏时间 | 500–2000ms | **< 200ms** | < 200ms | Chrome DevTools Performance |
| Web FCP（首次内容绘制） | 1500–3000ms | **< 800ms** | < 600ms | Lighthouse |
| Web TTI（可交互时间） | 3000–5000ms | < 2500ms | **< 2000ms** | Lighthouse |
| 弱网（Fast 3G）白屏 | 3000–8000ms | **< 1500ms** | < 1500ms | DevTools Network Throttling |
| 未登录首帧 Socket 初始化 | 有 | 有 | **无** | DevTools Network |

---

## 六、回退策略

每个 Phase 均为独立 commit，可单独 `git revert`。

| Phase | 回退操作 | 副作用 |
|-------|---------|--------|
| Phase 1 | `git revert <commit>` | 无，恢复数据屏障 |
| Phase 2 | 恢复 `app_startup.dart` 原始内容 | DB 初始化由 `user_store.fetchProfile()` 保底，不中断 |
| Phase 3 | 改回 `Duration(seconds: 10)` | 无 |
| Phase 4 | 删除 `AuthAwareServiceManager`，恢复 `app.dart` 三行 `ref.watch` | 无 |

---

## 七、相关文件索引

| 文件 | 角色 | 对应 Phase |
|------|------|-----------|
| `lib/main.dart` | 启动入口，含数据屏障 | Phase 1 |
| `lib/app/app_startup.dart` | 领域数据预热 Provider | Phase 2 |
| `lib/app/bootstrap.dart` | 基础设施初始化 | Phase 3 |
| `lib/app/app.dart` | App 根 Widget，含重服务 watch | Phase 4 |
| `lib/app/widgets/auth_aware_service_manager.dart` | Phase 4 新建 | Phase 4 |
| `lib/app/routes/app_router.dart:579–630` | GoRouter 鉴权守卫（Phase 1 安全保障） | 参考 |
| `lib/core/store/user_store.dart:32–40` | DB 初始化正确时机（Phase 2 理论依据） | 参考 |
| `pubspec.yaml` | 包体积问题源头 | Phase 5 |

---

## 八、参考文档

- `docs/Features & Integrations/Web & Performance/app start analy.md` — 原始瓶颈分析报告
- `docs/Features & Integrations/Web & Performance/OPTIMIZATION_STATUS_REPORT.md` — 历史优化状态
- `docs/Architecture & Design/ARCHITECTURE_MASTER.md` — 架构分层规范

