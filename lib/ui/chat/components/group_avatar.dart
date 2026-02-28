import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/common.dart';
import 'package:flutter_app/utils/media/url_resolver.dart';
import 'package:path/path.dart';

class GroupAvatar extends StatelessWidget {
  /// Full URL after backend synthesis
  final String? avatarUrl;

  /// Avatar dimensions
  final double size;

  const GroupAvatar({
    super.key,
    this.avatarUrl,
    this.size = 50, // Default size
  });

  @override
  Widget build(BuildContext context) {
    // 1. Prepare a lightweight default placeholder component
    // Instead of calling the complex DefaultGroupAvatar, a simple background with an icon is used
    final placeholder = Container(
      width: size,
      height: size,
      color: context.bgSecondary, // Using secondary background color from context
      child: Icon(
        Icons.groups_rounded,
        size: size * 0.5,
        color: context.textSecondary700.withOpacity(0.5),
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        // Maintain consistent corner radius style (15% ratio)
        borderRadius: BorderRadius.circular(size * 0.15),
        child: _buildAvatarImage(context, placeholder),
      ),
    );
  }

  Widget _buildAvatarImage(BuildContext context, Widget placeholder) {
    // If URL is null or empty, display the placeholder directly
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return placeholder;
    }

    // Utilize CachedNetworkImage for optimized loading and caching
    return CachedNetworkImage(
      imageUrl: UrlResolver.resolveImage(context, avatarUrl, logicalWidth: 48),
      fit: BoxFit.cover,
      // Uniform placeholder for loading, failure, or empty states
      placeholder: (context, url) => placeholder,
      errorWidget: (context, url, error) => placeholder,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }
}