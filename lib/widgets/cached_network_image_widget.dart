import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/image_cache_manager.dart';

/// A reusable cached network image widget with customizable properties
///
/// This widget provides:
/// - Automatic image caching (30 days)
/// - Customizable placeholder and error widgets
/// - Border radius support
/// - Size constraints (width/height)
/// - Fade animations
/// - HTTP headers support
///
/// Usage examples:
/// ```dart
/// // Basic usage
/// CachedNetworkImageWidget(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 100,
///   height: 100,
/// )
///
/// // With border radius
/// CachedNetworkImageWidget(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 100,
///   height: 100,
///   borderRadius: 12,
/// )
///
/// // With custom placeholder
/// CachedNetworkImageWidget(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 100,
///   height: 100,
///   placeholder: Container(
///     color: Colors.grey,
///     child: Icon(Icons.image),
///   ),
/// )
///
/// // With custom error widget
/// CachedNetworkImageWidget(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 100,
///   height: 100,
///   errorWidget: Container(
///     color: Colors.red,
///     child: Icon(Icons.error),
///   ),
/// )
///
/// // Full customization
/// CachedNetworkImageWidget(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 200,
///   height: 200,
///   borderRadius: 16,
///   fit: BoxFit.cover,
///   placeholder: CircularProgressIndicator(),
///   errorWidget: Icon(Icons.broken_image),
///   httpHeaders: {'Authorization': 'Bearer token'},
///   fadeInDuration: Duration(milliseconds: 500),
/// )
/// ```
class CachedNetworkImageWidget extends StatelessWidget {
  /// The URL of the image to load
  final String imageUrl;

  /// Width of the image
  final double? width;

  /// Height of the image
  final double? height;

  /// Border radius for the image (applied to all corners)
  final double? borderRadius;

  /// How the image should be inscribed into the box
  final BoxFit fit;

  /// Custom placeholder widget shown while loading
  final Widget? placeholder;

  /// Custom error widget shown when image fails to load
  final Widget? errorWidget;

  /// HTTP headers to include in the request
  final Map<String, String>? httpHeaders;

  /// Duration of the fade-in animation
  final Duration fadeInDuration;

  /// Duration of the fade-out animation
  final Duration fadeOutDuration;

  /// Whether to use the custom cache manager
  final bool useCustomCache;

  /// Color filter to apply to the image
  final ColorFilter? colorFilter;

  /// Alignment of the image within its bounds
  final Alignment alignment;

  /// Whether to show a progress indicator while loading
  final bool showProgressIndicator;

  /// Color of the progress indicator
  final Color? progressIndicatorColor;

  /// Background color of the image container
  final Color? backgroundColor;

  const CachedNetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.httpHeaders,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.fadeOutDuration = const Duration(milliseconds: 100),
    this.useCustomCache = true,
    this.colorFilter,
    this.alignment = Alignment.center,
    this.showProgressIndicator = false,
    this.progressIndicatorColor,
    this.backgroundColor,
  });

  /// Default placeholder widget
  Widget _defaultPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? CupertinoColors.systemGrey5,
      alignment: alignment,
      child: showProgressIndicator
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressIndicatorColor ??
                      Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          : Icon(
              CupertinoIcons.photo,
              size: (width != null && height != null)
                  ? (width! < height! ? width! * 0.4 : height! * 0.4)
                  : 24,
              color: CupertinoColors.systemGrey,
            ),
    );
  }

  /// Default error widget
  Widget _defaultErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? CupertinoColors.systemGrey5,
      alignment: alignment,
      child: Icon(
        CupertinoIcons.exclamationmark_triangle,
        size: (width != null && height != null)
            ? (width! < height! ? width! * 0.4 : height! * 0.4)
            : 24,
        color: CupertinoColors.systemRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return ClipRRect(
        borderRadius: borderRadius != null
            ? BorderRadius.circular(borderRadius!)
            : BorderRadius.zero,
        child: placeholder ?? _defaultPlaceholder(context),
      );
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      httpHeaders: httpHeaders ?? const {'Accept': 'image/*'},
      cacheManager: useCustomCache ? AppImageCacheManager.instance : null,
      placeholder: (context, url) =>
          placeholder ?? _defaultPlaceholder(context),
      errorWidget: (context, url, error) {
        debugPrint('Error loading image: $error');
        debugPrint('Image URL: $url');
        return errorWidget ?? _defaultErrorWidget(context);
      },
      fadeInDuration: fadeInDuration,
      fadeOutDuration: fadeOutDuration,
    );

    // Apply color filter if provided
    if (colorFilter != null) {
      imageWidget = ColorFiltered(
        colorFilter: colorFilter!,
        child: imageWidget,
      );
    }

    // Apply border radius if provided
    if (borderRadius != null && borderRadius! > 0) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius!),
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

