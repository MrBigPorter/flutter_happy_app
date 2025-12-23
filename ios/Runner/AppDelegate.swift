import UIKit
import Flutter
import SwiftUI
import Amplify
import AWSCognitoAuthPlugin

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    // 必须和 Flutter 端的 MethodChannel 名字完全一致
    private let CHANNEL = "com.joyminis.flutter_app/liveness"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // ------------------------------------------------
        // 1. 初始化 AWS Amplify (必须步骤)
        // ------------------------------------------------
        do {
            // 添加 Auth 插件（Liveness 必须依赖 Auth）
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            // 读取 amplifyconfiguration.json 配置文件
            try Amplify.configure()
            print("✅ AWS Amplify 初始化成功")
        } catch {
            print("❌ AWS Amplify 初始化失败: \(error)")
            // 注意：如果没有 amplifyconfiguration.json 文件，这里会报错，App 可能会闪退或功能不可用
        }

        // ------------------------------------------------
        // 2. 设置 Flutter 通信管道
        // ------------------------------------------------
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let livenessChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)

        livenessChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }

            if call.method == "start" {
                // 解析参数
                guard let args = call.arguments as? [String: Any],
                      let sessionId = args["sessionId"] as? String else {
                    result(FlutterError(code: "ARGS_ERROR", message: "SessionId is required", details: nil))
                    return
                }
                
                let region = args["region"] as? String ?? "us-east-1"
                
                // ------------------------------------------------
                // 3. 创建并弹出 SwiftUI 界面
                // ------------------------------------------------
                let livenessView = LivenessView(
                    sessionId: sessionId,
                    region: region,
                    onComplete: {
                        // 成功回调
                        result(["success": true, "sessionId": sessionId])
                        self.dismissLivenessScreen(controller)
                    },
                    onError: { errorMsg in
                        // 失败回调
                        result(["success": false, "error": errorMsg])
                        self.dismissLivenessScreen(controller)
                    }
                )

                // 使用 UIHostingController 将 SwiftUI 嵌入 UIKit
                let hostingController = UIHostingController(rootView: livenessView)
                hostingController.modalPresentationStyle = .fullScreen
                controller.present(hostingController, animated: true)
                
            } else {
                result(FlutterMethodNotImplemented)
            }
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // 辅助方法：关闭当前页面
    private func dismissLivenessScreen(_ controller: FlutterViewController) {
        DispatchQueue.main.async {
            controller.dismiss(animated: true, completion: nil)
        }
    }
}
