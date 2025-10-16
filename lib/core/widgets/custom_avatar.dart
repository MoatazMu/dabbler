import 'package:flutter/material.dart';

/// A simple customizable avatar widget placeholder.
class CustomAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;

  const CustomAvatar({
    super.key,
    this.imageUrl,
    this.radius = 24.0,
    this.fallbackIcon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: Colors.grey[200],
      );
    } else {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[200],
        child: Icon(fallbackIcon, size: radius),
      );
    }
  }
}
