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