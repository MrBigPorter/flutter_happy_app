import 'dart:async';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

Future<XFile> compressWebCanvasImpl(XFile file, {double quality = 0.8, int maxWidth = 1920}) async => file;
Future<Uint8List?> captureWebVideoFrameImpl(String blobUrl) async => null;