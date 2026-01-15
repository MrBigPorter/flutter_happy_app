package com.porter.joyminis

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.activity.result.contract.ActivityResultContracts

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.porter.joyminis/liveness"
    private var pendingResult: MethodChannel.Result? = null

    // 1️⃣ 声明你的扫描 Handler
    private lateinit var scannerHandler: DocumentScannerHandler

    // 🔒 活体检测回调
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
        pendingResult = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 2️⃣ 初始化扫描 Handler
        scannerHandler = DocumentScannerHandler(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // 🔒 活体启动逻辑
                "start" -> {
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
                }

                // 3️⃣ 扫描指令
                "scanDocument" -> {
                    scannerHandler.startScan(result)
                }

                else -> result.notImplemented()
            }
        }
    }

    // 4️⃣ 统一回调接入口
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        // 如果是扫描请求码（1001），交给 Handler 处理
        // 如果不是，它会自动跳过，不会干扰到 livenessLauncher 的回调
        scannerHandler.handleActivityResult(requestCode, resultCode, data)
    }
}