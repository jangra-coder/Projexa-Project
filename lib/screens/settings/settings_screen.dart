import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, _) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Settings items
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    iconBgColor: AppColors.accentBlue,
                    label: 'Edit Profile',
                    onTap: () => _showComingSoon(context, 'Edit Profile'),
                    isDark: isDark,
                  ),
                  _SettingsTile(
                    icon: Icons.key_rounded,
                    iconBgColor: AppColors.warningAmber,
                    label: 'Change Password',
                    onTap: () => _showComingSoon(context, 'Change Password'),
                    isDark: isDark,
                  ),
                  _SettingsToggleTile(
                    icon: Icons.notifications_outlined,
                    iconBgColor: AppColors.accentTeal,
                    label: 'Push Notifications',
                    value: provider.pushNotifications,
                    onChanged: (_) => provider.togglePushNotifications(),
                    isDark: isDark,
                  ),
                  _SettingsToggleTile(
                    icon: Icons.dark_mode_outlined,
                    iconBgColor: const Color(0xFF6C63FF),
                    label: 'Dark Mode',
                    value: provider.isDarkMode,
                    onChanged: (_) => provider.toggleTheme(),
                    isDark: isDark,
                  ),

                  // Google Drive connection
                  _SettingsTile(
                    icon: provider.isDriveConnected
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded,
                    iconBgColor: provider.isDriveConnected
                        ? AppColors.activeGreen
                        : AppColors.expiredRed,
                    label: provider.isDriveConnected
                        ? 'Google Drive Connected'
                        : 'Connect Google Drive',
                    onTap: () async {
                      if (provider.isDriveConnected) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              '✅ Google Drive is connected. Your images are backed up automatically.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.activeGreen,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      } else {
                        final success = await provider.connectGoogleDrive();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? '✅ Google Drive connected successfully!'
                                    : provider.errorMessage ??
                                        'Failed to connect Google Drive',
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: success
                                  ? AppColors.activeGreen
                                  : AppColors.dangerRed,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                          if (!success) provider.clearError();
                        }
                      }
                    },
                    isDark: isDark,
                  ),

                  _SettingsTile(
                    icon: Icons.description_outlined,
                    iconBgColor: AppColors.activeGreen,
                    label: 'Privacy Policy',
                    onTap: () => _showComingSoon(context, 'Privacy Policy'),
                    isDark: isDark,
                  ),
                  _SettingsTile(
                    icon: Icons.star_outline_rounded,
                    iconBgColor: AppColors.warningAmber,
                    label: 'Rate the App',
                    onTap: () => _showComingSoon(context, 'Rate the App'),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // App info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.buttonGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Warranty Vault',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkText
                                  : AppColors.lightText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Version 1.0.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkSubtext
                                  : AppColors.lightSubtext,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Made with ❤️',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkSubtext
                                  : AppColors.lightSubtext,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _SettingsTile({
    required this.icon,
    required this.iconBgColor,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconBgColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const _SettingsToggleTile({
    required this.icon,
    required this.iconBgColor,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconBgColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppColors.accentTeal,
            ),
          ],
        ),
      ),
    );
  }
}
