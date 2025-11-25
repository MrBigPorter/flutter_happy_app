import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/components/skeleton.dart';
import 'package:flutter_app/core/models/groups.dart';
import 'package:flutter_app/ui/button/index.dart';
import 'package:flutter_app/utils/date_helper.dart';
import 'package:flutter_app/utils/helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GroupUserItem extends StatefulWidget {
  final GroupMemberItem item;

  const GroupUserItem({super.key, required this.item});


  @override
  GroupUserItemState createState() => GroupUserItemState();
}

class GroupUserItemState extends State<GroupUserItem> {
  final bool showInviterNickname;

  GroupUserItemState({this.showInviterNickname = false});

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(avatarUrl: item.user?.avatar,isOwner: item.isOwner,),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                 const SizedBox(height: 8,),
                 _Header(nickname: item.user?.nickname ?? 'Guest', rightText: DateFormatHelper.formatMonthDayTime(DateTime.now()),),
                  SizedBox(height: 8),
                  _TicketGrid(shareAmount: item.shareAmount, shareCoin: item.shareCoin),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final int isOwner;

  const _Avatar({required this.avatarUrl, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final isWinner = true;
    return SizedBox(
      width: 50.w,
      height: 50.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CachedNetworkImage(
              imageUrl: avatarUrl ?? '',
              width: 40.w,
              height: 40.w,
              memCacheWidth: (40.w * ViewUtils.dpr).toInt(),
              memCacheHeight: (40.w * ViewUtils.dpr).toInt(),
              fit: BoxFit.cover,
              placeholder: (context, url) => Skeleton.circle(width: 40.w, height: 40.w),
              errorWidget: (context, url, error) => CircleAvatar(
                radius: 40.w,
                backgroundColor: context.bgBrandSecondary,
                child: Icon(Icons.person, size: 25.w, color: context.fgPrimary900),
              )
          ),
          if(isOwner == 1)
            Positioned.fill(
              child: Image.asset(
                'assets/images/leader.png',
                fit: BoxFit.contain,
              ),
            ),
          if(isWinner && isOwner != 1)
            Positioned.fill(
              child: Image.asset(
                'assets/images/win.png',
                fit: BoxFit.contain,
              ),
            )
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String nickname;
  final String rightText;

  const _Header({required this.nickname,required this.rightText});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize:context.textSm,
                    fontWeight: FontWeight.w800,
                    height: context.leadingSm,
                    color: context.textPrimary900
                ),
              ),
              Container(
                width: 39.w,
                height: 18.w,
                alignment: Alignment.center,
                margin: EdgeInsets.only(left: 6.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF7A00),
                      Color(0xFFFFD439),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                ),
                child: Text(
                  'Lucky',
                  style: TextStyle(
                    fontSize: context.text2xs,
                    color: context.textPrimaryOnBrand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            ],
          ),
        ),
        SizedBox(width: 10,),
        Text(
          rightText,
          style: TextStyle(
            fontSize:context.textSm,
            color: context.textSecondary700,
            fontWeight: FontWeight.w600,
            height: context.leadingXs
          ),
        )

      ],
    );
  }
}

class _TicketGrid extends StatefulWidget {
  final String shareAmount;
  final String shareCoin;

  const _TicketGrid({required this.shareAmount, required this.shareCoin});

  @override
  State<_TicketGrid> createState() => _TicketGridState();
}

class _TicketGridState extends State<_TicketGrid> {

  bool _open = false;


  @override
  Widget build(BuildContext context) {
    final itemsToShow = _open ? 10 : 4;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8.w,
            crossAxisSpacing: 8.w,
            childAspectRatio: 143.w / 30.w,
          ),
          itemBuilder: (context, index) {
            return Button(
              variant: ButtonVariant.outline,
              onPressed: () {},
              noPressAnimation: true,
              child: Text(
                '${widget.shareAmount} ${widget.shareCoin}',
              ),
            );
          },
          itemCount: itemsToShow,
        ),
        AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: GestureDetector(
              onTap: (){
                setState(() {
                  _open = !_open;
                });
              },
              child: Center(
                child: AnimatedRotation(
                  turns: _open ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 24.w,
                    color: context.fgPrimary900,
                  ),
                ),
              ),
            ),
        )
      ],
    );
  }
}
