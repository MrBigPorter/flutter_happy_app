import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../providers/chat_search_provider.dart';

class ChatSearchPage extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatSearchPage({super.key, required this.conversationId});

  @override
  ConsumerState<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends ConsumerState<ChatSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _currentKeyword = "";

  @override
  void initState() {
    super.initState();
    // 页面加载后，键盘自动弹起
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _currentKeyword = value;
    });
    ref.read(chatSearchControllerProvider(widget.conversationId).notifier).search(value);
  }

  @override
  Widget build(BuildContext context) {
    // 监听搜索结果的状态
    final searchState = ref.watch(chatSearchControllerProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: context.bgSecondary,
      appBar: _buildSearchBar(context),
      body: _buildBody(context, searchState),
    );
  }

  // ==========================================
  //  1. 顶部搜索框 (自动对焦 + 清除按钮)
  // ==========================================
  PreferredSizeWidget _buildSearchBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.bgPrimary,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: context.textPrimary900, size: 20.sp),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Container(
        height: 36.h,
        margin: EdgeInsets.only(right: 16.w),
        decoration: BoxDecoration(
          color: context.bgSecondary,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(fontSize: 14.sp, color: context.textPrimary900),
          decoration: InputDecoration(
            hintText: "Search chat history",
            hintStyle: TextStyle(fontSize: 14.sp, color: context.textSecondary700),
            prefixIcon: Icon(Icons.search, size: 18.sp, color: context.textSecondary700),
            suffixIcon: _currentKeyword.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.cancel, size: 16.sp, color: context.textSecondary700),
              onPressed: () {
                _searchController.clear();
                _onSearchChanged("");
              },
            )
                : null,
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8.h),
          ),
        ),
      ),
    );
  }

  // ==========================================
  //  2. 主体状态流转 (Loading / Empty / List)
  // ==========================================
  Widget _buildBody(BuildContext context, AsyncValue<List<ChatUiModel>> searchState) {
    if (_currentKeyword.trim().isEmpty) {
      return const SizedBox.shrink(); // 没搜的时候直接留白
    }

    return searchState.when(
      loading: () => Center(child: CircularProgressIndicator(color: context.utilityGreen500)),
      error: (err, _) => Center(child: Text("Search failed: $err")),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Text(
              'No results found for "$_currentKeyword"',
              style: TextStyle(color: context.textSecondary700, fontSize: 14.sp),
            ),
          );
        }

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: context.borderPrimary),
          itemBuilder: (context, index) {
            final msg = results[index];
            return _buildResultItem(context, msg);
          },
        );
      },
    );
  }

  // ==========================================
  //  3. 每一条结果的渲染与点击穿越
  // ==========================================
  Widget _buildResultItem(BuildContext context, ChatUiModel msg) {
    return InkWell(
      onTap: () {
        // 🚀 核心：点击后关掉搜索页，并把 seqId 返回给聊天页！
        // 聊天页接收到这个返回值后，就可以控制 ListView 滚动到这个位置
        Navigator.pop(context, msg.seqId);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        color: context.bgPrimary,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头像
            _buildAvatar(context, msg.senderAvatar),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 昵称 & 时间
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        msg.senderName ?? "Unknown",
                        style: TextStyle(fontSize: 14.sp, color: context.textSecondary700),
                      ),
                      Text(
                        DateFormatHelper.formatDate(msg.createdAt),
                        style: TextStyle(fontSize: 12.sp, color: context.textSecondary700),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  _buildHighlightedText(context, msg.content, _currentKeyword),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String? avatarUrl) {
    return Container(
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.r),
        color: context.bgSecondary,
        image: avatarUrl != null
            ? DecorationImage(
          image: CachedNetworkImageProvider(UrlResolver.resolveImage(context, avatarUrl, logicalWidth: 40)),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: avatarUrl == null ? Icon(Icons.person, color: context.textSecondary700) : null,
    );
  }

  // ==========================================
  //  4. 绝杀技：关键字高亮算法 (RichText)
  // ==========================================
  Widget _buildHighlightedText(BuildContext context, String text, String keyword) {
    if (keyword.isEmpty) return Text(text);

    // 忽略大小写分割字符串
    final regex = RegExp(keyword, caseSensitive: false);
    final matches = regex.allMatches(text).toList();

    if (matches.isEmpty) {
      return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);
    }

    List<TextSpan> spans = [];
    int currentIndex = 0;

    for (final match in matches) {
      // 关键字前面的普通文本
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }
      // 关键字文本 (标绿)
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: TextStyle(color: context.utilityGreen500, fontWeight: FontWeight.bold),
        ),
      );
      currentIndex = match.end;
    }

    // 关键字后面的剩余普通文本
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(fontSize: 15.sp, color: context.textPrimary900),
        children: spans,
      ),
    );
  }
}