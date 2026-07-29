import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../services/alert_service.dart';
import '../../models/urgent_alert_model.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../services/customer_service.dart';
import '../../services/invoice_service.dart';
import '../../services/invoice_pdf_service.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../models/invoice_model.dart';
import '../auth/login_screen.dart';
import 'staff_management_screen.dart';
import 'today_sales_screen.dart';
import 'admin_profile_screen.dart';
import 'product_list_screen.dart';
import '../shared/customer_list_screen.dart';

import '../shared/new_sale_screen.dart';
import '../shared/customer_purchase_history_screen.dart';
import '../../widgets/admin_sidebar.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../theme/accent_controller.dart';
import '../../theme/background_theme_controller.dart';
import 'theme_settings_screen.dart';
import 'backup_restore_screen.dart';
import 'attendance_payroll_screen.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';

//-------------------- DESKTOP BREAKPOINT --------------------
const double kDesktopBreakpoint = 900;

//-------------------- ADMIN DASHBOARD --------------------
class AdminDashboard extends StatefulWidget {
  final UserModel user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ProductService _productService = ProductService();
  final CustomerService _customerService = CustomerService();
  final InvoiceService _invoiceService = InvoiceService();
  final AttendanceService _attendanceService = AttendanceService();
  String _revenueRange = '7D'; // '7D' | '1M' | '3M'

  //-------------------- PERCENT CHANGE HELPER --------------------
  // Returns null agar comparison meaningful nahi (previous data hi nahi).
  double? _percentChange(double current, double previous) {
    if (previous <= 0) return null;
    return ((current - previous) / previous) * 100;
  }

