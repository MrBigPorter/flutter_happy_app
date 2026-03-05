

###  第一部分：三大平台打包差异深度分析

| 维度 | **Web (网页端)** | **Android (安卓端)** | **iOS (苹果端)** |
| --- | --- | --- | --- |
| **产物形态** | 文件夹（包含 JS、HTML、CanvasKit） | 文件（`.apk` 或 `.aab`） | 文件（`.ipa`） |
| **核心编译工具** | Flutter Web Compiler | Gradle + Android SDK 

| Xcode + Apple SDK |
| **签名/证书** | **不需要** | **需要** (`.jks` 签名文件) | **极严** (开发者证书 + 配置文件) |
| **环境注入** | 编译时注入 JS 常量 | 编译时注入 Java/Kotlin 代码 | 编译时注入 Objective-C/Swift 代码 |
| **发布方式** | 传到 Nginx/CDN 服务器即可 | 传到商店或直接发给用户 APK | 必须通过 App Store 或 TestFlight |
| **运行机制** | 在浏览器沙盒里跑 | 在安卓虚拟机或真机上跑 | 在苹果封闭系统内跑 |

---

###  第二部分：JoyMini 全平台打包“大包教程”

在开始之前，确保你的 `pubspec.yaml` 里的版本号（如 `version: 1.0.0+1`）已经更新，并且 `assets` 里的图标已经生成。

#### 1. Web 端：最简单的“一键发布”

Web 打包不需要签名，只要确保 API 地址正确。

* **打包命令**：
```bash
flutter build web --release --wasm --dart-define-from-file=lib/core/config/env/prod.json
```


* **后续操作**：
* 打包产物在 `build/web/` 文件夹。
* 直接把这个文件夹里的所有东西，通过 FTP 或 SSH 传到你的 Nginx 服务器对应目录下即可。



#### 2. Android 端：自由的“盖章出库”

你需要用到我们之前配置的 `key.properties` 和 `upload-keystore.jks`。

* **第一步：本地测试包 (APK)**
```bash
flutter build apk --release --dart-define-from-file=lib/core/config/env/prod.json

```


* **产物**：`build/app/outputs/flutter-apk/app-release.apk`。
* **用途**：直接发给哥们儿安装，或者放在官网给用户下载。


* **第二步：上架专用包 (AAB)**
```bash
flutter build appbundle --release --dart-define-from-file=lib/core/config/env/prod.json

```


* **产物**：`build/app/outputs/bundle/release/app-release.aab`。
* **用途**：传给 Google Play 控制台。



#### 3. iOS 端：严格的“苹果审核”

必须在 Mac 上操作，且 Xcode 里的 `Info.plist` 已经按照我们刚才说的修好了。

* **第一步：生成归档 (Archive)**
```bash
flutter build ipa --release --dart-define-from-file=lib/core/config/env/prod.json

```


* **第二步：Xcode 发布**
* 命令跑完后，会生成一个 `Runner.xcarchive`。
* 打开 Xcode 的 **Organizer** (Window -> Organizer)。
* 选择你的 **JoyMini** 归档，点 **Distribute App**。
* 如果你是上架，选 `App Store Connect`；如果你是给内部人测，选 `Ad Hoc`。



---

###  教程核心总结：你只需要记住这三行

为了方便你复制，我把生产环境的最常用命令整在一起了：

```bash
# Web 发布
flutter build web --release --dart-define-from-file=lib/core/config/env/prod.json

# Android 发给用户
flutter build apk --release --dart-define-from-file=lib/core/config/env/prod.json

# iOS 准备上传商店
flutter build ipa --release --dart-define-from-file=lib/core/config/env/prod.json

```

