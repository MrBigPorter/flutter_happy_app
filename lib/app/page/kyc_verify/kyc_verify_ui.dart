part of 'kyc_verify_page.dart';

// 提取出的底部按钮栏
class _BottomNavBar extends ConsumerWidget {
  final VoidCallback? onStartPressed;
  const _BottomNavBar({this.onStartPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kycTypeAsyncValue = ref.watch(kycIdTypeProvider);
    final kycStatus = ref.watch(userProvider.select((s) => s?.kycStatus));

    final statusEnum = KycStatusEnum.fromStatus(kycStatus ?? 0);
    final bool isLocked =
        statusEnum == KycStatusEnum.reviewing ||
            statusEnum == KycStatusEnum.approved;

    String buttonText = 'start-now'.tr();
    if (statusEnum == KycStatusEnum.reviewing) {
      buttonText = 'kyc.status.pending.btn'.tr();
    }
    if (statusEnum == KycStatusEnum.approved) {
      buttonText = 'kyc.status.approved.btn'.tr();
    }

    return Container(
      color: context.bgPrimary,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48.h,
          child: Button(
            loading: kycTypeAsyncValue.isLoading,
            disabled: isLocked,
            onPressed: isLocked ? null : onStartPressed,
            child: Text(
              buttonText,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepList extends StatelessWidget {
  const _StepList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30.h),
        _StepItem(
          title: '${'common.step'.tr()} 1',
          subTitle: 'Scan your ID',
          description:
          'Use the camera to scan your ID. Make sure it is clear and not blurry.',
          detail: _buildStep1Detail(context),
          completed: false,
          img: 'assets/images/verify/step1.png',
        ),
        SizedBox(height: 20.h),
        _StepItem(
          title: '${'common.step'.tr()} 2',
          subTitle: 'Confirm your information',
          description:
          'We will extract your name and ID number automatically. Please check carefully before submitting.',
          completed: false,
          img: 'assets/images/verify/step2.png',
        ),
        SizedBox(height: 20.h),
        _StepItem(
          title: '${'common.step'.tr()} 3',
          subTitle: 'Take a selfie (Liveness)',
          description:
          'We will do a quick selfie check to confirm you are the real owner of the ID.',
          completed: false,
          img: 'assets/images/verify/step3.png',
        ),
      ],
    );
  }

  Widget _buildStep1Detail(BuildContext context) {
    final tips = [
      'Use the original physical ID (no screenshots)',
      'Avoid glare / reflection',
      'Keep the whole ID inside the frame',
      'Ensure text is readable',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 14.h),
        Text(
          'Tips',
          style: TextStyle(
            fontSize: 14.sp,
            color: context.textPrimary900,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 10.h),
        ...tips.map(
              (t) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Icon(
                    Icons.circle,
                    color: context.textBrandPrimary900,
                    size: 6.w,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    t,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: context.textSecondary700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepItem extends StatelessWidget {
  final String title;
  final String description;
  final String? subTitle;
  final bool completed;
  final String img;
  final Widget? detail;

  const _StepItem({
    required this.title,
    required this.description,
    this.completed = false,
    this.subTitle,
    required this.img,
    this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              completed
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: context.textBrandPrimary900,
              size: 20.w,
            ),
            SizedBox(width: 8.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                color: context.textBrandPrimary900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(
          subTitle ?? '',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: context.textPrimary900,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: detail ??
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: context.textSecondary700,
                      height: 1.35,
                    ),
                  ),
            ),
            SizedBox(width: 8.w),
            Image.asset(img, width: 112.w, height: 70.h, fit: BoxFit.contain),
          ],
        ),
      ],
    );
  }
}