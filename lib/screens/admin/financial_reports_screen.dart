import 'package:flutter/material.dart';
import '../../models/invoice_model.dart';
import '../../models/expense_model.dart';
import '../../models/user_model.dart';
import '../../services/invoice_service.dart';
import '../../services/expense_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/accent_controller.dart';
import '../../theme/background_theme_controller.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/admin_header_actions.dart';

const double _kDesktopBreakpoint = 900;

class FinancialReportsScreen extends StatefulWidget {
  final UserModel? user;
  const FinancialReportsScreen({super.key, this.user});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  final ExpenseService _expenseService = ExpenseService();

  // Created once and reused for every rebuild — creating a fresh stream
  // inside build() (e.g. on every setState from a chip tap) makes
  // StreamBuilder flip back to `waiting` each time, which is what caused
  // the whole page to blink to a loading spinner on every filter change.
  late final Stream<List<InvoiceModel>> _invoicesStream =
      _invoiceService.getInvoices();
  late final Stream<List<ExpenseModel>> _expensesStream =
      _expenseService.getExpenses();

  String _selectedRange = 'This Month'; // 'Today', 'This Week', 'This Month', 'This Year', 'All Time'

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_selectedRange) {
      case 'Today':
        return DateTime(now.year, now.month, now.day);
      case 'This Week':
        final weekday = now.weekday;
        final monday = now.subtract(Duration(days: weekday - 1));
        return DateTime(monday.year, monday.month, monday.day);
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      case 'This Year':
        return DateTime(now.year, 1, 1);
      case 'All Time':
      default:
        return DateTime(2000, 1, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.user ??
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

        return ValueListenableBuilder<Color>(
          valueListenable: accentController,
          builder: (context, accent, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= _kDesktopBreakpoint;

                final content = _buildFinancialContent(
                  context,
                  bg: bg,
                  card: card,
                  border: border,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  accent: accent,
                  isDark: isDark,
                  isDesktop: isDesktop,
                );

                if (isDesktop) {
                  return Scaffold(
                    backgroundColor: bg,
                    body: Row(
                      children: [
                        AdminSidebar(
                          currentRoute: 'Profit & Loss',
                          user: currentUser,
                        ),
                        Expanded(
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 16,
                              ),
                              child: content,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Scaffold(
                  backgroundColor: bg,
                  appBar: AppBar(
                    backgroundColor: bg,
                    elevation: 0,
                    centerTitle: true,
                    title: Text(
                      'Profit & Loss Report',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                  ),
                  body: SafeArea(child: content),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFinancialContent(
    BuildContext context, {
    required Color bg,
    required Color card,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color accent,
    required bool isDark,
    required bool isDesktop,
  }) {
    final startDate = _getStartDate();

    return StreamBuilder<List<InvoiceModel>>(
      stream: _invoicesStream,
      builder: (context, invoiceSnapshot) {
        return StreamBuilder<List<ExpenseModel>>(
          stream: _expensesStream,
          builder: (context, expenseSnapshot) {
            if (invoiceSnapshot.connectionState == ConnectionState.waiting ||
                expenseSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: accent));
            }

            final allInvoices = invoiceSnapshot.data ?? [];
            final allExpenses = expenseSnapshot.data ?? [];

            // Filter by selected range
            final filteredInvoices = allInvoices
                .where((inv) => !inv.date.isBefore(startDate))
                .toList();
            final filteredExpenses = allExpenses
                .where((exp) => !exp.date.isBefore(startDate))
                .toList();

            // Aggregations
            final totalRevenue = filteredInvoices.fold<double>(
              0.0,
              (sum, inv) => sum + inv.totalAmount,
            );
            final totalExpenses = filteredExpenses.fold<double>(
              0.0,
              (sum, exp) => sum + exp.amount,
            );

            final netProfit = totalRevenue - totalExpenses;
            final isProfitable = netProfit >= 0;

            final profitMargin = totalRevenue > 0
                ? (netProfit / totalRevenue) * 100
                : 0.0;

            final totalOrders = filteredInvoices.length;
            final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
            final totalItemsSold = filteredInvoices.fold<int>(
              0,
              (sum, inv) => sum + inv.items.length,
            );

            // Category breakdown for expenses
            final Map<String, double> expenseCategories = {};
            for (var exp in filteredExpenses) {
              final cat = exp.category.isEmpty ? 'General' : exp.category;
              expenseCategories[cat] = (expenseCategories[cat] ?? 0.0) + exp.amount;
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  // Resetting the scroll position whenever the filter
                  // changes — without this, switching from a long list
                  // (e.g. "This Month") to a shorter one (e.g. "Today")
                  // could keep the old scroll offset.
                  key: ValueKey(_selectedRange),
                  // Clamping (not bouncing) physics keeps content strictly
                  // pinned to the top. BouncingScrollPhysics allows an
                  // elastic/rubber-band effect that — when the content is
                  // shorter than the viewport (e.g. "Today"/"This Week"
                  // with little data) — was making the whole block appear
                  // to float away from the top with matching gaps above
                  // and below it.
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    // Guarantees the content column always fills at least
                    // the full visible height, so short content can never
                    // be treated as "free space to center in" by anything
                    // up the tree.
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  //-------------------- HEADER & FILTER BAR --------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Financial Performance',
                              style: TextStyle(
                                fontSize: isDesktop ? 22 : 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Real-time Sales vs Expense Analytics',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      AdminHeaderActions(isDesktop: isDesktop),
                    ],
                  ),
                  const SizedBox(height: 14),

                  //-------------------- TIME RANGE CHIPS --------------------
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Today', 'This Week', 'This Month', 'This Year', 'All Time']
                          .map((range) {
                        final selected = _selectedRange == range;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(range),
                            selected: selected,
                            selectedColor: accent.withValues(alpha: 0.2),
                            backgroundColor: card,
                            side: BorderSide(
                              color: selected ? accent : border,
                              width: selected ? 1.4 : 0.8,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              color: selected ? accent : textSecondary,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedRange = range);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  //-------------------- MAIN HERO PROFIT / LOSS CARD --------------------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isProfitable
                            ? [
                                accent,
                                HSLColor.fromColor(accent)
                                    .withLightness((HSLColor.fromColor(accent).lightness - 0.16).clamp(0.0, 1.0))
                                    .toColor(),
                              ]
                            : [
                                AppColors.danger,
                                const Color(0xFF991B1B),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: (isProfitable ? accent : AppColors.danger).withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isProfitable
                                        ? Icons.trending_up_rounded
                                        : Icons.trending_down_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isProfitable ? 'NET PROFIT' : 'NET LOSS',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${profitMargin.toStringAsFixed(1)}% Margin',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Rs. ${netProfit.abs().toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: isDesktop ? 36 : 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isProfitable
                              ? 'Net earnings after deducting all store expenses.'
                              : 'Total expenses exceeded sales revenue for this period.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  //-------------------- 4 METRICS CARDS --------------------
                  GridView.count(
                    crossAxisCount: isDesktop ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isDesktop ? 1.7 : 1.35,
                    children: [
                      // Total Sales Revenue
                      _MetricCard(
                        title: 'Gross Revenue',
                        value: 'Rs. ${totalRevenue.toStringAsFixed(0)}',
                        subtitle: '$totalOrders invoice(s)',
                        icon: Icons.payments_outlined,
                        color: const Color(0xFF10B981),
                        card: card,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      // Total Expenses
                      _MetricCard(
                        title: 'Total Expenses',
                        value: 'Rs. ${totalExpenses.toStringAsFixed(0)}',
                        subtitle: '${filteredExpenses.length} expense log(s)',
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppColors.danger,
                        card: card,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      // Average Order Value
                      _MetricCard(
                        title: 'Avg Order Value',
                        value: 'Rs. ${avgOrderValue.toStringAsFixed(0)}',
                        subtitle: 'Per invoice average',
                        icon: Icons.analytics_outlined,
                        color: const Color(0xFF3B82F6),
                        card: card,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),

                      // Items Sold
                      _MetricCard(
                        title: 'Items Sold',
                        value: '$totalItemsSold',
                        subtitle: 'Products dispatched',
                        icon: Icons.shopping_bag_outlined,
                        color: accent,
                        card: card,
                        border: border,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  //-------------------- EXPENSE CATEGORY BREAKDOWN --------------------
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pie_chart_outline_rounded, size: 18, color: accent),
                            const SizedBox(width: 8),
                            Text(
                              'Expense Distribution by Category',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (expenseCategories.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No expense records for this time period.',
                                style: TextStyle(color: textSecondary, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: expenseCategories.entries.map((entry) {
                              final pct = totalExpenses > 0
                                  ? (entry.value / totalExpenses) * 100
                                  : 0.0;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Rs. ${entry.value.toStringAsFixed(0)} (${pct.toStringAsFixed(1)}%)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct / 100,
                                        minHeight: 7,
                                        backgroundColor: border,
                                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                      ],
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
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: textSecondary),
          ),
        ],
      ),
    );
  }
}