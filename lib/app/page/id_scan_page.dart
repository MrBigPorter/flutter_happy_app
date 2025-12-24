import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class IDScanPage extends StatefulWidget {
  final CameraDescription camera;
  const IDScanPage({super.key, required this.camera});

  @override
  State<IDScanPage> createState() => _IDScanPageState();
}

class _IDScanPageState extends State<IDScanPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // 使用高分辨率，保证OCR和人脸清晰
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // 1. 相机预览层
                Positioned.fill(child: CameraPreview(_controller)),

                // 2. 黑色半透明遮罩层 (画个透明洞)
                CustomPaint(
                  painter: OverlayPainter(),
                  child: Container(),
                ),

                // 3. 拍照按钮
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      backgroundColor: Colors.white,
                      onPressed: () async {
                        try {
                          await _initializeControllerFuture;
                          final image = await _controller.takePicture();
                          // 👉 拿到图片路径 image.path
                          // TODO: 1. 展示预览给用户确认
                          // TODO: 2. 上传 image.path 到你的后端
                          print("拍摄成功: ${image.path}");
                          Navigator.pop(context, image.path);
                        } catch (e) {
                          print(e);
                        }
                      },
                      child: const Icon(Icons.camera_alt, color: Colors.black),
                    ),
                  ),
                ),

                // 4. 提示文字
                const Positioned(
                  top: 150,
                  left: 0,
                  right: 0,
                  child: Text(
                    "请将身份证正面置于框内",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

// 🎨 画遮罩的画笔
class OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);

    // 整个屏幕都是黑的
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // 中间“抠”掉一个身份证比例的矩形 (清除混合模式)
    final clearPaint = Paint()..blendMode = BlendMode.clear;

    // 身份证宽高比一般是 8.56 : 5.4，大概 1.58 : 1
    final cardWidth = size.width * 0.9;
    final cardHeight = cardWidth / 1.58;
    final left = (size.width - cardWidth) / 2;
    final top = (size.height - cardHeight) / 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, cardWidth, cardHeight),
      const Radius.circular(10),
    );

    canvas.drawRRect(rect, clearPaint);

    // 可以再画个边框
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}