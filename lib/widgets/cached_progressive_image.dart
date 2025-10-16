import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CachedProgressiveImage extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const CachedProgressiveImage({super.key, required this.url, required this.width, required this.height, this.borderRadius, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, _) => Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      errorWidget: (context, _, __) => Container(
        width: width,
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image_outlined, size: 16),
      ),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}


