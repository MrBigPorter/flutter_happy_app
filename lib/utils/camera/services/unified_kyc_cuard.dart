import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb & kDebugMode
import 'package:flutter/widgets.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum KycDocType {
  idCard,
  passport,
  bankCard,
  document,
}

class UnifiedKycGuard with WidgetsBindingObserver {
  // 1. Singleton Pattern
  static final UnifiedKycGuard _instance = UnifiedKycGuard._internal();
  factory UnifiedKycGuard() => _instance;

  TextRecognizer? _textRecognizer;
  bool? _shouldSkipCheck;

  UnifiedKycGuard._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  // 2. Lifecycle Management
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

  // 3. Initialize Recognizer (Script: Chinese covers Latin + Numbers + Hanzi)
  TextRecognizer get _getTextRecognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.chinese);
    return _textRecognizer!;
  }

  // 4. Environment Check (Skip Simulator/Web)
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
    // A. Pre-flight check
    if (await _isSimulatorOrWeb()) return true;

    final inputImage = InputImage.fromFilePath(imagePath);

    try {
      // B. OCR Process
      final textResult = await _getTextRecognizer.processImage(inputImage);
      final fullText = textResult.text.toUpperCase(); // Normalize to UpperCase

      // C. Data Extraction & Statistics

      // 1. Clean Text (Remove whitespace)
      final cleanText = fullText.replaceAll(RegExp(r'\s+'), '');

      // 2. Digit Count (0-9)
      final digitCount = RegExp(r'[0-9]').allMatches(cleanText).length;

      // 3. Block/Word Analysis
      final allWords = fullText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final totalBlocks = allWords.length;

      // 4. Single Letter Count (Keyboard detection: Q W E R T...)
      final singleLetterCount = allWords.where((w) => w.length == 1 && RegExp(r'[A-Z]').hasMatch(w)).length;

      _log("Analysis -> Length: ${cleanText.length}, Digits: $digitCount, Blocks: $totalBlocks, SingleLetters: $singleLetterCount");

      // D. Validation Rules

      // Rule 1: Basic Garbage Filter (White paper / Black screen)
      if (cleanText.length < 10) {
        _log(" Rejected: Text too short (Likely blank or blurred).");
        return false;
      }

      // Rule 2: Keyboard Keyword Blacklist
      // Keyboards often contain: Shift, Ctrl, Alt, Enter...
      final keyboardKeywords = [
        'SHIFT', 'CTRL', 'ALT', 'ESC', 'TAB', 'CAPS', 'LOCK',
        'ENTER', 'BACKSPACE', 'DELETE', 'INSERT', 'HOME', 'PGUP', 'PGDN',
        'F1', 'F2', 'F12', 'NUM', 'PRTSC', 'QWERTY', 'CMD', 'OPTION'
      ];

      int keyboardHits = 0;
      for (var k in keyboardKeywords) {
        if (fullText.contains(k)) keyboardHits++;
      }

      if (keyboardHits >= 2) {
        _log(" Rejected: Keyboard function keys detected ($keyboardHits hits).");
        return false;
      }

      // Rule 3: Single Letter Density (Anti-Keyboard / Anti-EyeChart)
      // Keyboards have high density of isolated letters. Documents do not.
      if (totalBlocks > 10 && (singleLetterCount / totalBlocks > 0.35)) {
        final percentage = (singleLetterCount / totalBlocks * 100).toStringAsFixed(1);
        _log(" Rejected: High density of single letters ($percentage%). Suspected keyboard.");
        return false;
      }

      // Rule 4: Numeric Data Check (Documents MUST have numbers)
      final minDigits = (type == KycDocType.bankCard) ? 8 : 2;
      if (digitCount < minDigits) {
        _log(" Rejected: Insufficient numeric data (Found $digitCount, Need $minDigits).");
        return false;
      }

      //  Passed all checks
      _log(" Passed: Valid document structure detected.");
      return true;

    } catch (e) {
      _log(" ML Kit Error: $e");
      // Fail-open: If ML Kit crashes, allow the user to proceed to backend.
      return true;
    }
  }

  /// Internal Logger: Only prints in Debug Mode
  void _log(String message) {
    if (kDebugMode) {
      print("[KycGuard] $message");
    }
  }
}