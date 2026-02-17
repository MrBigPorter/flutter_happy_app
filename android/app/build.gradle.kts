plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("org.jetbrains.kotlin.plugin.compose")
    // 【新增】直接加在这里，不需要版本号（因为根目录已经定义了）
    id("com.google.gms.google-services")
    id("com.google.firebase.firebase-perf")
}

android {
    namespace = "com.porter.joyminis"
    compileSdk = 36  //  满足 webview 等插件的要求
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.porter.joyminis"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildFeatures {
        compose = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

//  这是一个自动脚本
// 它的作用：遍历所有依赖，只要看到有人敢要 1.9.0 或 1.17.0，
// 直接强行替换成 1.8.0 和 1.13.1。
// 这就是你要的“一次性识别并搞定”。
configurations.all {
    resolutionStrategy {
        force("androidx.browser:browser:1.8.0")
        force("androidx.core:core-ktx:1.13.1")
        force("androidx.core:core:1.13.1")
        force("androidx.activity:activity:1.8.2")
        force("androidx.activity:activity-ktx:1.8.2")
        force("androidx.activity:activity-compose:1.8.2")
    }
}

dependencies {
    // (Amplify 部分)
    // 使用 BOM 锁定核心版本为 2.19.1 (配合 Liveness 1.3.0 )
    implementation(platform("com.amplifyframework:core:2.19.1"))
    implementation(platform("com.amplifyframework:aws-auth-cognito:2.19.1"))

    // 实际引入库 (不需要写版本号了，BOM 会自动管)
    implementation("com.amplifyframework:aws-auth-cognito")
    implementation("com.amplifyframework:core") // 显式加上 core 比较保险

    // Liveness 独立引入
    implementation("com.amplifyframework.ui:liveness:1.3.0")

    implementation(platform("androidx.compose:compose-bom:2024.02.00"))
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation("androidx.appcompat:appcompat:1.6.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("com.google.android.gms:play-services-mlkit-document-scanner:16.0.0")
    implementation("com.google.android.gms:play-services-mlkit-text-recognition:19.0.0")
    implementation("com.google.mlkit:text-recognition-chinese:16.0.0")
    implementation("com.google.android.gms:play-services-mlkit-face-detection:17.1.0")

    //  【精华】引入 Firebase BOM (Bill of Materials)
    // 它的好处是：以后添加具体的 Firebase 库（如 Analytics, Messaging）不需要写版本号了！
    implementation(platform("com.google.firebase:firebase-bom:33.7.0")) // 版本号可以用最新的

    //  添加具体功能，不用写版本号，BOM 会自动配对
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging") // 如果你要做推送，就把这个加上

}