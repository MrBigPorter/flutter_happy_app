import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';

class UploadProgressDialog extends StatefulWidget {
  final ValueNotifier<String> messageNotifier;
  final Future<dynamic> Function(Function(double) onProgress) uploadTask;

  const UploadProgressDialog({
    super.key,
    required this.messageNotifier,
    required this.uploadTask,
  });

  static Future<T?> show<T>(
      BuildContext context, {
        required ValueNotifier<String> messageNotifier,
        required Future<dynamic> Function(Function(double) onProgress) uploadTask,
      }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UploadProgressDialog(
        messageNotifier: messageNotifier,
        uploadTask: uploadTask,
      ),
    );
  }

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  Timer? _fakeTimer;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _startFakeProgress();
    _startTask();
  }

  void _startFakeProgress() {
    _fakeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      if (_progressNotifier.value < 0.20) {
        _progressNotifier.value += 0.005;
      } else {
        _fakeTimer?.cancel();
      }
    });
  }

  void _startTask() async {
    try {
      final result = await widget.uploadTask((realProgress) {
        // ✅ 修复 1: 确保组件还在才更新 UI
        if (mounted) {
          if (realProgress > _progressNotifier.value) {
            _progressNotifier.value = realProgress;
          }
        }
      });

      _fakeTimer?.cancel();

      // ✅ 修复 2: 确保组件还在才 pop
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      _fakeTimer?.cancel();

      // ✅ 修复 3: 安全的错误处理
      if (mounted) {
        // 如果弹窗还在，关闭它
        Navigator.of(context).pop();

        // 注意：在 async void 方法中 throw 会导致 App 崩溃
        // 所以这里我们只打印日志，错误传递依靠 _scanAndUploadID 内部的 errorReason 捕获
        debugPrint("ProgressDialog task error: $e");
      } else {
        debugPrint("ProgressDialog task failed but widget was already disposed: $e");
      }
    }
  }

  @override
  void dispose() {
    _fakeTimer?.cancel();
    _progressNotifier.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<String>(
                valueListenable: widget.messageNotifier,
                builder: (context, msg, _) {
                  return Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  );
                },
              ),
              const SizedBox(height: 32),

              RotationTransition(
                turns: _spinController,
                child: Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 48,
                  color: context.bgBrandSolid,
                ),
              ),

              const SizedBox(height: 16),

              ValueListenableBuilder<double>(
                valueListenable: _progressNotifier,
                builder: (context, progress, child) {
                  return Text(
                    "${(progress * 100).toInt()}%",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: context.bgBrandSolid,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}