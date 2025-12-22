package com.joyminis.flutter_app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.activity.compose.setContent
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.material3.MaterialTheme
import com.amplifyframework.ui.liveness.ui.FaceLivenessDetector
import com.amplifyframework.core.Amplify
import com.amplifyframework.auth.cognito.AWSCognitoAuthPlugin

class LivenessActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // ---------------------------------------------------------
        // 原生层初始化 Amplify
        // ---------------------------------------------------------
        try {
            if (Amplify.Auth.plugins.isEmpty()) {
                Log.d("Liveness_Init", "正在原生层初始化 Amplify...")
                Amplify.addPlugin(AWSCognitoAuthPlugin())
                Amplify.configure(applicationContext)
                Log.d("Liveness_Init", "Amplify 原生初始化成功！✅")
            }
        } catch (e: Exception) {
            Log.e("Liveness_Init", "Amplify 初始化异常: ${e.message}")
        }
        // ---------------------------------------------------------

        val sessionId = intent.getStringExtra("sessionId")
        val region = intent.getStringExtra("region") ?: "us-east-1"

        if (sessionId == null) {
            finish()
            return
        }

        setContent {
            MaterialTheme {
                FaceLivenessDetector(
                    sessionId = sessionId,
                    region = region,
                    onComplete = {
                        val data = Intent()
                        data.putExtra("status", "success")
                        setResult(Activity.RESULT_OK, data)
                        finish()
                    },
                    onError = { error ->
                        // ❌ 修改前: error.toString() 只打印了个代号
                        // Log.e("Liveness_Debug", "检测失败: ${error.toString()}")

                        // ✅ 修改后: error.message 才是真正的人话！
                        Log.e("Liveness_Debug", "检测失败原因: ${error.message}")

                        // 如果 message 是空的，我们再试一下 access message
                        if (error.message == null) {
                             Log.e("Liveness_Debug", "检测失败(无message), 原始异常: $error")
                        }

                        val errorData = Intent()
                        errorData.putExtra("error_msg", error.message ?: "未知错误")
                        setResult(Activity.RESULT_CANCELED, errorData)
                        finish()
                    }
                )
            }
        }
    }
}