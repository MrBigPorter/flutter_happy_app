# Android 模拟器（访问宿主机用 10.0.2.2）
flutter run -d android \
--dart-define=FLAVOR=dev \
--dart-define=API_BASE=http://10.0.2.2:3000 \
--dart-define=LOG_HTTP=true

# iOS 模拟器（可直接 localhost/127.0.0.1）
flutter run -d ios \
--dart-define=FLAVOR=dev \
--dart-define=API_BASE=http://127.0.0.1:3000 \
--dart-define=LOG_HTTP=true

# 真机（用你电脑的局域网 IP）
flutter run \
--dart-define=FLAVOR=dev \
--dart-define=API_BASE=http://192.168.x.x:3000 \
--dart-define=LOG_HTTP=true


#  记住口诀口诀（敲重点）
内存调高不卡顿；
AndroidX加Jetifier，
老库新库全兼容。

# 实战触发记忆
当 Flutter 构建慢、Gradle 报错、老库不兼容 时，
马上会想到：

“是不是我没开 daemon 或没开 Jetifier？”


# Gradle 构建优化笔记
- org.gradle.daemon=true → 常驻进程
- org.gradle.parallel=true → 多核编译
- org.gradle.configureondemand=true → 按需加载
- org.gradle.jvmargs → JVM 内存
- android.useAndroidX=true → 新架构
- android.enableJetifier=true → 老库兼容

# “三开关 + 一内存 + 两兼容”
开关：daemon, parallel, configureondemand
内存：jvmargs
兼容：useAndroidX, enableJetifier