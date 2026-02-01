import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/chat_ui_model.dart';
import '../../services/database/local_database_service.dart';
import '../../../../utils/asset/asset_manager.dart';
import '../../services/download/file_download_service.dart';

class FileMsgBubble extends ConsumerStatefulWidget {
  final ChatUiModel message;

  const FileMsgBubble({super.key, required this.message});

  @override
  ConsumerState<FileMsgBubble> createState() => _FileMsgBubbleState();
}


class _FileMsgBubbleState extends ConsumerState<FileMsgBubble> {
  // 状态机
  bool _isDownloading = false;
  double _progress = 0.0;
  String? _finalLocalPath;
  final CancelToken _cancelToken = CancelToken();

  @override
  void initState() {
    super.initState();
    _checkFile();
  }

  @override
  void dispose() {
    if (_isDownloading) _cancelToken.cancel();
    super.dispose();
  }

  // 1. 检查状态 -> 交给 Service
  void _checkFile() async {
    final path = await ref.read(fileDownloadServiceProvider).checkLocalFile(widget.message.localPath);
    if (path != null && mounted) {
      setState(() => _finalLocalPath = path);
    }
  }

  // 2. 下载/打开 -> 交给 Service
  void _handleTap() async {
    final service = ref.read(fileDownloadServiceProvider);

    // 情况 A: 发送中，点不动
    if (widget.message.status == MessageStatus.sending) return;

    // 情况 B: 正在下载，点击取消
    if (_isDownloading) {
      _cancelToken.cancel();
      setState(() => _isDownloading = false);
      return;
    }

    // 情况 C: 已有文件，点击打开
    if (_finalLocalPath != null) {
      try {
        await service.openLocalFile(_finalLocalPath!);
      } catch (e) {
        debugPrint(e.toString());
      }
      return;
    }

    // 情况 D: 需要下载 (Web端是直接打开链接)
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
    });

    try {
      final path = await service.downloadOrOpen(
        widget.message,
        cancelToken: _cancelToken,
        onProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() => _progress = received / total);
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          // Web 端 path 是 null，但没关系，点击逻辑里会处理 Web 跳转
          if (path != null) _finalLocalPath = path;
        });
      }
    } catch (e) {
      debugPrint("Download error: $e");
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. 数据准备
    final ext = widget.message.fileExt ?? 'bin';
    final name = widget.message.fileName ?? 'Unknown File';
    final sizeStr = widget.message.displaySize;
    final style = _getFileStyle(ext);
    final isDownloaded = _finalLocalPath != null;
    final isSending = widget.message.status == MessageStatus.sending;

    // 2. 气泡宽度 (参考 ImageMsgBubble: 0.60.sw，文件可以稍微宽一点以便显示长文件名)
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
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 8.h), // 底部留点空间给时间戳
          decoration: BoxDecoration(
            color: Colors.white, // 文件气泡通常是白底
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Stack(
            children: [
              // === 主内容区 ===
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧：动态图标区
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
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          _isDownloading
                              ? "Downloading ${( _progress * 100).toInt()}%"
                              : sizeStr,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                        // 预留空间给绝对定位的时间戳，防止文字重叠
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
                ],
              ),

              // === 时间戳 (右下角) ===
              // 模仿 ImageMsgBubble 的 _buildTimeTag
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

  // 左侧图标区 (集成 发送中/下载中/文件类型)
  Widget _buildIconArea(_FileStyle style, bool isDownloaded, bool isSending) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 背景块
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: style.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),

        // 状态分层显示
        if (isSending)
          SizedBox(
            width: 20.w, height: 20.w,
            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
          )
        else if (_isDownloading)
          SizedBox(
            width: 20.w, height: 20.w,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 2.5,
              color: style.color,
            ),
          )
        else
          Icon(
            isDownloaded ? style.icon : Icons.arrow_circle_down_rounded,
            color: style.color,
            size: 26.sp,
          ),
      ],
    );
  }

  // 完全复刻 ImageMsgBubble 的时间胶囊样式
  Widget _buildTimeTag(String time) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2), // 白底上改用浅灰背景
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        time,
        style: TextStyle(
            color: Colors.grey[700], // 字体改深色
            fontSize: 9.sp,
            fontWeight: FontWeight.w500
        ),
      ),
    );
  }

  // 样式映射表
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