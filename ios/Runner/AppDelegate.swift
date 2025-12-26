import UIKit
import Flutter
import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import VisionKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    // 📞 酒店的总机号码（必须和 Flutter 一模一样）
    private let CHANNEL = "com.joyminis.flutter_app/liveness"

    // 👨‍🍳 长期雇佣一位厨师 (实例化 Handler)
    // 这一行代码让他一直待命，不会干完一次活就消失。
    private let scannerHandler = DocumentScannerHandler()

    override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // ------------------------------------------------
        // 1. 初始化 AWS Amplify (必须步骤)
        // ------------------------------------------------
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            print("✅ AWS Amplify 初始化成功")
        } catch {
            print("❌ AWS Amplify 初始化失败: \(error)")
        }

        // ------------------------------------------------
        // 2. 设置 Flutter 通信管道
        // ------------------------------------------------

        // ⚠️ 优化 1：使用 guard let 安全解包，防止 window 为空导致闪退
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return super.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        // ☎️ 安装电话机，贴上号码 CHANNEL
        let livenessChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)

        // 👂 开始守着电话 (监听回调)
        livenessChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in

            // 为了安全，确认一下自己还在不在 (防止内存泄露)
            guard let self = self else { return }

            // ⚠️ 优化 2：使用 switch 语句，逻辑更清晰，以后加功能更容易
            switch call.method {

            // 👉 情况 A: 顾客要做活体检测 (AWS)
            case "start":
                guard let args = call.arguments as? [String: Any],
                let sessionId = args["sessionId"] as? String else {
                    result(FlutterError(code: "ARGS_ERROR", message: "SessionId is required", details: nil))
                    return
                }

                let region = args["region"] as? String ?? "us-east-1"

                // 创建并弹出 SwiftUI 界面
                let livenessView = LivenessView(
                    sessionId: sessionId,
                    region: region,
                    onComplete: {
                        result(["success": true, "sessionId": sessionId])
                        self.dismissLivenessScreen(controller)
                    },
                    onError: { errorMsg in
                        result(["success": false, "error": errorMsg])
                        self.dismissLivenessScreen(controller)
                    }
                )

                let hostingController = UIHostingController(rootView: livenessView)
                hostingController.modalPresentationStyle = .fullScreen
                controller.present(hostingController, animated: true)

            // 👉 情况 B: 顾客要扫描证件 (VisionKit)
            case "scanDocument":
                if VNDocumentCameraViewController.isSupported {
                    // 1. 搬出扫描仪
                    let scannerVC = VNDocumentCameraViewController()

                    // 2. 【交接】把对讲机交给厨师
                    self.scannerHandler.flutterResult = result

                    // 3. 【指派】告诉扫描仪结果汇报给厨师
                    scannerVC.delegate = self.scannerHandler

                    // 4. 弹出界面
                    controller.present(scannerVC, animated: true)
                } else {
                    result(FlutterError(code: "UNSUPPORTED", message: "iOS 13+ required", details: nil))
                }

            // ❓ 其他情况: 听不懂的指令
            default:
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