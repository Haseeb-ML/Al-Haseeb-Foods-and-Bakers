import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/accent_controller.dart';
import '../theme/background_theme_controller.dart';
import '../screens/auth/login_screen.dart';
import '../screens/staff/staff_dashboard.dart';
import '../screens/staff/staff_product_list_screen.dart';
import '../screens/staff/staff_profile_screen.dart';
import '../screens/shared/new_sale_screen.dart';
import '../screens/admin/today_sales_screen.dart';
import '../screens/admin/theme_settings_screen.dart';

class StaffSidebar extends StatelessWidget {
  final String currentRoute;
  final UserModel? user;
  final bool isAdminPreview;

  //-------------------- GLOBAL ADMIN PREVIEW STATE --------------------
  static bool adminPreviewMode = false;

  const StaffSidebar({
    super.key,
    required this.currentRoute,
    this.user,
    this.isAdminPreview = false,
  });

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _navigate(BuildContext context, Widget screen, String targetRoute) {
    if (currentRoute == targetRoute) return;
    if (targetRoute == 'Dashboard') {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => screen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 150),
          reverseTransitionDuration: const Duration(milliseconds: 100),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = user ??
        UserModel(
          uid: AuthService().currentUser?.uid ?? '',
          name: AuthService().currentUser?.displayName ?? 'Staff',
          email: AuthService().currentUser?.email ?? '',
          role: 'staff',
          phone: '',
          createdAt: DateTime.now(),
        );

    // Check both the constructor flag and the static global flag
    final isPreview = isAdminPreview || StaffSidebar.adminPreviewMode;

    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: backgroundThemeController,
      builder: (context, bgPreset, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final card = bgPreset != null
            ? bgPreset['card'] as Color
            : (isDark ? AppColors.darkCard : AppColors.lightCard);
        final border = bgPreset != null
            ? bgPreset['border'] as Color
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
        final textPrimary = isDark
            ? AppColors.darkTextPrimary
            : AppColors.lightTextPrimary;
        final textSecondary = isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;

        return Container(
          width: 250,
          color: card,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //-------------------- STORE HEADER BRANDING --------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/bakery_logo.png',
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AL-HASEEB',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Staff Workspace',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: accentController.value,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isPreview) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.deepPurple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 14, color: Colors.deepPurple.shade300),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Admin Preview',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.deepPurple.shade300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Divider(color: border, height: 1),
              const SizedBox(height: 14),

              //-------------------- NAVIGATION MENU ITEMS --------------------
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _SidebarMenuItem(
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      isSelected: currentRoute == 'Dashboard',
                      onTap: () => _navigate(context, StaffDashboard(user: currentUser), 'Dashboard'),
                      textSecondary: textSecondary,
                    ),


                    _SidebarMenuItem(
                      icon: Icons.person_outline_rounded,
                      activeIcon: Icons.person_rounded,
                      label: 'My Profile & Log',
                      isSelected: currentRoute == 'Profile',
                      onTap: () => _navigate(context, StaffProfileScreen(user: currentUser), 'Profile'),
                      textSecondary: textSecondary,
                    ),
                    _SidebarMenuItem(
                      icon: Icons.palette_outlined,
                      activeIcon: Icons.palette_rounded,
                      label: 'App Appearance',
                      isSelected: currentRoute == 'Appearance',
                      onTap: () => _navigate(context, const ThemeSettingsScreen(isAdmin: false), 'Appearance'),
                      textSecondary: textSecondary,
                    ),
                  ],
                ),
              ),

              Divider(color: border, height: 1),
              const SizedBox(height: 12),

              //-------------------- USER MINI PROFILE CARD --------------------
              if (isPreview) ...[
                // Back to Admin button instead of profile/logout
                GestureDetector(
                  onTap: () {
                    StaffSidebar.adminPreviewMode = false;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentController.value.withValues(alpha: 0.15),
                          accentController.value.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: accentController.value.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back_rounded,
                          size: 18,
                          color: accentController.value,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Back to Admin',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: accentController.value,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.admin_panel_settings,
                          size: 16,
                          color: accentController.value.withValues(alpha: 0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                InkWell(
                  onTap: () => _navigate(context, StaffProfileScreen(user: currentUser), 'Profile'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: accentController.value.withValues(alpha: 0.15),
                          backgroundImage: currentUser.profileImageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(currentUser.profileImageUrl)
                              : null,
                          child: currentUser.profileImageUrl.isEmpty
                              ? Icon(Icons.person, size: 18, color: accentController.value)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currentUser.name.isNotEmpty ? currentUser.name : 'Staff Member',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Staff Member',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: accentController.value,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Logout',
                          icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                          onPressed: () => _handleLogout(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SidebarMenuItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color textSecondary;
  final String? badgeText;

  const _SidebarMenuItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.textSecondary,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = accentController.value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 20,
                  color: isSelected ? activeColor : textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? activeColor : textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: activeColor,
                      ),
                    ),
                  ),
                if (isSelected && badgeText == null)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
