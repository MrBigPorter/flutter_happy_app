import SwiftUI
import FaceLiveness

struct LivenessView: View {
    // 这里是我们自己定义的变量，保持小写没问题
    let sessionId: String
    let region: String

    let onComplete: () -> Void
    let onError: (String) -> Void

    @State private var isPresented = true

    var body: some View {
        FaceLivenessDetectorView(
        // 👇 修改点：这里必须是 sessionID (大写 ID)，不能是 sessionId
            sessionID: sessionId,
            region: region,
            isPresented: $isPresented,
            onCompletion: { result in // 👇 确保这里是 onCompletion
                switch result {
                case .success:
                    onComplete()
                case .failure(let error):
                    onError(error.localizedDescription)
                @unknown default:
                    onError("未知错误")
                }
            }
        )
        .edgesIgnoringSafeArea(.all)
    }
}