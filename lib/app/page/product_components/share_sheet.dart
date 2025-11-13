import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/features/share/models/share_data.dart';
import 'package:flutter_app/ui/button/button.dart';
import 'package:flutter_app/ui/toast/radix_toast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter_app/ui/button/variant.dart';

import 'package:flutter_app/features/share/services/share_service.dart';
import 'package:screenshot/screenshot.dart';

class ShareSheet extends StatefulWidget {
  final String? origin;

  final String? sharePath;
  final String? inviteCode;
  final ShareData data;
  final bool showShareCode;
  final Widget? poster;

  final Future<void> Function()? onDownloadPoster;

  const ShareSheet({
    super.key,
    this.origin,
    this.sharePath,
    this.inviteCode,
    required this.data,
    this.showShareCode = false,
    this.poster,
    this.onDownloadPoster,
  });

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  bool showForm = false;

  Uri get _shareUri {
    if (widget.data.url.isNotEmpty) {
      final u = Uri.tryParse(widget.data.url);
      return _appendInviteCode(u!);
    }
    return Uri.parse(widget.origin ?? '');
  }

  // Append invite code to URL if available
  Uri _appendInviteCode(Uri uri) {
    if (widget.inviteCode == null || widget.inviteCode!.isEmpty) {
      return uri;
    }
    final qp = Map<String, String>.from(uri.queryParameters);
    qp['invite_code'] = widget.inviteCode!;
    return uri.replace(queryParameters: qp);
  }

  // ShareData with final URL
  ShareData get _shareDataWithFinalUrl {
    return widget.data.copyWith(url: _shareUri.toString());
  }

  // Copy to clipboard
  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    RadixToast.success('copy.success'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final urlString = _shareUri.toString();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // optional poster
        if (widget.poster != null) ...[widget.poster!, SizedBox(height: 16.w)],
        SizedBox(height: 16.w),
        // !showForm
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ShareIconButton(
              label: 'Facebook',
              icon: SvgPicture.asset(
                'assets/images/facebook.svg',
                width: 32.w,
                height: 32.w,
              ),
              onTap: () {
                ShareService.shareFacebook(_shareDataWithFinalUrl);
              },
            ),
            _ShareIconButton(
              label: 'Viber',
              icon: SvgPicture.asset(
                'assets/images/viber.svg',
                width: 32.w,
                height: 32.w,
              ),
              onTap: () {
                // TODO: implement Viber share or deep link
              },
            ),
            _ShareIconButton(
              label: 'WhatsApp',
              icon: SvgPicture.asset(
                'assets/images/whatsapp.svg',
                width: 32.w,
                height: 32.w,
              ),
              onTap: () {
                ShareService.shareWhatsApp(_shareDataWithFinalUrl);
              },
            ),
            _ShareIconButton(
              label: 'X',
              icon: SvgPicture.asset(
                'assets/images/twitter.svg',
                width: 32.w,
                height: 32.w,
              ),
              onTap: () {
                ShareService.shareTwitter(_shareDataWithFinalUrl);
              },
            ),
            _ShareIconButton(
              label: 'Download',
              icon: SvgPicture.asset(
                'assets/images/download.svg',
                width: 32.w,
                height: 32.w,
              ),
              onTap: ()=> widget.onDownloadPoster?.call(),
            ),
          ],
        ),
        SizedBox(height: 16.w),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Container(
            width: double.infinity,
            height: 40.w,
            padding: EdgeInsets.only(left: 16.w),
            decoration: BoxDecoration(
              border: Border.all(color: context.buttonSecondaryBorder),
              borderRadius: BorderRadius.all(Radius.circular(context.radiusMd)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    urlString,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: context.textXs,
                      color: context.textSecondary700,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: context.buttonSecondaryBorder,
                        width: 1.w,
                      ),
                    ),
                  ),
                  child: Button(
                    variant: ButtonVariant.text,
                    height: 40.w,
                    onPressed: () => _copyToClipboard(urlString),
                    leading: SvgPicture.asset(
                      'assets/images/copy.svg',
                      width: 16.w,
                      height: 16.w,
                    ),
                    child: Text('common.invite.link.copy'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.w),
      ],
    );
  }
}

class _ShareIconButton extends StatelessWidget {
  final String label;
  final SvgPicture icon;
  final VoidCallback onTap;

  const _ShareIconButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          icon,
          SizedBox(height: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: context.textXs,
              color: context.textSecondary700,
              fontWeight: FontWeight.w600,
              height: context.leadingXs,
            ),
          ),
        ],
      ),
    );
  }
}
