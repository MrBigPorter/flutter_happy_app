
# ⚔️ Lucky IM 核心架构剩余战术板 (The Final Frontier)

> **🎯 当前阶段**: **v5.4.0 (Performance & Smoothness)**
> **🔥 核心目标**: 解决 **“极致丝滑”** 的最后一公里。
> **🧹 状态**: P0 (自愈) ✅, P2 (流式) ✅。**当前仅剩一项攻坚任务。**

## 🗺️ 剩余作战地图

### 🟡 P1: 资源预热调度器 (Resource Scheduler)

*解决“快速滑动列表时的白屏/图片加载滞后”*

1. **背景 (Context)**
* **现状**: `ConversationListPage` 和 `ChatPage` 目前是 **“懒加载” (Lazy Load)** 模式。只有当图片组件进入屏幕可视区域 (`Viewport`) 时，才开始发起网络请求或磁盘读取。
* **痛点**: 当用户快速甩动列表时，滚动速度超过了图片解码/IO速度，导致用户先看到“白块”或占位图，几百毫秒后图片才闪现，体验不够“跟手”。


2. **战术动作 (Action Item)**
* **封装 `ScrollAwarePreloader` 组件**:
* 在列表外层包裹 `NotificationListener<ScrollNotification>`。


* **速度感知算法**:
* 监听 `metrics.pixels` 和 `velocity`。
* **策略 A (静止预热)**: 当滚动停止 (`Idle`) 时，自动计算并预加载屏幕下方 **2000px** 范围内的图片资源。
* **策略 B (高速保护)**: 当滚动速度极快 (如 `velocity > 2000`) 时，暂停加载重资源（如视频缩略图），优先保证 FPS，等速度降下来再恢复加载。


* **API 调用**:
* 使用 Flutter 原生 `precacheImage(provider, context)` 将图片提前塞入内存缓存 (`ImageCache`)。





