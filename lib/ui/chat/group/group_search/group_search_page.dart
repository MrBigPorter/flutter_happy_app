import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';
import 'package:flutter_app/ui/chat/models/conversation.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:flutter_app/ui/chat/providers/group_search_provider.dart';

import 'package:flutter_app/app/routes/app_router.dart';

// 引入逻辑分片
part 'group_search_logic.dart';

class GroupSearchPage extends ConsumerStatefulWidget {
  const GroupSearchPage({super.key});

  @override
  ConsumerState<GroupSearchPage> createState() => _GroupSearchPageState();
}

class _GroupSearchPageState extends ConsumerState<GroupSearchPage> {
  final _controller = TextEditingController();

  // UI 状态：是否触发过搜索（用于控制初始提示文案的显示）
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听 Provider 数据状态
    final searchState = ref.watch(groupSearchControllerProvider);

    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        title: Text(
          "Join Group",
          style: TextStyle(
              color: context.textPrimary900,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.bgPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: context.textPrimary900),
      ),
      body: Column(
        children: [
          // =================================================
          // 1. 顶部搜索框区域
          // =================================================
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            color: context.bgPrimary,
            child: Column(
              children: [
                TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  // 转发给 Logic 处理
                  onSubmitted: (_) => _GroupSearchLogic.handleSearch(
                    context: context,
                    ref: ref,
                    controller: _controller,
                    onSearchStateChanged: () => setState(() => _hasSearched = true),
                  ),
                  style: TextStyle(fontSize: 16.sp, color: context.textPrimary900),
                  decoration: InputDecoration(
                    hintText: "Search Group ID or Name",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search, color: context.textSecondary700),
                    filled: true,
                    fillColor: context.bgSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                    suffixIcon: ValueListenableBuilder(
                      valueListenable: _controller,
                      builder: (context, value, child) {
                        return _controller.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey, size: 18.r),
                          // 转发给 Logic 处理
                          onPressed: () => _GroupSearchLogic.handleClear(_controller),
                        )
                            : const SizedBox();
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Button(
                  width: double.infinity,
                  loading: searchState.isLoading,
                  // 转发给 Logic 处理
                  onPressed: () => _GroupSearchLogic.handleSearch(
                    context: context,
                    ref: ref,
                    controller: _controller,
                    onSearchStateChanged: () => setState(() => _hasSearched = true),
                  ),
                  child: const Text("Search"),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: context.bgSecondary),

          // =================================================
          // 2. 结果展示区域
          // =================================================
          Expanded(
            child: searchState.when(
              // Loading 由 Button 显示，这里留白
              loading: () => const SizedBox(),

              // 错误状态
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48.r, color: Colors.red[300]),
                    SizedBox(height: 12.h),
                    Text("Search failed", style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),

              // 数据展示
              data: (results) {
                // A. 初始状态 (未搜索)
                if (!_hasSearched && results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64.r, color: Colors.grey[300]),
                        SizedBox(height: 12.h),
                        Text("Search for interesting communities",
                            style: TextStyle(color: Colors.grey[500], fontSize: 14.sp)),
                      ],
                    ),
                  );
                }

                // B. 无结果
                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64.r, color: Colors.grey[300]),
                        SizedBox(height: 12.h),
                        Text("No groups found",
                            style: TextStyle(color: Colors.grey[500], fontSize: 14.sp)),
                      ],
                    ),
                  );
                }

                // C. 结果列表
                return ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  itemCount: results.length,
                  separatorBuilder: (_, __) =>
                      Divider(indent: 72.w, height: 1, color: context.bgSecondary),
                  itemBuilder: (context, index) {
                    final group = results[index];
                    return _GroupResultItem(
                      group: group,
                      onTap: () => _GroupSearchLogic.handleResultTap(context, group),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
// Sub-Widgets (保留在 UI 文件中，因为它们属于 View 层)
// =================================================================

class _GroupResultItem extends StatelessWidget {
  final GroupSearchResult group;
  final VoidCallback onTap;

  const _GroupResultItem({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            // 头像
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: CachedNetworkImage(
                imageUrl: UrlResolver.resolveImage(context, group.avatar, logicalWidth: 48),
                width: 48.r,
                height: 48.r,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: context.bgSecondary),
                errorWidget: (_, __, ___) => Container(
                  color: context.bgSecondary,
                  alignment: Alignment.center,
                  child: Text(
                    group.name.isNotEmpty ? group.name[0].toUpperCase() : "?",
                    style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500]),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // 信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name,
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "ID: ${group.id} • ${group.memberCount} members",
                    style: TextStyle(fontSize: 12.sp, color: context.textSecondary700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 状态
            if (group.isMember)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: context.bgSecondary,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text("Joined",
                    style: TextStyle(color: context.textSecondary700, fontSize: 12.sp)),
              )
            else
              Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }
}