import 'package:flutter/material.dart';

/// A reusable image widget that loads images from assets
class AppImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Color? color;

  const AppImage(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.fit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit ?? BoxFit.contain,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(
          width: width,
          height: height,
          child: const Icon(Icons.image_not_supported),
        );
      },
    );
  }
}
