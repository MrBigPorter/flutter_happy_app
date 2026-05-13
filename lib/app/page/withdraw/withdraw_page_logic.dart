part of 'withdraw_page.dart';

/// Mixin: Handles core business logic for the withdrawal page
mixin WithdrawPageLogic on ConsumerState<WithdrawPage> {
  PaymentChannelConfigItem? selectedChannel;

  late final WithdrawFormModelForm formGroup = WithdrawFormModelForm(
    WithdrawFormModelForm.formElements(const WithdrawFormModel()),
    null,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).fetchBalance();
      ref.read(userProvider.notifier).fetchProfile();

      final state = ref.read(clientPaymentChannelsWithdrawProvider);
      if(state.hasValue && !state.isLoading){
        ref.invalidate(clientPaymentChannelsWithdrawProvider);
      }
    });
  }

  /// Setup Riverpod page-level listeners
  void setupListeners(double withdrawable) {
    // Listen for channel loading completion
    ref.listen<AsyncValue<List<PaymentChannelConfigItem>>>(
      clientPaymentChannelsWithdrawProvider,
          (prev, next) {
        next.whenData((channels) {
          if (channels.isNotEmpty && selectedChannel == null) {
            setState(() {
              selectedChannel = channels.first;
              updateValidators(withdrawable);
            });
          }
        });
      },
    );

    // Listen for balance changes to re-validate
    ref.listen(walletProvider.select((s) => s.realBalance), (prev, next) {
      if (prev != next) updateValidators(next);
    });
  }

  void updateValidators(double currentBalance) {
    if (selectedChannel == null) return;
    // Guard: skip if balance hasn't loaded yet to avoid setting
    // withdrawableBalance=0 which would reject all positive amounts
    if (currentBalance <= 0) return;
    final kycStatus = ref.read(userProvider)?.kycStatus ?? 0;
    final isVerified = KycStatusEnum.fromStatus(kycStatus) == KycStatusEnum.approved;
    final amountControl = formGroup.amountControl;

    amountControl.setValidators([
      Validators.required,
      WithdrawAmount(
        minAmount: selectedChannel!.minAmount,
        maxAmount: selectedChannel!.maxAmount,
        withdrawableBalance: currentBalance,
        feeRate: selectedChannel!.feeRate,
        fixedFee: selectedChannel!.feeFixed,
        isAccountVerified: isVerified,
      )
    ]);
    amountControl.updateValueAndValidity();
  }

  void handleWithdraw() {
    FocusScope.of(context).unfocus();
    formGroup.form.markAllAsTouched();

    if (formGroup.form.invalid || selectedChannel == null) return;

    final amount = formGroup.amountControl.value;
    RadixModal.show(
      title: 'withdraw.dialog_confirm_title'.tr(),
      builder: (context, close) => Text(
        'withdraw.dialog_confirm_content'.tr(
          namedArgs: {'amount': amount.toString(), 'channel': selectedChannel?.name ?? ''},
        ),
      ),
      confirmText: 'common.confirm'.tr(),
      cancelText: 'common.cancel'.tr(),
      onConfirm: (finish) {
        finish();
        processWithdraw();
      },
    );
  }

  Future<void> processWithdraw() async {
    final amountVal = formGroup.amountControl.value;
    final amount = double.tryParse(amountVal ?? '0') ?? 0.0;
    final feeRate = selectedChannel?.feeRate ?? 0.0;
    final fixedFee = selectedChannel?.feeFixed ?? 0.0;
    final fee = (amount * feeRate) + fixedFee;
    final actual = amount - fee;

    final result = await ref.read(createWithdrawProvider.notifier).create(
      WalletWithdrawApplyDto(
        amount: amount,
        channelId: selectedChannel!.id,
        account: formGroup.accountNumberControl.value ?? '',
        accountName: formGroup.accountNameControl.value ?? '',
        bankName: selectedChannel!.name,
      ),
    );

    if (result != null) {
      ref.read(transactionDirtyProvider(UiTransactionType.withdraw).notifier).state = true;
      ref.read(walletProvider.notifier).fetchBalance();
      final channelName = selectedChannel?.name ?? 'Wallet';
      final account = formGroup.accountNumberControl.value ?? '';
      formGroup.form.reset();

      if (mounted) {
        RadixSheet.show(
          builder: (context, close) => WithdrawSuccessModal(
            amount: amount, fee: fee, actual: actual,
            channelName: channelName, account: account, close: close,
          ),
        );
      }
    }
  }
}