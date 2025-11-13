import 'package:share_plus/share_plus.dart';

class ShareData {
  final String title;  // Title of the content to be shared
  final String url;    // URL of the content to be shared
  final String? text;  // Optional text description
  final String? imageUrl;  // Optional image URL
  final XFile? previewThumbnail; // Optional preview image URL

  ShareData({
    required this.title,
    required this.url,
    this.text,
    this.imageUrl,
    this.previewThumbnail,
  });

  ShareData copyWith({
    String? title,
    String? url,
    String? text,
    String? imageUrl,
    XFile? previewThumbnail,
  }) {
    return ShareData(
      title: title ?? this.title,
      url: url ?? this.url,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      previewThumbnail: previewThumbnail ?? this.previewThumbnail,
    );
  }

  // Combines text and url into a single string for sharing
  String get combined => [if(text?.isNotEmpty == true) text, url].whereType<String>().join();

}