import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/models/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// LuckyState - State class for LuckyStore
/// Holds user info, balance, and system config
/// Parameters:
/// - userInfo: UserInfo? - User information (nullable)
/// - balance: Balance - User's wallet balance
/// - sysConfig: SysConfig - System configuration
class LuckyState {
  final UserInfo? userInfo;
  final Balance balance;
  final SysConfig sysConfig;
  final String? token;

  const LuckyState({
    required this.balance,
    required this.sysConfig,
    this.token,
    this.userInfo,
  });

  /// Initial state factory
  /// Returns a LuckyState with default values
  /// - userInfo: null
  /// - balance: Balance with realBalance and coinBalance set to 0
  /// - sysConfig: SysConfig with kycAndPhoneVerification set to '1'
  factory LuckyState.initial()=> LuckyState(
     userInfo: null,
      balance: Balance(realBalance: 0, coinBalance: 0),
      sysConfig: SysConfig(kycAndPhoneVerification: '1'),
  );


  /// Copy with method for LuckyState
  /// Creates a new LuckyState with updated fields
  /// Parameters:
  /// - userInfo: UserInfo? - New user info (optional)
  /// - balance: Balance? - New balance (optional)
  /// - sysConfig: SysConfig? - New system config (optional)
  LuckyState copyWith({
    UserInfo? userInfo,
    Balance? balance,
    SysConfig? sysConfig,
  }) {
    return LuckyState(
      userInfo: userInfo ?? this.userInfo,
      balance: balance ?? this.balance,
      sysConfig: sysConfig ?? this.sysConfig,
    );
  }
}


/// LuckyNotifier - StateNotifier for LuckyState
/// Manages user info, balance, and system config state
/// Provides methods to update each part of the state
/// Parameters:
/// - ref: Ref - Riverpod reference for dependency injection
/// Methods:
/// - updateUserInfo(UserInfo userInfo): Future<'void'> - Updates user info from API
/// - updateWalletBalance(): Future<'void'> - Updates wallet balance from API
/// - updateSysConfig(): Future<'void'> - Updates system config from API
/// - refreshAll(): Future<'void'> - Refreshes all data from API
/// Provider:
/// - luckyProvider: StateNotifierProvider<'LuckyNotifier, LuckyState'> - Riverpod provider
/// Usage: luckyProvider
/// Example: final lucky = ref.watch(luckyProvider);
/// Updates: ref.read(luckyProvider.notifier).updateUserInfo(userInfo);
/// No parameters
class LuckyNotifier extends StateNotifier<LuckyState> {
  LuckyNotifier(this.ref) : super(LuckyState.initial());

  final Ref ref;

  /// Update user info method
  /// Fetches user info from API and updates state
  Future<void> updateUserInfo(UserInfo userInfo) async {
    final data = await Api.getUserInfo();
    state = state.copyWith(userInfo: data);
  }

  /// Update wallet balance method
  /// Fetches wallet balance from API and updates state
  Future<void> updateWalletBalance() async {
    final data = await Api.getWalletBalance();
    state = state.copyWith(balance: data);
  }

  /// Update system config method
  /// Fetches system config from API and updates state
  Future<void> updateSysConfig() async {
    final data = await Api.getSysConfig();
    state = state.copyWith(sysConfig: data);
  }

  /// Refresh all data method
  /// Fetches user info, wallet balance, and system config from API
  /// and updates state
  /// No parameters
  Future<void> refreshAll() async {
     final user = await Api.getUserInfo();
     final balance = await Api.getWalletBalance();
     final sysConfig = await Api.getSysConfig();
     state = LuckyState(
       userInfo: user,
       balance: balance,
       sysConfig: sysConfig,
     );
  }


}

/// Riverpod provider for LuckyNotifier
/// No parameters
/// Returns a StateNotifierProvider for LuckyNotifier
/// Usage: luckyProvider
/// Example: final lucky = ref.watch(luckyProvider);
/// Updates: ref.read(luckyProvider.notifier).updateUserInfo(userInfo);
final luckyProvider = StateNotifierProvider<LuckyNotifier,LuckyState>((ref)=> LuckyNotifier(ref));