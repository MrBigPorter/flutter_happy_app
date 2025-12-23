package com.joyminis.flutter_app

import android.app.Activity
import android.content.Intent
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity  // 👈 修改1：换成这个引用
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// 这里改成继承 FlutterFragmentActivity
class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.joyminis.flutter_app/liveness"

    // 用来暂存 Flutter 的回调结果，等 Activity 结束时用
    private var pendingResult: MethodChannel.Result? = null

    private val livenessLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            val returnedSessionId = result?.data?.getStringExtra("sessionId")

            val resultMap = mapOf(
                "sessionId" to returnedSessionId,
                "success" to true
            )
            pendingResult?.success(resultMap)
        } else {
            val errorMsg = result?.data?.getStringExtra("error_msg")
            pendingResult?.success(mapOf(
                "success" to false,
                "error" to errorMsg
            ))
        }
        // 清空，防止内存泄漏
        pendingResult = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            // 对应 Flutter 端的 invokeMethod('start')
            if (call.method == "start") {
                val sessionId = call.argument<String>("sessionId")
                val region = call.argument<String>("region")

                if (sessionId != null) {
                    // 1. 先把 result 存起来
                    pendingResult = result

                    val intent = Intent(this, LivenessActivity::class.java)
                    intent.putExtra("sessionId", sessionId)
                    intent.putExtra("region", region)

                    // 2. 启动原生页面
                    livenessLauncher.launch(intent)
                } else {
                    result.error("ARGS_ERROR", "SessionId is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}