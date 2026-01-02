import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/address_res.dart';
import 'package:flutter_app/core/providers/address_provider.dart';
import 'package:flutter_app/ui/form/fields/lf_wheel_select.dart';
import 'package:flutter_app/ui/index.dart';
import 'package:flutter_app/ui/modal/draggable/draggable_scrollable_scaffold.dart';
import 'package:flutter_app/utils/form/address_form.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../core/models/region_providers.dart';
import '../../utils/form/validation/address_validation_messages.dart';

class AddressManagerPage extends ConsumerStatefulWidget {
  final VoidCallback? onClose;
  final AddressRes? address;

  const AddressManagerPage({super.key, this.onClose, this.address});

  @override
  ConsumerState<AddressManagerPage> createState() => _AddressManagerPageState();
}

class _AddressManagerPageState extends ConsumerState<AddressManagerPage> {
  late final AddressFormModelForm addressForm = AddressFormModelForm(
    AddressFormModelForm.formElements(const AddressFormModel()),
    null,
  );

  // 新增标记位：防止回填数据时触发级联清空
  bool _isPatching = false;

  bool get isEditing => widget.address != null;

  StreamSubscription? _provinceSub;
  StreamSubscription? _citySub;

  @override
  void initState() {
    super.initState();

      if (isEditing) {
        _prefillForm(widget.address!);
      }
    _setupResetListeners();


  }

  void _prefillForm(AddressRes address) {
    _isPatching = true;
    try {
      addressForm.form.patchValue({
        'contactName': address.contactName,
        'fullAddress': address.fullAddress,
        'provinceId': address.provinceId,
        'cityId': address.cityId,
        'barangayId': address.barangayId,
        'postalCode': address.postalCode,
        'phone': address.phone,
        'isDefault': address.isDefault == 1,
      });
    } finally {
      _isPatching = false;
    }
  }

  void _setupResetListeners() {
    _provinceSub = addressForm.provinceIdControl.valueChanges.listen((_) {
      //修改监听逻辑：如果是 Patching 过程中，不要重置
      if (_isPatching) return;
      addressForm.cityIdControl.reset();
      addressForm.barangayIdControl.reset();
    });

    _citySub = addressForm.cityIdControl.valueChanges.listen((_) {
      //修改监听逻辑：如果是 Patching 过程中，不要重置
      if (_isPatching) return;
      addressForm.barangayIdControl.reset();
    });
  }

  void _showToast(String message) {
    RadixToast.error(message);
  }

  Future<void> submit() async {
    addressForm.form.markAllAsTouched();
    if (!addressForm.form.valid) {
      // 打印错误日志，方便调试哪个字段没填
      debugPrint('Address form is invalid:${addressForm.form.errors}');
      addressForm.form.controls.forEach((key, control) {
        if (control.invalid) {
          debugPrint('Invalid field: $key, errors: ${control.errors}');
        }
      });
      _showToast('Please check the highlighted fields.');
      return;
    }

    final val = addressForm.form.value;

    final req = AddressCreateDto(
      contactName: val['contactName'] as String,
      fullAddress: val['fullAddress'] as String,
      provinceId: val['provinceId'] as int,
      cityId: val['cityId'] as int,
      barangayId: val['barangayId'] as int,
      postalCode: val['postalCode'] as String?,
      phone: val['phone'] as String,
      isDefault: val['isDefault'] == true ? 1 : 0,
      label: null,
    );

    //  5. 调用 Manager
    final manager = ref.read(addressManagerProvider.notifier);
    bool success;

    if (isEditing) {
      // 编辑模式
      success = await manager.updateAddress(widget.address!.addressId, req);
    } else {
      // 新增模式
      success = await manager.addAddress(req);
    }

    if (!mounted) return;

    // 6. 处理结果
    if (success) {
      // 显示成功提示
      RadixToast.success('Address saved successfully.');
      // 关闭弹窗
      widget.onClose?.call();
    }
  }

