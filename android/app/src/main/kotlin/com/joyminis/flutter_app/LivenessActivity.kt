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
                        // 🔥 修复点：直接打印 error.toString()，避开类型检查问题
                        Log.e("Liveness_Debug", "检测失败: ${error.toString()}")

                        val errorData = Intent()
                        errorData.putExtra("error_msg", error.toString())
                        setResult(Activity.RESULT_CANCELED, errorData)
                        finish()
                    }
                )
            }
        }
    }
}