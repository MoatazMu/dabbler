import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:go_router/go_router.dart';
import '../utils/constants/route_constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final IconData? actionIcon;
  final VoidCallback? onActionPressed;
  final bool showBackButton;
  
  const CustomAppBar({
    super.key,
    this.actionIcon,
    this.onActionPressed,
    this.showBackButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 44); // 56 + 44 = 100

  @override
  Widget build(BuildContext context) {
    // Get the status bar height dynamically
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return PreferredSize(
      preferredSize: Size.fromHeight(statusBarHeight + kToolbarHeight + 12),
      child: Container(
        color: const Color.fromARGB(0, 255, 255, 255),
        padding: EdgeInsets.fromLTRB(24, statusBarHeight + 12, 24, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Home Button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                // Navigate directly to home screen
                context.go(RoutePaths.home);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: const Color(0xFF301C4D),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.home_hashtag_copy,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Home',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Action Icon (if provided)
            if (actionIcon != null)
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onActionPressed?.call();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0xFF301C4D),
                  ),
                  child: Icon(
                    actionIcon,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
