import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/page/image_preview_page.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IDScanPage extends StatefulWidget {
  final CameraDescription? cameraDescription;

  const IDScanPage({super.key, this.cameraDescription});

  @override
  State<IDScanPage> createState() => _IDScanPageState();
}

class _IDScanPageState extends State<IDScanPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();

    // 注册生命周期监听,以便在应用切换前后台时处理相机资源
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    // 注销生命周期监听
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('AppLifecycleState changed to $state');
    if (!_isCameraInitialized || _cameraController == null) {
      return;
    }
    // 应用切换到后台，释放相机资源
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // 应用切换到前台，重新初始化相机
      _initCamera();
    }
  }

  // 初始化相机
  Future<void> _initCamera() async {
    // 初始化相机控制器,假设已经有权限并且 cameraDescription 不为 null
    _cameraController = CameraController(
      widget.cameraDescription!,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );


    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (_) {}
  }

  // 拍照方法
  void _takePhoto() async {
    if (!_isCameraInitialized || _cameraController == null) {
      return;
    }

    try {
      // 拍照
      final XFile image = await _cameraController!.takePicture();

      await _cameraController!.pausePreview();
      // 3. 跳转去预览页 (等待用户决定)
      if (mounted) {
       final bool? isConfirmed = await Navigator.push(context, MaterialPageRoute(
           builder:(context)=> ImagePreviewPage(imagePath: image.path)
       ));
       
       print('User confirmed: $isConfirmed');

       if(isConfirmed == true) {
         if(mounted) {
           Navigator.pop(context, image.path);
         }
       } else {
         await _cameraController!.resumePreview();
       }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if(!_isCameraInitialized || _cameraController == null) {
      return const Scaffold(
       // backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview would go here
          CameraPreview(_cameraController!),
          //overlay UI elements would go here
          CustomPaint(painter: IDCardOverlayPainter()),

          // Add other UI elements like instructions, buttons, etc.
          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 30.w,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                Spacer(),
                // Instruction text
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 70.w),
                  child: Text(
                    'Please align your ID card within the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
                Padding(
                  padding: EdgeInsets.only(bottom: 40.h),
                  child: Center(
                    child: InkWell(
                      onTap: _takePhoto,
                      child: Container(
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE55865),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4.r),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 36.w,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 自定义绘制身份证扫描覆盖层
class IDCardOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 开一个可合成的图层
    canvas.saveLayer(Offset.zero & size, Paint());

    // 1. 全屏半透明黑底
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. 中间挖空矩形区域(身份证比例约 1.58:1)
    final cardWidth = size.width * 0.9;
    final cardHeight = cardWidth / 1.58;

    final left = (size.width - cardWidth) / 2;
    final top = (size.height - cardHeight) / 2 - 50.h; // 上移50像素

    final cutOutRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, cardWidth, cardHeight),
      Radius.circular(16.r),
    );

    // 3. 混合模式：Clear (把这块区域的黑色擦掉，露出底下的相机)
    final cutOutPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRRect(cutOutRect, cutOutPaint);

    // 4. 白色边框
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.w;
    canvas.drawRRect(cutOutRect, borderPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