  //-------------------- REVENUE TREND DATA (7D / 1M / 3M) --------------------
  ({List<double> values, List<String> labels}) _revenueTrendData(
    List<InvoiceModel> invoices,
    String range,
  ) {
    final now = DateTime.now();

    if (range == '7D') {
      const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final values = List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        return invoices
            .where(
              (inv) =>
                  inv.date.year == day.year &&
                  inv.date.month == day.month &&
                  inv.date.day == day.day,
            )
            .fold<double>(0, (sum, inv) => sum + inv.totalAmount);
      });
      final labels = List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        return dayLabels[day.weekday - 1];
      });
      return (values: values, labels: labels);
    }

    if (range == '1M') {
      final values = List.generate(4, (i) {
        final weekEnd = now.subtract(Duration(days: 7 * (3 - i)));
        final weekStart = weekEnd.subtract(const Duration(days: 6));
        return invoices
            .where(
              (inv) =>
                  !inv.date.isBefore(
                    DateTime(weekStart.year, weekStart.month, weekStart.day),
                  ) &&
                  !inv.date.isAfter(
                    DateTime(
                      weekEnd.year,
                      weekEnd.month,
                      weekEnd.day,
                      23,
                      59,
                      59,
                    ),
                  ),
            )
            .fold<double>(0, (sum, inv) => sum + inv.totalAmount);
      });
      final labels = List.generate(4, (i) => 'W${i + 1}');
      return (values: values, labels: labels);
    }

    // 3M
    const monthLabels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final values = List.generate(3, (i) {
      final target = DateTime(now.year, now.month - (2 - i), 1);
      return invoices
          .where(
            (inv) =>
                inv.date.year == target.year && inv.date.month == target.month,
          )
          .fold<double>(0, (sum, inv) => sum + inv.totalAmount);
    });
    final labels = List.generate(3, (i) {
      final target = DateTime(now.year, now.month - (2 - i), 1);
      return monthLabels[target.month - 1];
    });
    return (values: values, labels: labels);
  }

  //-------------------- WEEKLY SALES DATA (this month, W1-W4) --------------------
  List<double> _weeklySalesThisMonth(List<InvoiceModel> invoices) {
    final now = DateTime.now();
    final thisMonthInvoices = invoices.where(
      (inv) => inv.date.year == now.year && inv.date.month == now.month,
    );
    final buckets = List<double>.filled(4, 0);
    for (final inv in thisMonthInvoices) {
      final weekIndex = ((inv.date.day - 1) ~/ 7).clamp(0, 3);
      buckets[weekIndex] += inv.totalAmount;
    }
    return buckets;
  }

  //-------------------- LOGOUT LOGIC --------------------
  Future<void> _handleLogout(BuildContext context) async {
    await AuthService().logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  //-------------------- FORMATTED DATE --------------------
  String _getFormattedDate() {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  //==================== RECENT SALES SECTION (extracted, reused for desktop row + mobile) ====================
  Widget _buildRecentSalesSection(
    BuildContext context,
    Color card,
    Color border,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        //-------------------- RECENT SALES SECTION --------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 16,
                  color: isDark ? accentController.value : textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recent sales',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? accentController.value : textPrimary,
                    fontFamily: isDark ? 'PlayfairDisplay' : null,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TodaySalesScreen()),
                );
              },
              child: Row(
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentController.value,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 13,
                    color: accentController.value,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        StreamBuilder<List<InvoiceModel>>(
          stream: _invoiceService.getInvoices(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      accentController.value,
                    ),
                  ),
                ),
              );
            }

            final invoices = snapshot.data ?? [];
            invoices.sort((a, b) => b.date.compareTo(a.date));
            final recentInvoices = invoices.take(5).toList();

            if (recentInvoices.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: isDark
                        ? accentController.value.withValues(alpha: 0.1)
                        : border,
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 40,
                        color: textMuted.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No sales yet',
                        style: TextStyle(color: textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: isDark
                      ? accentController.value.withValues(alpha: 0.1)
                      : border,
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.transparent,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: List.generate(recentInvoices.length, (index) {
                  final invoice = recentInvoices[index];
                  final isLast = index == recentInvoices.length - 1;

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerPurchaseHistoryScreen(
                                customerId: invoice.customerId,
                                customerName: invoice.customerName,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              _InitialsAvatar(name: invoice.customerName),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${invoice.invoiceNumber} | ${invoice.customerName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? accentController.value
                                        : textPrimary,
                                    fontFamily: isDark
                                        ? 'PlayfairDisplay'
                                        : null,
                                  ),
                                ),
                              ),

                              Text(
                                'Rs. ${invoice.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF22C55E),
                                ),
                              ),

                              const SizedBox(width: 12),

                              IconButton(
                                tooltip: 'View',
                                icon: const Icon(
                                  Icons.visibility_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  InvoicePdfService().viewPdf(invoice);
                                },
                              ),

                              IconButton(
                                tooltip: 'Share',
                                icon: const Icon(
                                  Icons.share_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  InvoicePdfService().sharePdf(invoice);
                                },
                              ),

                              IconButton(
                                tooltip: 'Download',
                                icon: const Icon(
                                  Icons.download_outlined,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final path = await InvoicePdfService()
                                      .downloadPdf(invoice);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Saved to: $path'),
                                        backgroundColor: const Color(
                                          0xFF22C55E,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      //-------------------- VIEW / SHARE / DOWNLOAD ROW --------------------
                      if (!isLast)
                        Divider(
                          color: isDark
                              ? accentController.value.withValues(alpha: 0.08)
                              : border,
                          height: 0.8,
                          indent: 14,
                          endIndent: 14,
                        ),
                    ],
                  );
                }),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  //-------------------- BUILD UI (RESPONSIVE ROOT) --------------------
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: backgroundThemeController,
      builder: (context, bgPreset, _) {
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
        final textMuted = isDark
            ? AppColors.darkTextMuted
            : AppColors.lightTextMuted;

        return ValueListenableBuilder<Color>(
          valueListenable: accentController,
          builder: (context, accent, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= kDesktopBreakpoint;

                if (isDesktop) {
                  return _buildDesktopLayout(
                    context,
                    bg,
                    card,
                    border,
                    textPrimary,
                    textSecondary,
                    textMuted,
                  );
                }
                return _buildMobileLayout(
                  context,
                  bg,
                  card,
                  border,
                  textPrimary,
                  textSecondary,
                  textMuted,
                );
              },
            );
          },
        );
      },
    );
  }

  //==================== DESKTOP LAYOUT (premium sidebar) ====================
  Widget _buildDesktopLayout(
    BuildContext context,
    Color bg,
    Color card,
    Color border,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bg,
      body: Row(
        children: [
          AdminSidebar(
            currentRoute: 'Dashboard',
            user: widget.user,
          ),

          //-------------------- MAIN CONTENT --------------------
          Expanded(
            child: RefreshIndicator(
              color: accentController.value,
              backgroundColor: card,
              onRefresh: () async =>
                  Future.delayed(const Duration(milliseconds: 500)),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: AppSpacing.lg,
                ),
                child: _buildDashboardContent(
                  context,
                  card,
                  border,
                  textPrimary,
                  textSecondary,
                  textMuted,
                  isDesktop: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //==================== MOBILE LAYOUT ====================
  Widget _buildMobileLayout(
    BuildContext context,
    Color bg,
    Color card,
    Color border,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bg,

      drawer: Drawer(
        backgroundColor: card,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentController.value,
                    Color.lerp(accentController.value, Colors.black, 0.2)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: widget.user.profileImageUrl.isNotEmpty
                    ? CachedNetworkImageProvider(widget.user.profileImageUrl)
                    : null,
                child: widget.user.profileImageUrl.isEmpty
                    ? Text(
                        widget.user.name.isNotEmpty
                            ? widget.user.name[0].toUpperCase()
                            : 'A',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: accentController.value,
                        ),
                      )
                    : null,
              ),
              accountName: Text(
                widget.user.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(widget.user.email),
            ),
            _MobileDrawerItem(
              icon: Icons.inventory_2_outlined,
              label: 'Products',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductListScreen()),
                );
              },
            ),
            _MobileDrawerItem(
              icon: Icons.people_outline,
              label: 'Customers',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CustomerListScreen(isAdmin: true),
                  ),
                );
              },
            ),
            _MobileDrawerItem(
              icon: Icons.point_of_sale_outlined,
              label: 'New Sale',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NewSaleScreen(
                      currentUserUid: widget.user.uid,
                      isAdmin: true,
                    ),
                  ),
                );
              },
            ),
            _MobileDrawerItem(
              icon: Icons.badge_outlined,
              label: 'Staff',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StaffManagementScreen(),
                  ),
                );
              },
            ),
            _MobileDrawerItem(
              icon: Icons.palette_outlined,
              label: 'Appearance',
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ThemeSettingsScreen(),
                  ),
                );
              },
            ),
            Divider(color: border),
            _MobileDrawerItem(
              icon: Icons.logout,
              label: 'Logout',
              isDark: isDark,
              isDanger: true,
              onTap: () {
                Navigator.pop(context);
                _handleLogout(context);
              },
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          color: accentController.value,
          backgroundColor: card,
          onRefresh: () async =>
              Future.delayed(const Duration(milliseconds: 500)),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //-------------------- TOP BAR --------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Builder(
                      builder: (context) => GestureDetector(
                        onTap: () => Scaffold.of(context).openDrawer(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                            border: Border.all(
                              color: isDark
                                  ? accentController.value.withValues(
                                      alpha: 0.2,
                                    )
                                  : border,
                              width: 0.8,
                            ),
                          ),
                          child: Icon(Icons.menu, size: 20, color: textPrimary),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            themeController.value = isDark
                                ? ThemeMode.light
                                : ThemeMode.dark;
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(
                                AppRadius.button,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? accentController.value.withValues(
                                        alpha: 0.2,
                                      )
                                    : border,
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              isDark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              size: 18,
                              color: isDark
                                  ? accentController.value
                                  : textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        GestureDetector(
                          onTap: () => _handleLogout(context),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(
                                AppRadius.button,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? accentController.value.withValues(
                                        alpha: 0.2,
                                      )
                                    : border,
                                width: 0.8,
                              ),
                            ),
                            child: const Icon(
                              Icons.logout,
                              size: 18,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                _buildDashboardContent(
                  context,
                  card,
                  border,
                  textPrimary,
                  textSecondary,
                  textMuted,
                  isDesktop: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //==================== SHARED CONTENT ====================
  Widget _buildDashboardContent(
    BuildContext context,
    Color card,
    Color border,
    Color textPrimary,
    Color textSecondary,
    Color textMuted, {
    required bool isDesktop,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = widget.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        //-------------------- HEADER --------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getFormattedDate(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? accentController.value : textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Shop overview',
                  style: TextStyle(
                    fontSize: isDesktop ? 26 : 19,
                    fontWeight: FontWeight.w600,
                    color: isDark ? accentController.value : textPrimary,
                    fontFamily: isDark ? 'PlayfairDisplay' : null,
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ThemeSettingsScreen(isAdmin: true),
                      ),
                    );
                  },
                  child: Container(
                    width: isDesktop ? 44 : 36,
                    height: isDesktop ? 44 : 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentController.value.withValues(alpha: 0.12),
                      border: Border.all(
                        color: accentController.value.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      size: isDesktop ? 26 : 21,
                      color: accentController.value,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StreamBuilder<List<UrgentAlertModel>>(
                  stream: AlertService().getActiveAlerts(),
                  builder: (context, alertSnap) {
                    final activeAlerts = alertSnap.data ?? [];
                    final count = activeAlerts.length;
                    final hasAlerts = count > 0;

                    return GestureDetector(
                      onTap: () => _showAlertsListDialog(context, activeAlerts, isDark, textPrimary, textSecondary),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: isDesktop ? 44 : 36,
                            height: isDesktop ? 44 : 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasAlerts 
                                  ? AppColors.danger.withValues(alpha: 0.12)
                                  : accentController.value.withValues(alpha: 0.12),
                              border: Border.all(
                                color: hasAlerts 
                                    ? AppColors.danger.withValues(alpha: 0.35)
                                    : accentController.value.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              hasAlerts ? Icons.notifications_active_outlined : Icons.notifications_outlined,
                              size: isDesktop ? 24 : 19,
                              color: hasAlerts ? AppColors.danger : accentController.value,
                            ),
                          ),
                          if (hasAlerts)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                StreamBuilder<UserModel?>(
                  stream: AuthService().getUserStream(user.uid),
                  builder: (context, userSnap) {
                    final liveUser = userSnap.data ?? user;
                    final imgUrl = liveUser.profileImageUrl;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminProfileScreen(user: liveUser),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accentController.value.withValues(alpha: 0.35),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentController.value.withValues(alpha: 0.15),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: isDesktop ? 26 : 19,
                          backgroundColor: accentController.value.withValues(
                            alpha: 0.12,
                          ),
                          backgroundImage: imgUrl.isNotEmpty
                              ? CachedNetworkImageProvider(imgUrl)
                              : null,
                          child: imgUrl.isEmpty
                              ? Text(
                                  liveUser.name.isNotEmpty
                                      ? liveUser.name[0].toUpperCase()
                                      : 'A',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 17 : 13,
                                    fontWeight: FontWeight.bold,
                                    color: accentController.value,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: isDesktop ? AppSpacing.lg : AppSpacing.md),

        //-------------------- STATS --------------------
        StreamBuilder<List<InvoiceModel>>(
          stream: _invoiceService.getInvoices(),
          builder: (context, invoiceSnapshot) {
            final invoices = invoiceSnapshot.data ?? [];
            final totalRevenue = invoices.fold<double>(
              0,
              (sum, inv) => sum + inv.totalAmount,
            );

            final now = DateTime.now();
            final todaysInvoices = invoices
                .where(
                  (inv) =>
                      inv.date.year == now.year &&
                      inv.date.month == now.month &&
                      inv.date.day == now.day,
                )
                .toList();
            final todaysSales = todaysInvoices.fold<double>(
              0,
              (sum, inv) => sum + inv.totalAmount,
            );

            final yesterday = now.subtract(const Duration(days: 1));
            final yesterdaySales = invoices
                .where(
                  (inv) =>
                      inv.date.year == yesterday.year &&
                      inv.date.month == yesterday.month &&
                      inv.date.day == yesterday.day,
                )
                .fold<double>(0, (sum, inv) => sum + inv.totalAmount);

            final weekStart = now.subtract(const Duration(days: 6));
            final thisWeekRevenue = invoices
                .where(
                  (inv) => !inv.date.isBefore(
                    DateTime(weekStart.year, weekStart.month, weekStart.day),
                  ),
                )
                .fold<double>(0, (sum, inv) => sum + inv.totalAmount);
            final prevWeekStart = weekStart.subtract(const Duration(days: 7));
            final prevWeekEnd = weekStart.subtract(const Duration(days: 1));
            final prevWeekRevenue = invoices
                .where(
                  (inv) =>
                      !inv.date.isBefore(
                        DateTime(
                          prevWeekStart.year,
                          prevWeekStart.month,
                          prevWeekStart.day,
                        ),
                      ) &&
                      !inv.date.isAfter(
                        DateTime(
                          prevWeekEnd.year,
                          prevWeekEnd.month,
                          prevWeekEnd.day,
                          23,
                          59,
                          59,
                        ),
                      ),
                )
                .fold<double>(0, (sum, inv) => sum + inv.totalAmount);

            final revenueChange = _percentChange(
              thisWeekRevenue,
              prevWeekRevenue,
            );
            final todaySalesChange = _percentChange(
              todaysSales,
              yesterdaySales,
            );

            final List<double> last7Days = List.generate(7, (i) {
              final day = now.subtract(Duration(days: 6 - i));
              return invoices
                  .where(
                    (inv) =>
                        inv.date.year == day.year &&
                        inv.date.month == day.month &&
                        inv.date.day == day.day,
                  )
                  .fold<double>(0, (sum, inv) => sum + inv.totalAmount);
            });
            final maxDay = last7Days.reduce((a, b) => a > b ? a : b);

            //-------------------- REVENUE CARD (Premium Gold, mobile only) --------------------
            final revenueCard = Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentController.value,
                    Color.lerp(accentController.value, Colors.black, 0.2)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: [
                  BoxShadow(
                    color: accentController.value.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total revenue',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rs. ${totalRevenue.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: isDesktop ? 34 : 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: isDark ? 'PlayfairDisplay' : null,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.trending_up,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${invoices.length} orders',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: isDesktop ? 52 : 36,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        final ratio = maxDay > 0
                            ? (last7Days[index] / maxDay)
                            : 0.0;
                        final isToday = index == 6;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Container(
                              height: 6 + ((isDesktop ? 44 : 30) * ratio),
                              decoration: BoxDecoration(
                                color: isToday
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );

            //-------------------- TODAY'S SALES CARD (Premium, mobile) --------------------
            final todaysSalesCard = GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TodaySalesScreen()),
                );
              },
              child: _ColorStatCard(
                icon: Icons.point_of_sale_outlined,
                label: "Today's sales",
                value: 'Rs. ${todaysSales.toStringAsFixed(0)}',
                color: const Color(0xFF22C55E),
                card: card,
                border: border,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
            );

            return StreamBuilder<List<CustomerModel>>(
              stream: _customerService.getCustomers(),
              builder: (context, customerSnapshot) {
                final customers = customerSnapshot.data ?? [];
                final customerCount = customers.length;

                final thisMonthNewCustomers = customers
                    .where(
                      (c) =>
                          c.createdAt.year == now.year &&
                          c.createdAt.month == now.month,
                    )
                    .length;
                final lastMonthDate = DateTime(now.year, now.month - 1, 1);
                final lastMonthNewCustomers = customers
                    .where(
                      (c) =>
                          c.createdAt.year == lastMonthDate.year &&
                          c.createdAt.month == lastMonthDate.month,
                    )
                    .length;
                final customersChange = _percentChange(
                  thisMonthNewCustomers.toDouble(),
                  lastMonthNewCustomers.toDouble(),
                );

                final customersCard = GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerListScreen(isAdmin: true),
                      ),
                    );
                  },
                  child: _ColorStatCard(
                    icon: Icons.people_outline,
                    label: 'Customers',
                    value: '$customerCount',
                    color: const Color(0xFF3B82F6),
                    card: card,
                    border: border,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  ),
                );

                return StreamBuilder<List<ProductModel>>(
                  stream: _productService.getProducts(),
                  builder: (context, productSnapshot) {
                    final products = productSnapshot.data ?? [];
                    final totalProducts = products.length;
                    final inStockCount = products
                        .where((p) => p.stockQty > 0)
                        .length;
                    final lowStockCount = products
                        .where((p) => p.isLowStock)
                        .length;

                    final productsCard = GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductListScreen(),
                          ),
                        );
                      },
                      child: _ColorStatCard(
                        icon: Icons.inventory_2_outlined,
                        label: 'Total products',
                        value: '$totalProducts',
                        color: accentController.value,
                        card: card,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        isDark: isDark,
                      ),
                    );

                    final lowStockCard = _ColorStatCard(
                      icon: Icons.warning_amber_rounded,
                      label: 'Low stock',
                      value: '$lowStockCount',
                      color: lowStockCount > 0
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF22C55E),
                      card: card,
                      border: border,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    );

                    return StreamBuilder<List<AttendanceModel>>(
                      stream: _attendanceService.getAllAttendanceHistory(),
                      builder: (context, attendanceSnapshot) {
                        final allAttendance = attendanceSnapshot.data ?? [];
                        final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                        final todayAttendance = allAttendance.where((r) => r.date == todayStr).toList();
                        final presentCount = todayAttendance.length;

                        final staffPresentCard = GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AttendancePayrollScreen(),
                              ),
                            );
                          },
                          child: _ColorStatCard(
                            icon: Icons.badge_outlined,
                            label: 'Staff Present Today',
                            value: '$presentCount',
                            color: const Color(0xFFF59E0B),
                            card: card,
                            border: border,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                          ),
                        );

                        //==================== DESKTOP: NEW RICH LAYOUT ====================
                        if (isDesktop) {
                          final trend = _revenueTrendData(invoices, _revenueRange);
                          final weeklySales = _weeklySalesThisMonth(invoices);
                          final totalOrders = invoices.length;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              //-------------------- ROW 1: 5 STAT CARDS --------------------
                              Row(
                                children: [
                                  Expanded(
                                    child: _MiniStatCard(
                                      icon: Icons.account_balance_wallet_outlined,
                                      label: 'Total Revenue',
                                      value: 'Rs. ${totalRevenue.toStringAsFixed(0)}',
                                      changePercent: revenueChange,
                                      color: accentController.value,
                                      card: card,
                                      border: border,
                                      textPrimary: textPrimary,
                                      textSecondary: textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TodaySalesScreen(),
                                        ),
                                      ),
                                      child: _MiniStatCard(
                                        icon: Icons.point_of_sale_outlined,
                                        label: "Today's Sales",
                                        value: 'Rs. ${todaysSales.toStringAsFixed(0)}',
                                        changePercent: todaySalesChange,
                                        color: const Color(0xFF8B5CF6),
                                        card: card,
                                        border: border,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const CustomerListScreen(
                                            isAdmin: true,
                                          ),
                                        ),
                                      ),
                                      child: _MiniStatCard(
                                        icon: Icons.people_outline,
                                        label: 'Customers',
                                        value: '$customerCount',
                                        changePercent: customersChange,
                                        color: const Color(0xFF22C55E),
                                        card: card,
                                        border: border,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ProductListScreen(),
                                        ),
                                      ),
                                      child: _MiniStatCard(
                                        icon: Icons.warning_amber_rounded,
                                        label: 'Low Stock',
                                        value: '$lowStockCount items',
                                        changePercent: null,
                                        color: const Color(0xFFEF4444),
                                        card: card,
                                        border: border,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const AttendancePayrollScreen(),
                                        ),
                                      ),
                                      child: _MiniStatCard(
                                        icon: Icons.badge_outlined,
                                        label: 'Staff Present',
                                        value: '$presentCount',
                                        changePercent: null,
                                        color: const Color(0xFFF59E0B),
                                        card: card,
                                        border: border,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),

                              //-------------------- ROW 2: REVENUE TREND + WEEKLY SALES --------------------
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _RevenueTrendCard(
                                        values: trend.values,
                                        labels: trend.labels,
                                        selectedRange: _revenueRange,
                                        onRangeChanged: (r) =>
                                            setState(() => _revenueRange = r),
                                        accent: accentController.value,
                                        card: card,
                                        border: border,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      flex: 2,
                                      child: _WeeklyBarChartCard(
                                        values: weeklySales,
                                        accent: const Color(0xFF3B82F6),
                                        card: card,
                                        border: border,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),

                              //-------------------- QUICK STATS + RECENT SALES (same row) --------------------
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _QuickStatsCard(
                                        totalProducts: totalProducts,
                                        inStock: inStockCount,
                                        totalOrders: totalOrders,
                                        card: card,
                                        border: border,
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      flex: 3,
                                      child: _buildRecentSalesSection(
                                        context,
                                        card,
                                        border,
                                        textPrimary,
                                        textSecondary,
                                        textMuted,
                                        isDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        //==================== MOBILE: ORIGINAL STACKED LAYOUT ====================
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            revenueCard,
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Expanded(child: todaysSalesCard),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(child: customersCard),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Expanded(child: productsCard),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(child: lowStockCard),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            staffPresentCard,
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),

        //-------------------- QUICK ACTIONS (mobile only) --------------------
        if (!isDesktop) ...[
          Text(
            'Quick actions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? accentController.value : textPrimary,
              fontFamily: isDark ? 'PlayfairDisplay' : null,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.inventory_2_outlined,
                  label: 'Products',
                  color: accentController.value,
                  card: card,
                  border: border,
                  textPrimary: textPrimary,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductListScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.people_outline,
                  label: 'Customers',
                  color: const Color(0xFF3B82F6),
                  card: card,
                  border: border,
                  textPrimary: textPrimary,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerListScreen(isAdmin: true),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.badge_outlined,
                  label: 'Staff',
                  color: const Color(0xFF8B5CF6),
                  card: card,
                  border: border,
                  textPrimary: textPrimary,
                  isDark: isDark,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StaffManagementScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        if (!isDesktop)
          _buildRecentSalesSection(
            context,
            card,
            border,
            textPrimary,
            textSecondary,
            textMuted,
            isDark,
          ),
      ],
    );
  }
}

//-------------------- PREMIUM SIDEBAR NAV ITEM --------------------
class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool isDanger;
  final VoidCallback onTap;
  final Color textSecondary;
  final bool isDark;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.textSecondary,
    required this.isDark,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger
        ? AppColors.danger
        : selected
        ? accentController.value
        : textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? accentController.value.withValues(alpha: 0.12)
              : null,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: selected
              ? Border.all(
                  color: accentController.value.withValues(alpha: 0.2),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? accentController.value : color,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? accentController.value : color,
              ),
            ),
            if (selected) const Spacer(),
            if (selected)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: accentController.value,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

//-------------------- PREMIUM COLOR STAT CARD --------------------
class _ColorStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _ColorStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark
              ? accentController.value.withValues(alpha: 0.1)
              : border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.transparent,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? accentController.value : textPrimary,
              fontFamily: isDark ? 'PlayfairDisplay' : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: textSecondary)),
        ],
      ),
    );
  }
}

