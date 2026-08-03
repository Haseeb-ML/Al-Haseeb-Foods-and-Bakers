import 'package:flutter/material.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import '../../services/invoice_pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../theme/accent_controller.dart';
import '../../theme/background_theme_controller.dart';
import 'theme_settings_screen.dart';
import '../shared/invoice_detail_screen.dart';
import 'product_list_screen.dart';
import 'staff_management_screen.dart';
import '../shared/customer_list_screen.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/staff_sidebar.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/admin_header_actions.dart';

//-------------------- DESKTOP BREAKPOINT --------------------
const double _kDesktopBreakpoint = 900;

//-------------------- TODAY SALES SCREEN --------------------
class TodaySalesScreen extends StatefulWidget {
  const TodaySalesScreen({super.key});

  @override
  State<TodaySalesScreen> createState() => _TodaySalesScreenState();
}

class _TodaySalesScreenState extends State<TodaySalesScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  late Stream<List<InvoiceModel>> _todayInvoicesStream;

  @override
  void initState() {
    super.initState();
    _todayInvoicesStream = _invoiceService.getTodayInvoices();
  }

  //-------------------- FORMAT TIME --------------------
  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $period";
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

  String _formatDateOnly(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  //-------------------- BUILD UI --------------------
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
                final isDesktop = constraints.maxWidth >= _kDesktopBreakpoint;

                final content = _buildContent(
                  context,
                  bg,
                  card,
                  border,
                  textPrimary,
                  textSecondary,
                  textMuted,
                  accent,
                  isDark,
                  isDesktop,
                );
                if (isDesktop) {
                  final String currentUid = AuthService().currentUser?.uid ?? '';
                  return StreamBuilder<UserModel?>(
                    stream: AuthService().getUserStream(currentUid),
                    builder: (context, userSnap) {
                      final currentUser = userSnap.data;
                      final isStaff = currentUser != null && currentUser.role == 'staff';

                      return Scaffold(
                        backgroundColor: bg,
                        body: Row(
                          children: [
                            (isStaff || StaffSidebar.adminPreviewMode)
                                ? StaffSidebar(
                                    currentRoute: "Today's Sales",
                                    user: currentUser,
                                    isAdminPreview: StaffSidebar.adminPreviewMode,
                                  )
                                : const AdminSidebar(
                                    currentRoute: "Today's Sales",
                                  ),
                             Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Overview',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: accent,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "Today's Sales",
                                              style: TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary,
                                                fontFamily: isDark ? 'PlayfairDisplay' : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (!isStaff) AdminHeaderActions(isDesktop: isDesktop),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(child: content),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                //-------------------- MOBILE LAYOUT --------------------
                return Scaffold(
                  backgroundColor: bg,
                  drawer: const Drawer(
                    width: 230,
                    child: AdminSidebar(currentRoute: "Today's Sales"),
                  ),
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: border, width: 0.8),
                                    ),
                                    child: Icon(Icons.menu, size: 20, color: textPrimary),
                                  ),
                                ),
                              ),
                              if (!isStaff) AdminHeaderActions(isDesktop: false),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Overview',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: accent,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Today's Sales",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                      fontFamily: isDark ? 'PlayfairDisplay' : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(child: content),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  //-------------------- SHARED CONTENT --------------------
  Widget _buildContent(
    BuildContext context,
    Color bg,
    Color card,
    Color border,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    Color accent,
    bool isDark,
    bool isDesktop,
  ) {
    return StreamBuilder<List<InvoiceModel>>(
      stream: _todayInvoicesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: accent));
        }

        final invoices = snapshot.data ?? [];
        invoices.sort((a, b) => b.date.compareTo(a.date));

        if (invoices.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.point_of_sale_outlined,
                  size: 70,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                const SizedBox(height: 15),
                Text(
                  "No Sales Today",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    fontFamily: isDark ? 'PlayfairDisplay' : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Sales will appear here after creating invoices.",
                  style: TextStyle(color: textSecondary),
                ),
              ],
            ),
          );
        }

        final totalRevenue = invoices.fold<double>(
          0,
          (sum, invoice) => sum + invoice.totalAmount,
        );
        final totalInvoices = invoices.length;
        final totalItems = invoices.fold<int>(
          0,
          (sum, invoice) => sum + invoice.items.length,
        );
        final averageSale = totalInvoices == 0
            ? 0
            : totalRevenue / totalInvoices;
        final highestSale = invoices
            .map((e) => e.totalAmount)
            .reduce((a, b) => a > b ? a : b);
        final lowestSale = invoices
            .map((e) => e.totalAmount)
            .reduce((a, b) => a < b ? a : b);

        final HSLColor hslAccent = HSLColor.fromColor(accent);
        final Color darkerAccent = hslAccent
            .withLightness((hslAccent.lightness - 0.15).clamp(0.0, 1.0))
            .toColor();

        return RefreshIndicator(
          color: accent,
          backgroundColor: card,
          onRefresh: () async =>
              Future.delayed(const Duration(milliseconds: 500)),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 0 : AppSpacing.sm,
              vertical: 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //-------------------- DATE LABEL --------------------
                Text(
                  _getFormattedDate(),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? accent : textSecondary,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                //-------------------- REVENUE HERO CARD (Dynamic Accent Gradient) --------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, darkerAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.3),
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
                                "Today's revenue",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rs. ${totalRevenue.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: isDesktop ? 30 : 26,
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
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.receipt_long,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$totalInvoices invoice(s)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                //-------------------- STAT GRID: ITEMS / AVERAGE --------------------
                Row(
                  children: [
                    Expanded(
                      child: _ColorStatCard(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Items sold',
                        value: '$totalItems',
                        color: accent,
                        card: card,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _ColorStatCard(
                        icon: Icons.bar_chart_rounded,
                        label: 'Average sale',
                        value: 'Rs. ${averageSale.toStringAsFixed(0)}',
                        color: const Color(0xFF3B82F6),
                        card: card,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                //-------------------- STAT GRID: HIGHEST / LOWEST --------------------
                Row(
                  children: [
                    Expanded(
                      child: _ColorStatCard(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Highest sale',
                        value: 'Rs. ${highestSale.toStringAsFixed(0)}',
                        color: const Color(0xFF22C55E),
                        card: card,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _ColorStatCard(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Lowest sale',
                        value: 'Rs. ${lowestSale.toStringAsFixed(0)}',
                        color: const Color(0xFFEF4444),
                        card: card,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                //-------------------- INVOICE LIST HEADER --------------------
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 16,
                      color: isDark ? accent : textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Today's invoices",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? accent : textPrimary,
                        fontFamily: isDark ? 'PlayfairDisplay' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                //-------------------- BORDERED DIVIDER LIST --------------------
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: isDark
                          ? accent.withValues(alpha: 0.18)
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
                    children: List.generate(invoices.length, (index) {
                      final invoice = invoices[index];
                      final isLast = index == invoices.length - 1;

                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      InvoiceDetailScreen(invoice: invoice),
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
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: accent.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long_outlined,
                                      color: accent,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          invoice.customerName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                            fontFamily: isDark
                                                ? 'PlayfairDisplay'
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${invoice.items.length} item(s) · ${invoice.invoiceNumber} · ${_formatTime(invoice.date)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: textSecondary,
                                          ),
                                        ),
                                        if (invoice.dueAmount > 0) ...[
                                          const SizedBox(height: 5),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEF4444).withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.pending_actions_outlined,
                                                      color: Color(0xFFEF4444),
                                                      size: 10,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Pending: Rs. ${invoice.dueAmount.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        fontSize: 9,
                                                        color: Color(0xFFEF4444),
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (invoice.dueDate != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(
                                                        Icons.calendar_today_outlined,
                                                        color: Color(0xFFF59E0B),
                                                        size: 10,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Due: ${_formatDateOnly(invoice.dueDate!)}',
                                                        style: const TextStyle(
                                                          fontSize: 9,
                                                          color: Color(0xFFF59E0B),
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Rs. ${invoice.totalAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF22C55E),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      _InvoiceIconAction(
                                        icon: Icons.visibility_outlined,
                                        accent: accent,
                                        onTap: () => InvoicePdfService().viewPdf(invoice),
                                      ),
                                      const SizedBox(width: 6),
                                      _InvoiceIconAction(
                                        icon: Icons.share_outlined,
                                        accent: accent,
                                        onTap: () => InvoicePdfService().sharePdf(invoice),
                                      ),
                                      const SizedBox(width: 6),
                                      _InvoiceIconAction(
                                        icon: Icons.download_outlined,
                                        accent: accent,
                                        onTap: () async {
                                          final path = await InvoicePdfService().downloadPdf(invoice);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Saved to: $path'),
                                                behavior: SnackBarBehavior.floating,
                                                backgroundColor: const Color(0xFF22C55E),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (!isLast)
                            Divider(
                              color: border,
                              height: 0.8,
                              indent: 14,
                              endIndent: 14,
                            ),
                        ],
                      );
                    }),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }
}

//-------------------- COLOR STAT CARD (Dynamic Accent Supported) --------------------
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
          color: border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.transparent,
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
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: textSecondary)),
        ],
      ),
    );
  }
}

//-------------------- INVOICE ICON ACTION (View/Share/Download) --------------------
class _InvoiceIconAction extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _InvoiceIconAction({
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accent.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, size: 14, color: accent),
        ),
      ),
    );
  }
}
