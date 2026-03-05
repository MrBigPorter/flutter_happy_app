import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';

import 'package:flutter_app/core/api/lucky_api.dart';

/// Customer Service Helper: Handles initiating customer service chats
class CustomerServiceHelper {
  // Prevent multiple simultaneous chat initiations
  static bool _isLoading = false;

  // start customer service chat
  static Future<void> startChat() async {
    if (_isLoading) return;

    _isLoading = true;
    RadixToast.showLoading(); // 全局弹窗 loading

    try {
      final conversation = await Api.chatBusinessApi('official_platform_support_v1');

      RadixToast.hide();

      appRouter.push('/chat/room/${conversation.conversationId}');
    } catch (e) {
      RadixToast.hide();
      RadixToast.error('Customer service is currently unavailable.');
      debugPrint('[CustomerService] Error: $e');
    } finally {
      _isLoading = false;
    }
  }
}