//-------------------- QUICK ACTION BUTTON --------------------
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color card;
  final Color border;
  final Color textPrimary;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isDark
                ? accentController.value.withValues(alpha: 0.1)
                : border,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.transparent,
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.15)),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//-------------------- MOBILE DRAWER ITEM --------------------
class _MobileDrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool isDanger;
  final VoidCallback onTap;

  const _MobileDrawerItem({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDanger
        ? AppColors.danger
        : isDark
        ? accentController.value
        : AppColors.primary;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: isDanger
              ? AppColors.danger
              : isDark
              ? Colors.white
              : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }
}

//-------------------- RECENT SALE QUICK ACTION (View/Share/Delete) --------------------
class _RecentSaleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool isDanger;
  final VoidCallback onTap;

  const _RecentSaleAction({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  }) : isDanger = false;

  @override
  Widget build(BuildContext context) {
    final color = isDanger ? AppColors.danger : accentController.value;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}

//-------------------- MINI STAT CARD (with % change badge) --------------------
class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double? changePercent; // null = no badge shown
  final Color color;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.changePercent,
    required this.color,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = (changePercent ?? 0) >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
              if (changePercent != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isPositive
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444))
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 10,
                        color: isPositive
                            ? const Color(0xFF22C55E)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${changePercent!.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isPositive
                              ? const Color(0xFF22C55E)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

//-------------------- REVENUE TREND CARD (line chart + range toggle) --------------------
class _RevenueTrendCard extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;
  final Color accent;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const _RevenueTrendCard({
    required this.values,
    required this.labels,
    required this.selectedRange,
    required this.onRangeChanged,
    required this.accent,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Trend',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedRange == '7D'
                        ? 'Last 7 days'
                        : selectedRange == '1M'
                        ? 'Last 4 weeks'
                        : 'Last 3 months',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                ],
              ),
              Row(
                children: ['7D', '1M', '3M'].map((r) {
                  final isSelected = r == selectedRange;
                  return GestureDetector(
                    onTap: () => onRangeChanged(r),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? accent : border,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        r,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _RevenueLinePainter(
                values: values,
                maxValue: maxVal,
                lineColor: accent,
                gridColor: border,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map(
                  (l) => Text(
                    l,
                    style: TextStyle(fontSize: 10, color: textSecondary),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

//-------------------- REVENUE LINE CHART PAINTER --------------------
class _RevenueLinePainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final Color lineColor;
  final Color gridColor;

  _RevenueLinePainter({
    required this.values,
    required this.maxValue,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final max = maxValue > 0 ? maxValue : 1;

    //---------- GRIDLINES ----------
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..strokeWidth = 0.8;
    for (var i = 0; i <= 3; i++) {
      final y = size.height - (size.height / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.length < 2) return;

    final stepX = size.width / (values.length - 1);
    final points = List.generate(values.length, (i) {
      final ratio = values[i] / max;
      final y = size.height - (ratio * size.height);
      return Offset(i * stepX, y);
    });

    //---------- FILL UNDER LINE ----------
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    //---------- SMOOTH LINE ----------
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      linePath.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    //---------- DOT ON LAST POINT ----------
    canvas.drawCircle(points.last, 4, Paint()..color = lineColor);
    canvas.drawCircle(
      points.last,
      4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RevenueLinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.maxValue != maxValue;
}

//-------------------- WEEKLY BAR CHART CARD --------------------
class _WeeklyBarChartCard extends StatelessWidget {
  final List<double> values;
  final Color accent;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const _WeeklyBarChartCard({
    required this.values,
    required this.accent,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Sales',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'This month',
            style: TextStyle(fontSize: 11, color: textSecondary),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (i) {
                final ratio = maxVal > 0 ? (values[i] / maxVal) : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      height: 8 + (140 * ratio),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.85),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              values.length,
              (i) => Text(
                'W${i + 1}',
                style: TextStyle(fontSize: 10, color: textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//-------------------- QUICK STATS CARD (progress bars) --------------------
class _QuickStatsCard extends StatelessWidget {
  final int totalProducts;
  final int inStock;
  final int totalOrders;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const _QuickStatsCard({
    required this.totalProducts,
    required this.inStock,
    required this.totalOrders,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final productsRatio = (totalProducts / 20).clamp(0.0, 1.0);
    final inStockRatio = totalProducts > 0
        ? (inStock / totalProducts).clamp(0.0, 1.0)
        : 0.0;
    final ordersRatio = (totalOrders / 50).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_outlined,
                size: 16,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Stats',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatProgressRow(
            label: 'Total Products',
            value: '$totalProducts',
            ratio: productsRatio,
            color: const Color(0xFF3B82F6),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
          ),
          const SizedBox(height: 14),
          _StatProgressRow(
            label: 'In Stock',
            value: '$inStock',
            ratio: inStockRatio,
            color: const Color(0xFF22C55E),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
          ),
          const SizedBox(height: 14),
          _StatProgressRow(
            label: 'Total Orders',
            value: '$totalOrders',
            ratio: ordersRatio,
            color: const Color(0xFF8B5CF6),
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            border: border,
          ),
        ],
      ),
    );
  }
}

//-------------------- STAT PROGRESS ROW (used inside Quick Stats) --------------------
class _StatProgressRow extends StatelessWidget {
  final String label;
  final String value;
  final double ratio;
  final Color color;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  const _StatProgressRow({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: textSecondary)),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

//-------------------- COLORED INITIALS AVATAR (Recent Sales) --------------------
class _InitialsAvatar extends StatelessWidget {
  final String name;

  const _InitialsAvatar({required this.name});

  static const List<Color> _palette = [
    Color(0xFF7C3AED),
    Color(0xFF059669),
    Color(0xFFDC2626),
    Color(0xFF2563EB),
    Color(0xFFD97706),
  ];

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color get _color {
    final index = name.isNotEmpty ? name.codeUnitAt(0) % _palette.length : 0;
    return _palette[index];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _color,
        ),
      ),
    );
  }
}

  void _showAlertsListDialog(
    BuildContext context,
    List<UrgentAlertModel> activeAlerts,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? AppColors.darkBg : Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Active Staff Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 300,
            child: activeAlerts.isEmpty
                ? Center(
                    child: Text(
                      'No active notifications found.',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: activeAlerts.length,
                    separatorBuilder: (context, idx) => Divider(color: border),
                    itemBuilder: (context, index) {
                      final alert = activeAlerts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alert.message,
                                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'By ${alert.userName} at ${DateFormat('hh:mm a').format(alert.createdAt)}',
                                    style: TextStyle(color: textSecondary, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                              tooltip: 'Acknowledge & Dismiss',
                              onPressed: () async {
                                await AlertService().markAsRead(alert.id);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
