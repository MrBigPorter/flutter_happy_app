package com.porter.joyminis

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import androidx.activity.compose.setContent
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.amplifyframework.ui.liveness.ui.FaceLivenessDetector
import com.amplifyframework.core.Amplify
import com.amplifyframework.auth.cognito.AWSCognitoAuthPlugin
import androidx.core.view.WindowCompat

class LivenessActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 作用：告诉系统“我的背景是亮的，请把状态栏图标（时间/电量）改成黑色的”
        WindowCompat.getInsetsController(window, window.decorView).isAppearanceLightStatusBars = true


        // ---------------------------------------------------------
        // 原生层初始化 Amplify
        // ---------------------------------------------------------
        try {
            if (Amplify.Auth.plugins.isEmpty()) {
                Log.d("Liveness_Init", "正在原生层初始化 Amplify...")
                Amplify.addPlugin(AWSCognitoAuthPlugin())
                Amplify.configure(applicationContext)
                Log.d("Liveness_Init", "Amplify 原生初始化成功")
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

            // ⚫️⚪️ 2. 定义【黑白极简】配色方案
            val blackAndWhiteTheme = lightColorScheme(
                primary = Color.Black,
                onPrimary = Color.White,

                background = Color.White,
                onBackground = Color.Black,

                surface = Color.White,
                onSurface = Color.Black,

                errorContainer = Color(0xFFF2F2F2),
                onErrorContainer = Color.Black,
                error = Color.Red,
                onError = Color.White
            )

            // 3. 应用主题
            MaterialTheme (colorScheme = blackAndWhiteTheme) {
                // 4. 使用 Box 布局叠加自定义标题
                Box(
                    modifier = Modifier.fillMaxSize().background(Color.White)  // 确保底色是白的
                ) {
                    // --- 底层：AWS 摄像头组件 ---
                    FaceLivenessDetector(
                        sessionId = sessionId,
                        region = region,
                        onComplete = {
                            val data = Intent()
                            data.putExtra("status", "success")
                            data.putExtra("sessionId", sessionId)
                            Log.d("Liveness_Debug", "检测成功")
                            setResult(Activity.RESULT_OK, data)
                            finish()
                        },
                        onError = { error ->

                            //  修改后: error.message 才是真正的人话！
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
}