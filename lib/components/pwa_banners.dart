import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/utils/pwa_helper.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// PWA Install Banner — shows a "Add to Home Screen" prompt on Web.
/// Automatically hides when:
///  - Not on Web
///  - Already installed as PWA
///  - Install prompt is not available
///  - User dismisses it
class PwaInstallBanner extends StatefulWidget {
  const PwaInstallBanner({super.key});

  @override
  State<PwaInstallBanner> createState() => _PwaInstallBannerState();
}

class _PwaInstallBannerState extends State<PwaInstallBanner>
    with SingleTickerProviderStateMixin {
  bool _visible = false;
  late final AnimationController _ctrl;
  late final Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    // Delay check so Flutter is fully settled
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (!kIsWeb) return;
    if (PwaHelper.isInstalledPwa) return;
    if (!PwaHelper.canInstall) return;
    setState(() => _visible = true);
    _ctrl.forward();
  }

  Future<void> _onInstall() async {
    final shown = await PwaHelper.promptInstall();
    if (shown) _dismiss();
  }

  void _dismiss() {
    _ctrl.reverse().then((_) {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return SizeTransition(
      sizeFactor: _slide,
      axisAlignment: -1,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFFF5722).withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Image.asset(
              'assets/images/app_icon.png',
              width: 40.w,
              height: 40.w,
              errorBuilder: (_, __, ___) => Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.shopping_bag_outlined,
                    color: Colors.white, size: 22.sp),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Install JoyMini',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.sp,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Add to your home screen for a better experience',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            TextButton(
              onPressed: _onInstall,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Install',
                  style:
                      TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
            ),
            SizedBox(width: 4.w),
            GestureDetector(
              onTap: _dismiss,
              child: Icon(Icons.close, size: 18.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// PWA Update Banner — shows when a new SW version is waiting.
class PwaUpdateBanner extends StatefulWidget {
  const PwaUpdateBanner({super.key});

  @override
  State<PwaUpdateBanner> createState() => _PwaUpdateBannerState();
}

class _PwaUpdateBannerState extends State<PwaUpdateBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    // Dev mode (kDebugMode): never show update banner.
    // Flutter's web engine may auto-register flutter_service_worker.js in dev,
    // causing false "new version" detection on every hot-reload/rebuild.
    // Production builds (kReleaseMode) use the real SW and should show updates.
    if (kReleaseMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (kIsWeb && PwaHelper.updateAvailable) {
          setState(() => _visible = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Material(
      color: const Color(0xFF1A1A1A),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Row(
            children: [
              Icon(Icons.system_update_outlined,
                  color: Colors.white, size: 18.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'A new version is available',
                  style: TextStyle(color: Colors.white, fontSize: 13.sp),
                ),
              ),
              TextButton(
                onPressed: PwaHelper.applyUpdate,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5722),
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Reload',
                    style: TextStyle(
                        fontSize: 13.sp, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

