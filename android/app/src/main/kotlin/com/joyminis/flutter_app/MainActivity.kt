package com.joyminis.flutter_app

import android.app.Activity
import android.content.Intent
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity  // 👈 修改1：换成这个引用
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// 👇 修改2：这里改成继承 FlutterFragmentActivity
class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.joyminis.flutter_app/liveness"

    private var pendingResult: MethodChannel.Result? = null

    // 现在这里绝对不会报错了，因为 FlutterFragmentActivity 支持它！
    private val livenessLauncher = registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        if (result.resultCode == Activity.RESULT_OK) {
            pendingResult?.success(true)
        } else {
            pendingResult?.success(false)
        }
        pendingResult = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "start") {
                val sessionId = call.argument<String>("sessionId")
                val region = call.argument<String>("region")

                if (sessionId != null) {
                    pendingResult = result

                    val intent = Intent(this, LivenessActivity::class.java)
                    intent.putExtra("sessionId", sessionId)
                    intent.putExtra("region", region)
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