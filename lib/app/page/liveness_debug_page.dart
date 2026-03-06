import 'package:flutter/material.dart';
import 'package:flutter_app/ui/button/button.dart';
import '../../utils/camera/services/liveness_service.dart';

class LivenessDebugPage extends StatefulWidget {
  const LivenessDebugPage({super.key});

  @override
  State<LivenessDebugPage> createState() => _LivenessDebugPageState();
}

class _LivenessDebugPageState extends State<LivenessDebugPage> {
  //  用来获取输入框里的 ID
  final TextEditingController _idController = TextEditingController();

  void _startTest() async {
    final inputId = _idController.text.trim();
    if (inputId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("大哥，先贴个 Session ID 进来啊！")),
      );
      return;
    }

    debugPrint(" 正在使用手动 ID 测试: $inputId");

    // 调用你之前写的服务逻辑
    final result = await LivenessService.start(context, inputId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result == true ? "🎉 验证成功！" : "❌ 验证失败或已关闭")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("活体检测手动测试")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("1. 先去 AWS 或后端拿一个全新的 Session ID", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "在此粘贴 sessionId (例如: b100b68b...)",
                labelText: "Session ID",
              ),
            ),
            const SizedBox(height: 20),
            Button(
              onPressed: _startTest,
              child: const Text(" 启动 Iframe 验证"),
            ),
            const SizedBox(height: 40),
            const Card(
              color: Colors.amberAccent,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(" 注意：AWS Session ID 是【一次性】的！如果你在浏览器独立页面跑过一次，这个 ID 就废了，必须拿个新的点这里。"),
              ),
            )
          ],
        ),
      ),
    );
  }
}