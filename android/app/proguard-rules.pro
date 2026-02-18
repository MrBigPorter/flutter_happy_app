# AWS Amplify 混淆规则
-keep class com.amplifyframework.** { *; }
-keep class com.amazonaws.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# 如果使用了 Gson (Amplify 内部可能依赖)
-keep class com.google.gson.** { *; }

# 保持 Kotlin 元数据
-keep class kotlin.Metadata { *; }

#  新增：CallKit 混淆规则
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
-keep interface com.hiennv.flutter_callkit_incoming.** { *; }