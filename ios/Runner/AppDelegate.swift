import UIKit
import Flutter
import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import VisionKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    private let CHANNEL = "com.porter.joyminis/liveness"
    private let scannerHandler = DocumentScannerHandler()

    override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // 1. 初始化 AWS Amplify
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
        } catch {
            print("❌ AWS Amplify 初始化失败: \(error)")
        }

        // ------------------------------------------------
        // ✅ 优化点：注册插件
        // ------------------------------------------------
        GeneratedPluginRegistrant.register(with: self)

        // ------------------------------------------------
        // ✅ 关键修复：消除警告的通信管道设置
        // ------------------------------------------------

        // 这种写法通过 self 直接访问，更加符合 Flutter 引擎的生命周期管理
        if let controller = self.window?.rootViewController as? FlutterViewController {
            let livenessChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)

            livenessChannel.setMethodCallHandler({ [weak self, weak controller] (call: FlutterMethodCall, result: @escaping FlutterResult) in
                guard let self = self, let controller = controller else { return }

                switch call.method {
                case "start":
                    self.handleLiveness(call: call, result: result, controller: controller)
                case "scanDocument":
                    self.handleScan(result: result, controller: controller)
                default:
                    result(FlutterMethodNotImplemented)
                }
            })
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // --- 逻辑抽离，让 AppDelegate 更整洁 ---

    private func handleLiveness(call: FlutterMethodCall, result: @escaping FlutterResult, controller: FlutterViewController) {
        guard let args = call.arguments as? [String: Any],
        let sessionId = args["sessionId"] as? String else {
            result(FlutterError(code: "ARGS_ERROR", message: "SessionId is required", details: nil))
            return
        }
        let region = args["region"] as? String ?? "us-east-1"

        let livenessView = LivenessView(
            sessionId: sessionId,
            region: region,
            onComplete: {
                result(["success": true, "sessionId": sessionId])
                controller.dismiss(animated: true)
            },
            onError: { errorMsg in
                result(["success": false, "error": errorMsg])
                controller.dismiss(animated: true)
            }
        )
        let hostingController = UIHostingController(rootView: livenessView)
        hostingController.modalPresentationStyle = .fullScreen
        controller.present(hostingController, animated: true)
    }

    private func handleScan(result: @escaping FlutterResult, controller: FlutterViewController) {
        if VNDocumentCameraViewController.isSupported {
            let scannerVC = VNDocumentCameraViewController()
            self.scannerHandler.flutterResult = result
            scannerVC.delegate = self.scannerHandler
            controller.present(scannerVC, animated: true)
        } else {
            result(FlutterError(code: "UNSUPPORTED", message: "iOS 13+ required", details: nil))
        }
    }
}