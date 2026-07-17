import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';

import 'package:flutter_app/core/api/lucky_api.dart';

enum CustomerServiceScene { support, business }

/// Customer Service Helper: Handles initiating customer service chats
class CustomerServiceHelper {
  static const String defaultSupportBusinessId = 'official_platform_support_v1';

  // Prevent multiple simultaneous chat initiations
  static bool _isLoading = false;

  /// 入口上下文（静态存储，ChatPage 读取后清空）
  // @deprecated 后续统一走 HTTP POST /chat/message + Socket aiEventStream
  // pendingEntryPoint/pendingMetadata 仅用于 SSE AI 模式的入口上下文，后续可移除
  static String? pendingEntryPoint;
  static Map<String, dynamic>? pendingMetadata;

  // start customer service chat
  static Future<void> startChat({
    CustomerServiceScene scene = CustomerServiceScene.support,
    String? businessId,
    String? entryPoint,
    Map<String, dynamic>? metadata,
  }) async {
    if (_isLoading) return;

    final resolvedBusinessId = _resolveBusinessId(
      scene: scene,
      businessId: businessId,
    );
    if (resolvedBusinessId == null || resolvedBusinessId.isEmpty) {
      RadixToast.error('Missing customer service business id.');
      return;
    }

    // 把入口上下文暂存到静态变量，ChatPage 读取后清空
    pendingEntryPoint = entryPoint;
    pendingMetadata = metadata;

    _isLoading = true;
    RadixToast.showLoading(); // 全局弹窗 loading

    try {
      final conversation = await Api.chatBusinessApi(resolvedBusinessId);

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

  static String? _resolveBusinessId({
    required CustomerServiceScene scene,
    String? businessId,
  }) {
    if (businessId != null && businessId.isNotEmpty) {
      return businessId;
    }

    if (scene == CustomerServiceScene.support) {
      return defaultSupportBusinessId;
    }

    return null;
  }
}
