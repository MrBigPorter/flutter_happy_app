import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../models/chat_ui_model.dart';
import '../../services/download/file_download_service.dart';

class FileMsgBubble extends ConsumerStatefulWidget {
  final ChatUiModel message;

  const FileMsgBubble({super.key, required this.message});

  @override
  ConsumerState<FileMsgBubble> createState() => _FileMsgBubbleState();
}

class _FileMsgBubbleState extends ConsumerState<FileMsgBubble> {
  // 简化状态机：只关心是否正在处理中
  bool _isLoading = false;
  String? _finalLocalPath;
  final CancelToken _cancelToken = CancelToken();

  @override
  void initState() {
    super.initState();
    _checkFile();
  }

  @override
  void dispose() {
    if (_isLoading) _cancelToken.cancel();
    super.dispose();
  }

  // 1. 初始化检查文件是否存在
  void _checkFile() async {
    final path = await ref.read(fileDownloadServiceProvider).checkLocalFile(widget.message.localPath);
    if (path != null && mounted) {
      setState(() => _finalLocalPath = path);
    }
  }

  // 2. 点击逻辑：简化版
  void _handleTap() async {
    // 正在处理中，忽略点击 (防止重复触发)
    if (_isLoading) return;

    // 消息正在发送中，忽略点击
    if (widget.message.status == MessageStatus.sending) return;

    final service = ref.read(fileDownloadServiceProvider);

    // 情况 A: 已有本地文件 -> 直接打开
    if (_finalLocalPath != null) {
      try {
        await service.openLocalFile(_finalLocalPath!);
      } catch (e) {
        debugPrint("Open error: $e");
        RadixToast.error("Failed to open file.");
      }
      return;
    }

    // 情况 B: 需要下载 (Web端是直接触发浏览器下载)
    // 切换到 Loading 状态
    setState(() => _isLoading = true);

    try {
      // 这里的 onProgress 我们不需要了，因为只显示转圈圈
      final path = await service.downloadOrOpen(
        widget.message,
        cancelToken: _cancelToken,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          // Web 端 path 是 null，Native 端是本地路径
          if (path != null) _finalLocalPath = path;
        });
      }
    } catch (e) {
      debugPrint("Download error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        // 可以选加一个 Toast 提示失败
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 数据准备
    final ext = widget.message.fileExt ?? 'bin';
    final name = widget.message.fileName ?? 'Unknown File';
    final sizeStr = widget.message.displaySize;
    final style = _getFileStyle(ext);

    // 状态判断：是否有文件?
    // Web端我们通常认为如果没有 _isLoading 就是待下载状态(除非你存了blob状态，但这里简单处理)
    final bool isDownloaded = _finalLocalPath != null;
    final bool isSending = widget.message.status == MessageStatus.sending;

    // 2. 气泡宽度
    final double baseWidth = 0.65.sw;

    // 3. 时间字符串
    final timeStr = DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(widget.message.createdAt),
    );

    return RepaintBoundary(
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          width: baseWidth,
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h),
          decoration: BoxDecoration(
            color:context.bgSecondary,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: context.borderPrimary),
          ),
          child: Stack(
            children: [
              // === 主内容区 ===
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧：动态图标区 (核心修改)
                  _buildIconArea(style, isDownloaded, isSending),

                  SizedBox(width: 12.w),

                  // 右侧：信息区
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color:context.textPrimary900,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          _isLoading ? "Loading..." : sizeStr,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: _isLoading ? style.color : Colors.grey[500],
                            fontWeight: _isLoading ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        // 预留空间给时间戳
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
                ],
              ),

              // === 时间戳 (右下角) ===
              Positioned(
                right: 0,
                bottom: 0,
                child: _buildTimeTag(timeStr),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 左侧图标区：精简版
  // 优先级：发送中 > 加载中(下载/打开) > 已下载(显示文件图标) > 未下载(显示下载箭头)
  Widget _buildIconArea(_FileStyle style, bool isDownloaded, bool isSending) {
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: style.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      alignment: Alignment.center,
      child: _buildInnerIcon(style, isDownloaded, isSending),
    );
  }

  Widget _buildInnerIcon(_FileStyle style, bool isDownloaded, bool isSending) {
    // 1. 发送中 (转灰圈)
    if (isSending) {
      return SizedBox(
        width: 20.w, height: 20.w,
        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
      );
    }

    // 2. 加载中 (转色圈) - 下载或打开
    if (_isLoading) {
      return SizedBox(
        width: 20.w, height: 20.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: style.color, // 使用文件类型的颜色
        ),
      );
    }

    // 3. 已下载 (显示文件类型图标)
    if (isDownloaded) {
      return Icon(
        style.icon, // e.g. PDF icon
        color: style.color,
        size: 26.sp,
      );
    }

    // 4. 未下载 (显示下载箭头)
    return Icon(
      Icons.arrow_circle_down_rounded,
      color: style.color,
      size: 26.sp,
    );
  }

  Widget _buildTimeTag(String time) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        time,
        style: TextStyle(
            color: context.textSecondary700,
            fontSize: 9.sp,
            fontWeight: FontWeight.w500
        ),
      ),
    );
  }

  _FileStyle _getFileStyle(String ext) {
    final e = ext.toLowerCase();
    if (['pdf'].contains(e)) return _FileStyle(Colors.redAccent, Icons.picture_as_pdf);
    if (['doc', 'docx'].contains(e)) return _FileStyle(Colors.blueAccent, Icons.description);
    if (['xls', 'xlsx', 'csv'].contains(e)) return _FileStyle(Colors.green, Icons.table_chart);
    if (['ppt', 'pptx'].contains(e)) return _FileStyle(Colors.orange, Icons.pie_chart);
    if (['zip', 'rar', '7z'].contains(e)) return _FileStyle(Colors.amber[700]!, Icons.folder_zip);
    if (['mp3', 'wav', 'm4a'].contains(e)) return _FileStyle(Colors.purpleAccent, Icons.audio_file);
    if (['mp4', 'mov', 'avi'].contains(e)) return _FileStyle(Colors.deepPurple, Icons.video_file);
    if (['apk'].contains(e)) return _FileStyle(Colors.teal, Icons.android);
    return _FileStyle(Colors.grey[700]!, Icons.insert_drive_file);
  }
}

class _FileStyle {
  final Color color;
  final IconData icon;
  _FileStyle(this.color, this.icon);
}