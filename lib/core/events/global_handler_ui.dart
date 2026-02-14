part of 'global_handler.dart';

// 职责：专注于“样式呈现与交互”的逻辑分层
extension GlobalHandlerUIExtension on _GlobalHandlerState {

  /// 1. 交互式好友申请通知 (使用 RadixToast 核心逻辑)
  void _showContactApplyNotification(Map<String, dynamic> data) {
    // 数据预处理
    final String nickname = data['nickname'] ?? data['applicantId'] ?? 'Someone';
    final String reason = data['reason'] ?? 'Wants to add you';

    //  改动：使用自定义 Notification 构建，但保持 RadixToast 的现代感设计
    BotToast.showCustomNotification(
      duration: const Duration(seconds: 5),
      toastBuilder: (cancelFunc) {
        return _buildModernNotificationCard(
          context: context,
          title: "Friend Request",
          message: "$nickname: $reason",
          leading: CircleAvatar(
            radius: 18.r,
            backgroundColor: context.bgBrandSecondary,
            child: Icon(Icons.person_add_rounded, color: context.utilityBrand500, size: 20.sp),
          ),
          onTap: () {
            cancelFunc(); // 点击后关闭通知
            appRouter.push('/contact/new-friends'); // 直达申请列表页
          },
        );
      },
    );
  }

  ///  2. 成功提示：直接调用封装好的 RadixToast
  void _showSuccessToast(String title, String msg) {
    if (_isDuplicate(title, msg)) return;
    RadixToast.success(msg, title: title);
  }

  ///  3. 错误提示：直接调用封装好的 RadixToast
  void _showErrorToast(String title, String msg) {
    if (_isDuplicate(title, msg)) return;
    RadixToast.error(msg, title: title);
  }

  // ----------------------------------------------------------------
  //  内部逻辑与系统弹窗 (保持不变)
  // ----------------------------------------------------------------

  /// 通用去重判断
  bool _isDuplicate(String title, String msg) {
    final String key = '$title|$msg';
    final DateTime now = DateTime.now();
    if (_lastToastKey == key &&
        _lastToastTime != null &&
        now.difference(_lastToastTime!) < const Duration(seconds: 2)) {
      return true;
    }
    _lastToastKey = key;
    _lastToastTime = now;
    return false;
  }

  /// 处理 EventBus 传来的全局系统事件
  void _handleGlobalEvent(GlobalEvent event) {
    if (!mounted) return;
    if (event.type == GlobalEventType.deviceBanned) _showLockDialog();
  }

  ///  4. 系统锁定对话框 (完整的 RadixModal 实现)
  void _showLockDialog() {
    RadixModal.show(
      config: ModalDialogConfig(showCloseButton: false),
      clickBgToClose: false,
      builder: (context, close) {
        return PopScope(
          canPop: false,
          child: Container(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_person_rounded, size: 48.w, color: context.textPrimary900),
                SizedBox(height: 16.h),
                Text('security.device_banned_title'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: context.textPrimary900)),
                SizedBox(height: 8.h),
                Text('security.device_banned_desc'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: context.textSecondary700)),
                SizedBox(height: 24.h),
                Button(onPressed: () {}, child: Text('security.btn_contact_support'.tr())),
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: () => Platform.isAndroid ? SystemNavigator.pop() : exit(0),
                  child: Padding(padding: EdgeInsets.symmetric(vertical: 8.h), child: Text('security.btn_exit_app'.tr(), style: TextStyle(color: context.textSecondary700))),
                ),
              ],
            ),
          ),
        );
      },
      confirmText: '', cancelText: '',
    );
  }

  // 注：这里的 _buildModernNotificationCard 可以保留在当前文件作为私有构建器，
  // 也可以迁移到 RadixToast 内部作为一个通用的基础构建方法。
  Widget _buildModernNotificationCard({
    required BuildContext context,
    required String title,
    required String message,
    required Widget leading,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: context.bgSecondary, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                leading,
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: context.textPrimary900)),
                      SizedBox(height: 2.h),
                      Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.sp, color: context.textSecondary700)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: context.textSecondary700, size: 20.sp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}