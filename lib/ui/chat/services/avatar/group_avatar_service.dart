import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/utils/asset/asset_manager.dart';
import 'package:image/image.dart' as img;

import '../../../../core/api/http_client.dart';


class GroupAvatarService {

  static Future<Uint8List?> getOrGenerateGroupAvatar(List<String> memberUrls) async{
    if(memberUrls.isEmpty) return null;

    // generate a unique key based on memberUrls
    // get 9 avatar images
    final validUrls = memberUrls.where((url) => url.isNotEmpty).take(9).toList();
    final key = AssetManager.generateAvatarKey(validUrls);

    // check if avatar already exists,native only
    if(!kIsWeb){
      final File? cachedFile = await AssetManager.getCachedAvatar(key);
      if(cachedFile != null){
        return await cachedFile.readAsBytes();
      }
    }

    // generate new avatar, fetch images
    // it should be working isolate in future
    try{
      // fetch images
      final List<Uint8List> imagesData = await _fetchAllImages(validUrls);
      if(imagesData.isEmpty) return null;

      // put images into isolate to generate avatar
      //compute will auto work in isolate
      final Uint8List? composedBytes = await compute(_composeImages, imagesData);
      if(composedBytes != null && !kIsWeb){
        // cache the generated avatar
        await AssetManager.saveAvatar(key, composedBytes);
      }
      return composedBytes;
    }catch(e){
      debugPrint("Group Avatar Generation Error: $e");
      return null;
    }

  }

  // fetch all images from urls
  static Future<List<Uint8List>> _fetchAllImages(List<String> urls) async{
    final List<Future<Uint8List?>> tasks = urls.map((url) async{
      try{
        // Use rawDio to avoid global interceptors
        final resp = await Http.rawDio.get(
          url,
          options: Options(responseType: ResponseType.bytes),
        );
        return Uint8List.fromList(resp.data);
      }catch(e){
        debugPrint("Fetch Avatar Image Error: $e");
        return null;
      }
    }).toList();

    final results = await Future.wait(tasks);
    // filter out download failed images
    return results.whereType<Uint8List>().toList();
  }

  // compose images into one avatar
  static Uint8List? _composeImages(List<Uint8List> imagesData){
    if(imagesData.isEmpty) return null;

    //define canvas size
    const int size = 200;
    const int gap = 4;
    final canvas = img.Image(width:size, height:size);

    //fill  background
    img.fill(canvas, color: img.ColorRgb8(240,240,240));

    int count = imagesData.length;
    //limit to 9 images
    if(count > 9) count = 9;

    // calculate grid
    int columns = 1;
    if(count >= 2 && count <= 4) columns = 2;
    if(count >=5) columns =3;

    // cell size
    final int cellSize = (size - (columns + 1) * gap) ~/ columns;

    for (int i = 0; i < count; i++) {
      // decode image
      final smallImage = img.decodeImage(imagesData[i]);
      if(smallImage == null) continue;

      // resize image to fit cell
      final resized = img.copyResize(
        smallImage,
        width: cellSize,
        height: cellSize,
        interpolation:  img.Interpolation.average
      );

      // calculate position
      final row = i ~/ columns;
      final col = i % columns;

      int x = gap + col * (cellSize + gap);
      int y = gap + row * (cellSize + gap);

      if(count == 3 && i == 0) {
        // special case for 3 images, center the first one
        x = (size - cellSize) ~/ 2; // center horizontally
      }

      // draw onto canvas
      img.compositeImage(canvas, resized, dstX: x, dstY: y);
    }
    // encode to png
    return Uint8List.fromList(img.encodePng(canvas));
  }
}