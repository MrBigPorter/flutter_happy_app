package com.example.flutter_app // 保持你原有的包名

// 📦 必须导入这几个包 (IDE 通常会提示自动导入，如果没有就手动加)
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.widget.Toast // 为了测试弹个窗

class MainActivity: FlutterActivity() {
    // 🔑 语法点 1：跟 Flutter 端一模一样的"电话号码"
    private val CHANNEL = "com.lucky.kyc/liveness"

    // 这是 Flutter 引擎启动时会自动调用的方法
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 🔑 语法点 2：建立监听 (setMethodCallHandler)
        // binaryMessenger 是底层的通信员，不用管，传进去就行
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->

            // call: 包含了 Flutter 传过来的 method (暗号) 和 arguments (数据)
            // result: 用来给 Flutter 回话 (success/error)

            // 🔑 语法点 3：判断暗号
            if (call.method == "start") {

                // 🔑 语法点 4：获取参数 (类型安全获取)
                val sessionId = call.argument<String>("sessionId")
                val region = call.argument<String>("region")

                println("Android: 收到 Flutter 指令! Session: $sessionId")

                // --- 🧪 测试阶段：先弹个窗证明通了 ---
                Toast.makeText(this, "Android 收到: $sessionId", Toast.LENGTH_SHORT).show()

                // --- 模拟业务完成 ---
                // 告诉 Flutter: 任务搞定 (对应 Flutter 的 await 返回值)
                result.success(true)

            } else {
                // 如果暗号不对，告诉 Flutter 没这个方法
                result.notImplemented()
            }
        }
    }
}