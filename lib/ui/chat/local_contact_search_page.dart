import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/ui/chat/providers/contact_search_provider.dart';
import 'package:flutter_app/ui/chat/providers/conversation_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';

import '../toast/radix_toast.dart';
import 'models/conversation.dart';

class LocalContactSearchPage extends ConsumerStatefulWidget {
  const LocalContactSearchPage({super.key});

  @override
  ConsumerState<LocalContactSearchPage> createState() => _LocalContactSearchPageState();
}

class _LocalContactSearchPageState extends ConsumerState<LocalContactSearchPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听本地搜索结果
    final asyncResults = ref.watch(contactSearchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: context.bgSecondary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: context.textPrimary900, size: 20.sp),
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 36.h,
          margin: EdgeInsets.only(right: 16.w),
          decoration: BoxDecoration(
            color: context.bgSecondary,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            style: TextStyle(fontSize: 14.sp, color: context.textPrimary900),
            decoration: InputDecoration(
              hintText: "Search friends (Name/Pinyin)",
              hintStyle: TextStyle(color: context.textSecondary700),
              prefixIcon: Icon(Icons.search, color: context.textSecondary700, size: 20.sp),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8.h),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                icon: Icon(Icons.cancel, color: context.textSecondary700, size: 16.sp),
                onPressed: () {
                  _controller.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                },
              )
                  : null,
            ),
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
          ),
        ),
      ),
      body: asyncResults.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (results) {
          if (query.isEmpty) {
            return Center(
              child: Text(
                "Try searching by name or pinyin",
                style: TextStyle(color: context.textSecondary700),
              ),
            );
          }

          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 48.sp, color: context.textSecondary700.withOpacity(0.3)),
                  SizedBox(height: 8.h),
                  Text("No results for '$query'", style: TextStyle(color: context.textSecondary700)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: results.length,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            separatorBuilder: (_, __) => Divider(height: 1, color: context.bgSecondary),
            itemBuilder: (context, index) {
              final user = results[index];
              return _buildResultItem(context, user);
            },
          );
        },
      ),
    );
  }

  Widget _buildResultItem(BuildContext context, ChatUser user) {
    return ListTile(
      tileColor: context.bgPrimary,
      //  2. 修改点击事件：先创建会话，再跳转
      onTap: () async {
        // 收起键盘
        FocusScope.of(context).unfocus();
        RadixToast.showLoading();

        try {
          final conversation = await ref
              .read(createDirectChatControllerProvider.notifier)
              .createDirectChat(user.id);

          if (conversation != null && context.mounted) {
            // 使用 push，这样用户还能按返回键回到搜索页
            appRouter.push('/chat/room/${conversation.conversationId}');
          }
        } catch (e) {
          RadixToast.error(e.toString());
        } finally {
          RadixToast.hide();
        }
      },
      leading: CircleAvatar(
        radius: 20.r,
        backgroundColor: context.bgBrandSecondary,
        backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
            ? CachedNetworkImageProvider(UrlResolver.resolveImage(context, user.avatar!))
            : null,
        child: (user.avatar == null || user.avatar!.isEmpty)
            ? Text(
          user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : "?",
          style: TextStyle(color: context.utilityBrand500, fontWeight: FontWeight.bold),
        )
            : null,
      ),
      title: Text(
        user.nickname,
        style: TextStyle(color: context.textPrimary900, fontWeight: FontWeight.w600, fontSize: 15.sp),
      ),
      subtitle: Text(
        "ID: ${user.id}",
        style: TextStyle(color: context.textSecondary700, fontSize: 12.sp),
      ),
    );
  }
}