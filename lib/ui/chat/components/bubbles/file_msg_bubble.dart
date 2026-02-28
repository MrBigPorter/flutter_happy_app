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
  // Simplified state machine: primarily tracks active processing state
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
    // Cancel active download if component is disposed
    if (_isLoading) _cancelToken.cancel();
    super.dispose();
  }

  // 1. Initial check to verify if the file exists locally
  void _checkFile() async {
    final path = await ref.read(fileDownloadServiceProvider).checkLocalFile(widget.message.localPath);
    if (path != null && mounted) {
      setState(() => _finalLocalPath = path);
    }
  }

  // 2. Interaction logic: Handles both opening and downloading based on local file availability
  void _handleTap() async {
    // Prevent duplicate triggers if already processing
    if (_isLoading) return;

    // Ignore clicks if the message is still in the process of sending
    if (widget.message.status == MessageStatus.sending) return;

    final service = ref.read(fileDownloadServiceProvider);

    // Scenario A: Local file exists -> Open directly
    if (_finalLocalPath != null) {
      try {
        await service.openLocalFile(_finalLocalPath!);
      } catch (e) {
        debugPrint("[FileBubble] Open error: $e");
        RadixToast.error("Failed to open file.");
      }
      return;
    }

    // Scenario B: File needs to be downloaded (Direct browser download on Web)
    setState(() => _isLoading = true);

    try {
      final path = await service.downloadOrOpen(
        widget.message,
        cancelToken: _cancelToken,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          // path returns null on Web, and local path on Native
          if (path != null) _finalLocalPath = path;
        });
      }
    } catch (e) {
      debugPrint("[FileBubble] Download error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Data Preparation
    final ext = widget.message.fileExt ?? 'bin';
    final name = widget.message.fileName ?? 'Unknown File';
    final sizeStr = widget.message.displaySize;
    final style = _getFileStyle(ext);

    // State determination
    final bool isDownloaded = _finalLocalPath != null;
    final bool isSending = widget.message.status == MessageStatus.sending;

    // 2. Bubble Sizing
    final double baseWidth = 0.65.sw;

    // 3. Timestamp formatting
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
            color: context.bgSecondary,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: context.borderPrimary),
          ),
          child: Stack(
            children: [
              // === Main Content Area ===
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Dynamic Icon Area
                  _buildIconArea(style, isDownloaded, isSending),

                  SizedBox(width: 12.w),

                  // Right: Information Area
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
                            color: context.textPrimary900,
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
                        // Reserved space for timestamp
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),
                ],
              ),

              // === Timestamp (Bottom Right) ===
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

  // Left Icon Area: Logic priority -> Sending > Loading > Downloaded > Pending
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
    // 1. Sending State (Gray progress indicator)
    if (isSending) {
      return SizedBox(
        width: 20.w, height: 20.w,
        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
      );
    }

    // 2. Loading State (Colored progress indicator for Download/Open)
    if (_isLoading) {
      return SizedBox(
        width: 20.w, height: 20.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: style.color,
        ),
      );
    }

    // 3. Downloaded State (Specific file type icon)
    if (isDownloaded) {
      return Icon(
        style.icon,
        color: style.color,
        size: 26.sp,
      );
    }

    // 4. Pending Download (Download arrow icon)
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

  // Style mapper for different file extensions
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