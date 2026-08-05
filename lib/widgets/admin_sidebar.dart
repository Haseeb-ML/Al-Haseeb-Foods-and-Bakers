import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/accent_controller.dart';
import '../theme/background_theme_controller.dart';
import '../screens/staff/staff_dashboard.dart';
import 'staff_sidebar.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/product_list_screen.dart';
import '../screens/admin/staff_management_screen.dart';
import '../screens/admin/backup_restore_screen.dart';
import '../screens/admin/today_sales_screen.dart';
import '../screens/admin/sales_history_screen.dart';
import '../screens/admin/theme_settings_screen.dart';
import '../screens/shared/new_sale_screen.dart';
import '../screens/shared/customer_list_screen.dart';
import '../screens/shared/expense_list_screen.dart';
import '../screens/admin/financial_reports_screen.dart';
import '../screens/admin/supplier_list_screen.dart';
import '../screens/admin/attendance_payroll_screen.dart';

class AdminSidebar extends StatelessWidget {
  final String currentRoute;
  final UserModel? user;

  const AdminSidebar({
    super.key,
    required this.currentRoute,
    this.user,
  });

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout Confirmation'),
        content: const Text('Are you sure you want to logout from Admin Panel?'),
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
    
    // Using a fast fade transition with 150ms instead of standard 350ms slide transition
    // to make screen switching feel instant and extremely snappy on Desktop.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 150),
        reverseTransitionDuration: const Duration(milliseconds: 100),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = user ??
        UserModel(
          uid: AuthService().currentUser?.uid ?? '',
          name: AuthService().currentUser?.displayName ?? 'Admin Owner',
          email: AuthService().currentUser?.email ?? '',
          role: 'admin',
          phone: '',
          createdAt: DateTime.now(),
        );

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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: accentController.value.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ADMIN PANEL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: accentController.value,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: border, height: 1),
              const SizedBox(height: 12),

              //-------------------- 10 COMPLETE ADMIN NAVIGATION OPTIONS --------------------
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 1. Dashboard
                      _buildNavItem(
                        context,
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        targetRoute: 'Dashboard',
                        screen: AdminDashboard(user: currentUser),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        border: border,
                      ),

                      // 2. Products Catalog
                      _buildNavItem(
                        context,
                        icon: Icons.inventory_2_outlined,
                        activeIcon: Icons.inventory_2_rounded,
                        label: 'Products Catalog',
                        targetRoute: 'Products',
                        screen: const ProductListScreen(),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        border: border,
                      ),

                      // 2b. Suppliers & Stock-In
                      _buildNavItem(
                        context,
                        icon: Icons.local_shipping_outlined,
                        activeIcon: Icons.local_shipping_rounded,
                        label: 'Suppliers & Stock In',
                        targetRoute: 'Suppliers',
                        badge: 'IN',
                        screen: SupplierListScreen(user: currentUser),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        border: border,
                      ),

                      // 3. New Sale (POS)
                      _buildNavItem(
                        context,
                        icon: Icons.point_of_sale_outlined,
                        activeIcon: Icons.point_of_sale_rounded,
                        label: 'New Sale (POS)',
                        targetRoute: 'New Sale',
                        badge: 'POS',
                        screen: NewSaleScreen(
                          currentUserUid: currentUser.uid,
                          isAdmin: true,
                        ),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        border: border,
                      ),

                      // 4. Today's Sales
                      _buildNavItem(
                        context,
                        icon: Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long_rounded,
                        label: "Today's Sales",
                        targetRoute: "Today's Sales",
                        screen: TodaySalesScreen(),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        border: border,
                      ),

                      // 4b. Sales History
                      _buildNavItem(
                        context,
                        icon: Icons.history_outlined,
                        activeIcon: Icons.history_rounded,
                        label: 'Sales History',
                        targetRoute: 'Sales History',
                        screen: const SalesHistoryScreen(),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        border: border,
                      ),

                      // 5. Customers & Dues
                      _buildNavItem(
                        context,
                        icon: Icons.people_alt_outlined,
                        activeIcon: Icons.people_alt_rounded,
                        label: 'Customers & Dues',
                        targetRoute: 'Customers',
                        screen: const CustomerListScreen(isAdmin: true),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        border: border,
                      ),

                      // 6. Store Expenses
                      _buildNavItem(
                        context,
                        icon: Icons.account_balance_wallet_outlined,
                        activeIcon: Icons.account_balance_wallet_rounded,
                        label: 'Store Expenses',
                        targetRoute: 'Expenses',
                        screen: ExpenseListScreen(user: currentUser),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        border: border,
                      ),

                      // 7. Profit & Loss Report
                      _buildNavItem(
                        context,
                        icon: Icons.insights_outlined,
                        activeIcon: Icons.insights_rounded,
                        label: 'Profit & Loss',
                        targetRoute: 'Profit & Loss',
                        badge: 'P&L',
                        screen: FinancialReportsScreen(user: currentUser),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        border: border,
                      ),

                      // 7. Staff Management
                      _buildNavItem(
                        context,
                        icon: Icons.badge_outlined,
                        activeIcon: Icons.badge_rounded,
                        label: 'Staff Management',
                        targetRoute: 'Staff',
                        screen: const StaffManagementScreen(),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        border: border,
                      ),

                      // 7b. Attendance & Payroll
                      _buildNavItem(
                        context,
                        icon: Icons.calendar_month_outlined,
                        activeIcon: Icons.calendar_month_rounded,
                        label: 'Attendance & Payroll',
                        targetRoute: 'Attendance & Payroll',
                        screen: const AttendancePayrollScreen(),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        border: border,
                      ),

                      // 8. Backup & Restore
                      _buildNavItem(
                        context,
                        icon: Icons.cloud_sync_outlined,
                        activeIcon: Icons.cloud_sync_rounded,
                        label: 'Backup & Restore',
                        targetRoute: 'Backup & Restore',
                        screen: const BackupRestoreScreen(),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        border: border,
                      ),

                      // 10. App Appearance
                      _buildNavItem(
                        context,
                        icon: Icons.palette_outlined,
                        activeIcon: Icons.palette_rounded,
                        label: 'App Appearance',
                        targetRoute: 'Appearance',
                        screen: const ThemeSettingsScreen(isAdmin: true),
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        border: border,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Divider(color: border, height: 1),
              const SizedBox(height: 12),



              //-------------------- BOTTOM ADMIN PROFILE CARD & LOGOUT --------------------
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: border, width: 0.8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: accentController.value.withValues(alpha: 0.2),
                      child: Text(
                        currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'A',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: accentController.value,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          Text(
                            'Administrator',
                            style: TextStyle(
                              fontSize: 10,
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String targetRoute,
    required Widget screen,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
    String? badge,
  }) {
    final isSelected = currentRoute == targetRoute;
    final accent = accentController.value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigate(context, screen, targetRoute),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? accent.withValues(alpha: 0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: accent.withValues(alpha: 0.3), width: 1)
                  : Border.all(color: Colors.transparent, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 19,
                  color: isSelected ? accent : textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? accent : textSecondary,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  )
                else if (isSelected)
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
        ),
      ),
    );
  }
}
