import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart'; // 包含 context.bgBrandSolid 的定义

class UploadProgressDialog extends StatefulWidget {
  final String title;
  // 这里的 uploadTask 是一个高阶函数，把 onProgress 回调传出去
  final Future<dynamic> Function(Function(double) onProgress) uploadTask;

  const UploadProgressDialog({
    super.key,
    required this.title,
    required this.uploadTask,
  });

  /// 静态便捷调用方法
  static Future<T?> show<T>(
      BuildContext context, {
        required String title,
        required Future<dynamic> Function(Function(double) onProgress) uploadTask,
      }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false, // 禁止点击背景关闭
      builder: (context) => UploadProgressDialog(title: title, uploadTask: uploadTask),
    );
  }

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog> {
  //  使用 ValueNotifier 代替 setState，性能更好
  final ValueNotifier<double> _progressNotifier = ValueNotifier<double>(0.0);
  Timer? _fakeTimer;

  @override
  void initState() {
    super.initState();
    _startFakeProgress();
    _startTask();
  }

  //  启动"假进度"：在前 25% 阶段模拟匀速前进
  // 掩盖压缩图片和请求 URL 的耗时
  void _startFakeProgress() {
    _fakeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;

      // 直接修改 notifier，不触发整个页面 build
      if (_progressNotifier.value < 0.25) {
        _progressNotifier.value += 0.005; // 每次加 0.5%，非常丝滑
      } else {
        _fakeTimer?.cancel();
      }
    });
  }

  void _startTask() async {
    try {
      final result = await widget.uploadTask((realProgress) {
        if (mounted) {
          // 只有当真实进度反超假进度时，才接管
          if (realProgress > _progressNotifier.value) {
            _progressNotifier.value = realProgress;
          }
        }
      });

      _fakeTimer?.cancel();
      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      _fakeTimer?.cancel();
      if (mounted) {
        Navigator.of(context).pop(); // 关闭弹窗
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload failed: $e"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fakeTimer?.cancel();
    _progressNotifier.dispose(); // 记得销毁
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 拦截返回键，防止误触导致上传中断
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
              Text(
                widget.title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              //  局部刷新构建器，只重绘进度部分
              ValueListenableBuilder<double>(
                valueListenable: _progressNotifier,
                builder: (context, progress, child) {
                  return Column(
                    children: [
                      // 动画补帧：让跳跃的进度值变得平滑
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 90,
                                height: 90,
                                child: CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.grey[100],
                                  valueColor: AlwaysStoppedAnimation<Color>(context.bgBrandSolid),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Text(
                                "${(value * 100).toInt()}%",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: context.bgBrandSolid,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // 动态文案
                      Text(
                        progress < 0.25 ? "Preparing file..." : "Uploading...",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
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