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

    // 期雇佣一位厨师 (实例化 Handler)
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
        // 拿到当前的 Flutter 界面控制器 (为了能在它上面弹窗)
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        // ☎️ 安装电话机，贴上号码 CHANNEL
        let livenessChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: controller.binaryMessenger)

        // 👂 开始守着电话 (监听回调)
        livenessChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            // 为了安全，确认一下自己还在不在 (防止内存泄露)
            guard let self = self else { return }

            // 👉 顾客说：我要做活体检测 (AWS)
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
                
            }
            // 👉 顾客说：我要扫描证件 (Scan)
            else if(call.method == "scanDocument") {
                if VNDocumentCameraViewController.isSupported {
                    // 2. 把“扫描仪”这个大家伙搬出来
                    let scannerVc = VNDocumentCameraViewController()
                    // 🤝 【交接棒动作 1】
                    // 经理把手里的“听筒 (result)”递给厨师
                    // 这样厨师做完菜，就能直接告诉顾客，不用经过经理
                    self.scannerHandler.flutterResult = result
                    // 👮 【交接棒动作 2】
                    // 经理告诉扫描仪：
                    // "你拍好的照片，不要给我，直接交给那位厨师 (scannerHandler) 处理！"
                    scannerVc.delegate = self.scannerHandler
                    // 3. 把扫描仪界面弹出来显示在屏幕上
                    controller.present(scannerVc, animated: true)
                }else{
                    result(FlutterError(code: "UNSUPPORTED", message: "Document scanning is not supported on this device", details: nil))
                }
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
