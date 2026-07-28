import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../theme/accent_controller.dart';
import '../../theme/background_theme_controller.dart';
import 'product_list_screen.dart';
import '../staff/staff_product_list_screen.dart';
import 'staff_management_screen.dart';
import '../shared/customer_list_screen.dart';
import 'backup_restore_screen.dart';
import '../shared/expense_list_screen.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/staff_sidebar.dart';
import '../../widgets/admin_sidebar.dart';

//-------------------- DESKTOP BREAKPOINT --------------------
const double _kDesktopBreakpoint = 900;

//-------------------- THEME SETTINGS SCREEN --------------------
class ThemeSettingsScreen extends StatelessWidget {
  final bool isAdmin;
  const ThemeSettingsScreen({super.key, this.isAdmin = true});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: backgroundThemeController,
      builder: (context, bgPreset, __) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bg = bgPreset != null
            ? bgPreset['bg'] as Color
            : (isDark ? AppColors.darkBg : AppColors.lightBg);
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

        return _buildScaffold(
          context,
          bg,
          card,
          border,
          textPrimary,
          textSecondary,
          isDark,
          bgPreset,
        );
      },
    );
  }

  //==================== SCAFFOLD (wraps accent listener) ====================
  Widget _buildScaffold(
    BuildContext context,
    Color bg,
    Color card,
    Color border,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
    Map<String, dynamic>? bgPreset,
  ) {
    return ValueListenableBuilder<Color>(
      valueListenable: accentController,
      builder: (context, accent, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= _kDesktopBreakpoint;

            final content = _buildContent(
              context,
              accent,
              card,
              border,
              textPrimary,
              textSecondary,
              isDark,
              isDesktop,
              bgPreset,
            );

            if (isDesktop) {
              return Scaffold(
                backgroundColor: bg,
                body: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isAdmin)
                      StaffSidebar(
                        currentRoute: 'Appearance',
                        user: UserModel(
                          uid: AuthService().currentUser?.uid ?? '',
                          name: AuthService().currentUser?.displayName ?? 'Staff',
                          email: AuthService().currentUser?.email ?? '',
                          role: 'staff',
                          phone: '',
                          createdAt: DateTime.now(),
                        ),
                      )
                    else
                      const AdminSidebar(
                        currentRoute: 'Appearance',
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 28,
                          right: 28,
                          top: 24,
                          bottom: 20,
                        ),
                        child: content,
                      ),
                    ),
                  ],
                ),
              );
            }

            //-------------------- MOBILE --------------------
            return Scaffold(
              backgroundColor: bg,
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: content,
                ),
              ),
            );
          },
        );
      },
    );
  }

  //==================== SHARED CONTENT ====================
  Widget _buildContent(
    BuildContext context,
    Color accent,
    Color card,
    Color border,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
    bool isDesktop,
    Map<String, dynamic>? bgPreset,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //-------------------- HEADER --------------------
          Row(
            children: [
              if (!isDesktop || !isAdmin)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(color: border, width: 0.8),
                    ),
                    child: Icon(Icons.arrow_back, size: 18, color: textPrimary),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: isDesktop ? 26 : 19,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          //-------------------- DARK THEME MODE (toggle row) --------------------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: border, width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    size: 20,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dark Theme Mode',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Reduces eye strain in low-light environments.',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isDark,
                  activeColor: accent,
                  onChanged: (value) {
                    themeController.value = value
                        ? ThemeMode.dark
                        : ThemeMode.light;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          //-------------------- ACCENT COLOR SECTION --------------------
          Text(
            'Accent Color',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppAccentPresets.presets.map((preset) {
              final presetColor = preset['color'] as Color;
              final name = preset['name'] as String;
              final isSelected = presetColor.value == accent.value;

              return GestureDetector(
                onTap: () => accentController.value = presetColor,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? presetColor : border,
                      width: isSelected ? 1.6 : 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: presetColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected ? textPrimary : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          //-------------------- BACKGROUND THEMES SECTION --------------------
          Text(
            'Background Themes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppBackgroundPresets.presets.map((preset) {
              final presetBg = preset['bg'] as Color;
              final name = preset['name'] as String;
              final isSelected = bgPreset != null && bgPreset['name'] == name;

              return GestureDetector(
                onTap: () {
                  backgroundThemeController.value = preset;
                  final isDarkStyle = preset['isDarkStyle'] as bool;
                  themeController.value = isDarkStyle
                      ? ThemeMode.dark
                      : ThemeMode.light;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? accent : border,
                      width: isSelected ? 1.6 : 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: presetBg,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (preset['isDarkStyle'] as bool)
                                ? Colors.white24
                                : Colors.black12,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected ? textPrimary : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

//-------------------- DESKTOP SIDEBAR --------------------
class _DesktopSidebar extends StatelessWidget {
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final bool isDark;
  final bool isAdmin;
  final String selectedLabel;

  const _DesktopSidebar({
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.isDark,
    required this.isAdmin,
    required this.selectedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      color: card,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //-------------------- LOGO --------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, Color.lerp(accent, Colors.black, 0.2)!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AL-HASEEB',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          //-------------------- NAV ITEMS --------------------
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            selected: selectedLabel == 'Dashboard',
            accent: accent,
            onTap: () => Navigator.pop(context),
            textSecondary: textSecondary,
          ),
          _SidebarItem(
            icon: Icons.inventory_2_outlined,
            label: 'Products',
            selected: selectedLabel == 'Products',
            accent: accent,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => isAdmin
                    ? const ProductListScreen()
                    : const StaffProductListScreen(),
              ),
            ),
            textSecondary: textSecondary,
          ),
          _SidebarItem(
            icon: Icons.people_outline,
            label: 'Customers',
            selected: selectedLabel == 'Customers',
            accent: accent,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerListScreen(isAdmin: isAdmin),
              ),
            ),
            textSecondary: textSecondary,
          ),
          if (!isAdmin)
            _SidebarItem(
              icon: Icons.receipt_long_outlined,
              label: 'Expenses',
              selected: selectedLabel == 'Expenses',
              accent: accent,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ExpenseListScreen()),
              ),
              textSecondary: textSecondary,
            ),
          if (isAdmin)
            _SidebarItem(
              icon: Icons.badge_outlined,
              label: 'Staff',
              selected: selectedLabel == 'Staff',
              accent: accent,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaffManagementScreen(),
                ),
              ),
              textSecondary: textSecondary,
            ),

          if (isAdmin)
            _SidebarItem(
              icon: Icons.backup_outlined,
              label: 'Backup & Restore',
              selected: selectedLabel == 'Backup & Restore',
              accent: accent,
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
              ),
              textSecondary: textSecondary,
            ),
          _SidebarItem(
            icon: Icons.palette_outlined,
            label: 'Appearance',
            selected: selectedLabel == 'Appearance',
            accent: accent,
            onTap: () {},
            textSecondary: textSecondary,
          ),

          const Spacer(),

          _SidebarItem(
            icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            label: isDark ? 'Light mode' : 'Dark mode',
            selected: false,
            accent: accent,
            onTap: () => themeController.value = isDark
                ? ThemeMode.light
                : ThemeMode.dark,
            textSecondary: textSecondary,
          ),
        ],
      ),
    );
  }
}

//-------------------- SIDEBAR NAV ITEM --------------------
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final Color textSecondary;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.12) : null,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: selected
              ? Border.all(color: accent.withOpacity(0.2), width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            if (selected) const Spacer(),
            if (selected)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