  @override
  void dispose() {
    _provinceSub?.cancel();
    _citySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(provinceProvider);
    // 基础高度
    const k = kToolbarHeight;
    // 计算高度，考虑状态栏
    final height = MediaQuery.of(context).padding.top + k;

    // 7. 监听全局 Loading 状态
    final managerState = ref.watch(addressManagerProvider);
    final isLoading = managerState.isLoading;
    // 1. 获取键盘高度
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableScaffold(
      heroTag: 'add-address-manager',
      onDismiss: () {
        if (widget.onClose != null) {
          widget.onClose!();
        }
      },
      headerBuilder: (context, scrollController, physics) {
        return Container(
          height: height,
          color: context.bgPrimary,
          padding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: (height / 2) - 12.h,
          ),
          child: NavigationToolbar(
            leading: SizedBox(width: 24.w),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: () {
                widget.onClose?.call();
              },
              child: Icon(
                Icons.close,
                size: 24.w,
                color: context.textSecondary700,
              ),
            ),
            middle: Text(
              "Add New Address",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: context.textPrimary900,
              ),
            ),
          ),
        );
      },
      bodyBuilder: (context, scrollController, physics) {
        return SingleChildScrollView(
          controller: scrollController,
          physics: physics,
          padding: EdgeInsets.zero,
          child: Material(
            child: ReactiveFormConfig(
              validationMessages: kAddressValidationMessages,
              child: ReactiveForm(
                formGroup: addressForm.form,
                child: IgnorePointer(
                  ignoring: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height:height,),
                        LfInput(name: "contactName", label: "Contact Name", required: true,),
                        SizedBox(height: 16.h),
                        LfInput(name: "fullAddress", label: "full Address", required: true,),
                        SizedBox(height: 16.h),
                        LfWheelSelect(
                          required: true,
                          name: 'provinceId',
                          label: "Province",
                          isLoading:
                              provincesAsync.isLoading ||
                              provincesAsync.hasError,
                          options: provincesAsync.when(
                            data: (list) => list,
                            loading: () => [],
                            error: (_, __) => [],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        ReactiveValueListenableBuilder<int>(
                          formControlName: 'provinceId',
                          builder: (context, control, child) {
                            final provinceId = control.value ?? widget.address?.provinceId;
                            // 监听省份变化，加载对应的城市
                            final citiesAsync = ref.watch(
                              cityProvider(provinceId ?? -1),
                            );
                            return LfWheelSelect(
                              required: true,
                              name: 'cityId',
                              label: "City",
                              isLoading:
                                  citiesAsync.isLoading || citiesAsync.hasError,
                              options: citiesAsync.when(
                                data: (list) => list,
                                loading: () => [],
                                error: (_, __) => [],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 16.h),
                        ReactiveValueListenableBuilder<int>(
                          formControlName: 'cityId',
                          builder: (context, control, child) {
                            final cityId = control.value ?? widget.address?.cityId;
                            // 监听城市变化，加载对应的区/县
                            final districtsAsync = ref.watch(
                              barangaysProvider(cityId ?? -1),
                            );
                            return LfWheelSelect(
                              required: true,
                              name: 'barangayId',
                              label: "Barangay",
                              isLoading:
                                  districtsAsync.isLoading ||
                                  districtsAsync.hasError,
                              options: districtsAsync.when(
                                data: (list) => list,
                                loading: () => [],
                                error: (_, __) => [],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 16.h),
                        LfInput(name: "postalCode", label: "Postal Code"),
                        SizedBox(height: 16.h),
                        LfInput(name: "phone", label: "Phone", keyboardType: TextInputType.phone, required: true,),
                        LfCheckbox(
                          name: "isDefault",
                          label: "Set as Default Address",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      bottomBar: Container(
        color: context.bgSecondary,
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 16.h,
          bottom:
              16.h +
              (keyboardHeight > 0
                  ? keyboardHeight
                  : MediaQuery.of(context).padding.bottom),
        ),
        child: Button(
          width: double.infinity,
          height: 48.h,
          onPressed: isLoading ? null : submit,
          loading: isLoading,
          child: Text(
            isEditing ? "common.edit".tr() : "common.add".tr(),
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
