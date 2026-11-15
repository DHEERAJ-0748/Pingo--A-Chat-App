import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Premium header for the Home (chat list) screen.
/// Shows a small version of the Pingo logo, the app title, and the
/// standard actions (notification, profile). All the existing callbacks
/// are preserved – the widget receives them as parameters.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.onLogout,
    this.onProfileTap,
  });

  final VoidCallback onLogout;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        // Slight elevation effect using a subtle shadow.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo + title
          Row(
            children: [
              // Placeholder for the logo – replace with actual asset later.
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF37B995), Color(0xFFB9F5DD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'Pingo',
                style: TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          // Action icons
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                color: iconColor,
                tooltip: 'Notifications',
                onPressed: () {}, // keep existing behavior if any
              ),
              IconButton(
                icon: const Icon(Icons.account_circle),
                color: iconColor,
                tooltip: 'Profile',
                onPressed: onProfileTap ?? () {},
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                color: iconColor,
                tooltip: 'Sign out',
                onPressed: onLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
