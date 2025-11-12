class ShareData {
  final String title;  // Title of the content to be shared
  final String url;    // URL of the content to be shared
  final String? text;  // Optional text description
  final String? imageUrl;  // Optional image URL

  ShareData({
    required this.title,
    required this.url,
    this.text,
    this.imageUrl,
  });

  // Combines text and url into a single string for sharing
  String get combined => [if(text?.isNotEmpty == true) text, url].whereType<String>().join();

}