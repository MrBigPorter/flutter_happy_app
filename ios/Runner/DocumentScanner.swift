import UIKit        // 引入“装修工具包”（处理界面）
import VisionKit    // 引入“扫描仪工具包”（苹果自带的相机）
import Flutter      // 引入“传话工具包”（为了能回复 Flutter）

// 定义一个类，名字叫 DocumentScannerHandler
// NSObject: 它是 iOS 对象的老祖宗（必须继承）。
// VNDocumentCameraViewControllerDelegate: 这是一张“资格证”。
// 意思是：我考过了扫描仪操作证，我会处理“扫描成功”、“扫描失败”和“取消”这三件事。
class DocumentScannerHandler: NSObject, VNDocumentCameraViewControllerDelegate {

    // 📞 这是一个“对讲机”。
    // 一会儿经理会把这个对讲机塞给我。
    // 我只要对着它说话，Flutter 就能听到。
    var flutterResult: FlutterResult?

    // ✅ 情况一：扫描成功
    // 当用户点击“保存”时，系统会自动调用这个方法
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {

        // 检查：如果一张纸都没扫到（pageCount < 1），那就当没发生。
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true) // 关掉相机
            flutterResult?(nil)                // 告诉 Flutter: 啥也没有
            return
        }

        // 1. 拿到第 0 页（第一张）的图片
        let image = scan.imageOfPage(at: 0)

        // 2. 把图片转换成 .jpg 数据（类似把肉做成红烧肉）
        if let data = image.jpegData(compressionQuality: 0.8) {

            // 3. 找一个临时存放的地方（盘子）
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = UUID().uuidString + ".jpg" // 随机起个名字，防重复
            let fileURL = tempDir.appendingPathComponent(fileName) // 拼成完整路径

            // 4. 把数据写入文件（把菜装盘）
            try? data.write(to: fileURL)

            // 📢 5. 【关键】对着对讲机喊话！
            // 把“文件路径”传回给 Flutter
            flutterResult?(fileURL.path)
        } else {
            // 如果转换失败
            flutterResult?(nil)
        }

        // 最后，关掉相机界面
        controller.dismiss(animated: true)
    }

    // ❌ 情况二：用户点“取消”
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        flutterResult?(nil) // 告诉 Flutter: 用户取消了 (null)
        controller.dismiss(animated: true) // 关掉相机
    }

    // ⚠️ 情况三：出错（比如相机坏了）
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print("报错了: \(error)")
        flutterResult?(nil) // 告诉 Flutter: 失败了 (null)
        controller.dismiss(animated: true) // 关掉相机
    }
}