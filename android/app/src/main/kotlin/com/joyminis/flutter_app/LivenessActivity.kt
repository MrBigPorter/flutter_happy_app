package com.joyminis.flutter_app
import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.material3.MaterialTheme
import com.amplifyframework.ui.liveness.ui.FaceLivenessDetector

class LivenessActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 1. 接收 Flutter 传过来的 SessionId
        val sessionId = intent.getStringExtra("sessionId")
        val region = intent.getStringExtra("region") ?: "us-east-1"

        if (sessionId == null) {
            finish()
            return
        }

        // 2. 加载 AWS 的 Compose UI
        setContent {
            MaterialTheme {
                FaceLivenessDetector(
                    sessionId = sessionId,
                    region = region,
                    onComplete = {
                        // ✅ 检测成功
                        setResult(RESULT_OK)
                        finish()
                    },
                    onError = { error ->
                        // ❌ 检测失败
                        // 可以在这里打个日志 Log.e("Liveness", error.message)
                        setResult(RESULT_CANCELED)
                        finish()
                    }
                )
            }
        }
    }
}