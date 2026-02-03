import 'dart:ui';
import 'package:azlistview/azlistview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/app/routes/app_router.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/base_scaffold.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/ui/chat/providers/contact_provider.dart';
import 'package:flutter_app/utils/url_resolver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpinyin/lpinyin.dart';

import 'models/conversation.dart';

class ContactEntity extends ISuspensionBean {
  final ChatUser user;
  String tagIndex;

  ContactEntity({required this.user, this.tagIndex = ""});

  @override
  String getSuspensionTag() => tagIndex;
}

class ContactListPage extends ConsumerWidget {
  const ContactListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncContacts = ref.watch(contactListProvider);
    final asyncRequests = ref.watch(friendRequestListProvider);
    final int requestCount = asyncRequests.valueOrNull?.length ?? 0;

    return BaseScaffold(
      title: "Contacts",
      actions: [
        IconButton(
          icon: Icon(Icons.search_rounded, size: 24.sp, color: context.textPrimary900),
          onPressed: () => appRouter.push('/contact/search'),
        ),
        SizedBox(width: 8.w),
      ],
      body: Container(
        color: context.bgSecondary,
        width: double.infinity, //  确保宽度撑满
        height: double.infinity, //  确保高度撑满，防止 AzListView 布局错误
        child: asyncContacts.when(
          loading: () => _buildSkeleton(context),
          error: (err, _) => Center(child: Text("Load Error: $err")),
          data: (contacts) {
            // 如果没数据，直接显示空状态，别去算拼音了
            if (contacts.isEmpty) return _buildEmptyState(context, requestCount);

            // 1. 数据转换
            final List<ContactEntity> contactModels = _processData(contacts);
            // 2. 提取索引
            final List<String> indexData = SuspensionUtil.getTagIndexList(contactModels);

            return Column(
              children: [
                // 顶部固定入口
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                  child: _buildActionSection(context, requestCount),
                ),

                Expanded(
                  child: AzListView(
                    data: contactModels,
                    itemCount: contactModels.length,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: _buildContactItem(context, contactModels[index].user),
                    ),
                    susItemBuilder: (context, index) => _buildHeader(context,contactModels[index].tagIndex),

                    // 索引条数据
                    indexBarData: indexData,

                    //  核心配置：索引条样式
                    indexBarOptions: IndexBarOptions(
                      needRebuild: true,
                      selectTextStyle: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold),
                      selectItemDecoration: BoxDecoration(shape: BoxShape.circle, color: context.utilityBrand500),
                      textStyle: TextStyle(fontSize: 10.sp, color: context.textSecondary700),
                      downTextStyle: TextStyle(fontSize: 12.sp, color: Colors.white),
                      downItemDecoration: BoxDecoration(shape: BoxShape.circle, color: context.utilityBrand500),
                    ),
                    indexHintBuilder: (context, tag) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(20.r),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                            alignment: Alignment.center,
                            width: 80.r,
                            height: 80.r,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6), // 半透明黑底
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36.sp,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  //  下面是辅助函数，逻辑微调增强健壮性

  List<ContactEntity> _processData(List<ChatUser> contacts) {
    List<ContactEntity> list = contacts.map((e) {
      //  增加判空防御
      if (e.nickname.isEmpty) {
        return ContactEntity(user: e, tagIndex: "#");
      }
      String pinyin = PinyinHelper.getPinyinE(e.nickname);
      String tag = pinyin.substring(0, 1).toUpperCase();
      if (!RegExp("[A-Z]").hasMatch(tag)) tag = "#";
      return ContactEntity(user: e, tagIndex: tag);
    }).toList();

    SuspensionUtil.sortListBySuspensionTag(list);
    SuspensionUtil.setShowSuspensionStatus(list);
    return list;
  }

  // 样式保持原样，微调颜色
  Widget _buildHeader(BuildContext context,String tag) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 16.w, 8.h),
      alignment: Alignment.centerLeft,
      // AzListView 的 Header 默认是透明的，如果不给颜色，滑上去的时候背景文字会透出来重叠
      color: context.bgSecondary, //  必须给 Header 一个不透明背景色！
      child: Text(
        tag,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.grey[500]),
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, int count) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: _buildActionRow(
        context,
        icon: Icons.person_add_rounded,
        color: Colors.orange,
        title: "New Friends",
        count: count,
        onTap: () => appRouter.push('/contact/new-friends'),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, {required IconData icon, required Color color, required String title, int count = 0, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10.r)),
              child: Icon(icon, color: color, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: context.textPrimary900)),
            ),
            if (count > 0)
              Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10.r)),
                child: Text("$count", style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold)),
              ),
            Icon(Icons.chevron_right_rounded, size: 20.sp, color: context.textSecondary700.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(BuildContext context, ChatUser user) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.bgSecondary, width: 0.5),
      ),
      child: ListTile(
        onTap: () => appRouter.push('/contact/profile/${user.id}'),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        leading: CircleAvatar(
          radius: 22.r,
          backgroundColor: context.bgBrandSecondary,
          backgroundImage: user.avatar != null
              ? CachedNetworkImageProvider(UrlResolver.resolveImage(context, user.avatar!, logicalWidth: 44))
              : null,
          child: user.avatar == null
              ? Text(user.nickname.isNotEmpty ? user.nickname[0].toUpperCase() : "?",
              style: TextStyle(fontSize: 16.sp, color: context.utilityBrand500, fontWeight: FontWeight.bold))
              : null,
        ),
        title: Text(
          user.nickname,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: context.textPrimary900),
        ),
        trailing: Icon(Icons.chevron_right_rounded, size: 18.sp, color: context.textSecondary700.withOpacity(0.2)),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      padding: EdgeInsets.all(16.r),
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Row(
          children: [
            Skeleton.react(width: 44.r, height: 44.r, borderRadius: BorderRadius.circular(22.r)),
            SizedBox(width: 16.w),
            Skeleton.react(width: 140.w, height: 16.h),
          ],
        ),
      ),
    );
  }

  //  新增：空状态兜底
  Widget _buildEmptyState(BuildContext context, int requestCount) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
          child: _buildActionSection(context, requestCount),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.contacts_rounded, size: 48.sp, color: context.textSecondary700.withOpacity(0.1)),
                SizedBox(height: 16.h),
                Text("No contacts found", style: TextStyle(color: context.textSecondary700)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}