import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum KycDocType { idCard, passport, bankCard, document }

class UnifiedKycGuard with WidgetsBindingObserver {
  static final UnifiedKycGuard _instance = UnifiedKycGuard._internal();
  factory UnifiedKycGuard() => _instance;

  TextRecognizer? _textRecognizer;
  bool? _shouldSkipCheck;

  UnifiedKycGuard._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (!kIsWeb) {
        _log("App background, releasing ML Kit resources...");
        _disposeResources();
      }
    }
  }

  void _disposeResources() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }

  TextRecognizer get _getTextRecognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.chinese);
    return _textRecognizer!;
  }

  Future<bool> _isSimulatorOrWeb() async {
    if (_shouldSkipCheck != null) return _shouldSkipCheck!;
    if (kIsWeb) { _shouldSkipCheck = true; return true; }

    final deviceInfo = DeviceInfoPlugin();
    bool isPhysical = true;
    try {
      if (Platform.isAndroid) {
        isPhysical = (await deviceInfo.androidInfo).isPhysicalDevice;
      } else if (Platform.isIOS) {
        isPhysical = (await deviceInfo.iosInfo).isPhysicalDevice;
      }
    } catch (e) { isPhysical = true; }

    if (!isPhysical) _log("Simulator detected. Skipping local checks.");
    _shouldSkipCheck = !isPhysical;
    return _shouldSkipCheck!;
  }

  // =========================================================
  //  Core Logic: Structure & Content Validation
  // =========================================================
  Future<bool> check(String imagePath, KycDocType type) async {
    // -------------------------------------------------------
    // 🌟 关键修改：双重保命检查
    // -------------------------------------------------------
    // 1. 检查是否是虚拟机/Web
    final isMockEnv = await _isSimulatorOrWeb();

    // 2. 检查路径是否包含 mock 关键字 (来自 LivenessService 的假返回)
    final isMockPath = imagePath.contains("mock");

    if (isMockEnv || isMockPath) {
      _log("🛡️ 检测到开发环境或模拟路径，自动跳过 OCR 校验。");
      return true; // 虚拟机直接返回通过，确保流程继续
    }

    // --- 下面是只有真机才会执行的硬核识别代码 ---

    // 确保文件真实存在，防止闪退
    if (!File(imagePath).existsSync()) {
      _log("❌ 错误：找不到图片文件 $imagePath");
      return false;
    }

    final inputImage = InputImage.fromFilePath(imagePath);

    try {
      final textResult = await _getTextRecognizer.processImage(inputImage);
      final fullText = textResult.text.toUpperCase();

      // 1. 清洗数据
      final cleanText = fullText.replaceAll(RegExp(r'\s+'), '');
      final digitCount = RegExp(r'[0-9]').allMatches(cleanText).length;
      final allWords = fullText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final totalBlocks = allWords.length;
      final singleLetterCount = allWords.where((w) => w.length == 1 && RegExp(r'[A-Z]').hasMatch(w)).length;

      _log("Analysis -> Length: ${cleanText.length}, Digits: $digitCount, Blocks: $totalBlocks, SingleLetters: $singleLetterCount");

      // --- 校验规则 ---

      // Rule 1: 文本太短 (可能是白纸或虚焦)
      if (cleanText.length < 10) {
        _log(" Rejected: Text too short.");
        return false;
      }

      // Rule 2: 键盘关键字黑名单
      final keyboardKeywords = ['SHIFT', 'CTRL', 'ALT', 'ESC', 'TAB', 'ENTER', 'BACKSPACE', 'QWERTY'];
      int keyboardHits = 0;
      for (var k in keyboardKeywords) {
        if (fullText.contains(k)) keyboardHits++;
      }
      if (keyboardHits >= 2) {
        _log(" Rejected: Keyboard detected.");
        return false;
      }

      // Rule 3: 单字母密度 (防止拍屏幕键盘)
      if (totalBlocks > 10 && (singleLetterCount / totalBlocks > 0.35)) {
        _log(" Rejected: High single letter density.");
        return false;
      }

      // Rule 4: 数字检查 (证件必须有数字)
      final minDigits = (type == KycDocType.bankCard) ? 8 : 2;
      if (digitCount < minDigits) {
        _log(" Rejected: Insufficient numeric data.");
        return false;
      }

      _log(" ✅ Passed: Valid document structure.");
      return true;

    } catch (e) {
      _log(" ⚠️ ML Kit Error: $e");
      return true; // 容错处理：算法崩溃时允许通过，交由后端审核
    }
  }

  void _log(String message) {
    if (kDebugMode) {
      print("[UnifiedKycGuard] $message");
    }
  }
}