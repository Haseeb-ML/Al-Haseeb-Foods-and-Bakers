import 'package:flutter/material.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import 'invoice_detail_screen.dart';
import '../../theme/app_theme.dart';

//-------------------- CUSTOMER PURCHASE HISTORY SCREEN --------------------
class CustomerPurchaseHistoryScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerPurchaseHistoryScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerPurchaseHistoryScreen> createState() =>
      _CustomerPurchaseHistoryScreenState();
}

class _CustomerPurchaseHistoryScreenState
    extends State<CustomerPurchaseHistoryScreen> {
  late final Stream<List<InvoiceModel>> _invoicesStream;

  @override
  void initState() {
    super.initState();
    _invoicesStream = InvoiceService().getInvoicesForCustomer(
      widget.customerId,
    );
  }

  //-------------------- FORMAT DATE + TIME --------------------
  String _formatDateTime(DateTime date) {
    const months = [
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
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year}, $hour:$minute $period';
  }

  //-------------------- BUILD UI --------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: StreamBuilder<List<InvoiceModel>>(
          stream: _invoicesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFD4AF37),
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textSecondary),
                  ),
                ),
              );
            }

            final invoices = snapshot.data ?? [];
            final totalOrders = invoices.length;
            final lifetimeValue = invoices.fold<double>(
              0,
              (sum, inv) => sum + inv.totalAmount,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  //-------------------- HEADER: BACK + TITLE (CENTERED) --------------------
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFFD4AF37).withOpacity(0.2)
                                  : border,
                              width: 0.8,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Purchase History',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFFD4AF37)
                                    : textSecondary,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.customerName,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? const Color(0xFFD4AF37)
                                    : textPrimary,
                                fontFamily: isDark ? 'PlayfairDisplay' : null,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40), // Placeholder for symmetry
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  //-------------------- CUSTOMER STATS ROW --------------------
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Total Orders',
                          value: '$totalOrders',
                          icon: Icons.receipt_long_outlined,
                          card: card,
                          border: border,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: _StatCard(
                          label: 'Lifetime Value',
                          value: 'Rs. ${lifetimeValue.toStringAsFixed(0)}',
                          icon: Icons.attach_money,
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

                  //-------------------- SECTION LABEL --------------------
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_outlined,
                          size: 16,
                          color: isDark
                              ? const Color(0xFFD4AF37)
                              : textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ALL PURCHASES',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFD4AF37)
                                : textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  //-------------------- PURCHASE LIST --------------------
                  if (invoices.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: textMuted.withOpacity(0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No purchases yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFFD4AF37).withOpacity(0.1)
                              : border,
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.2)
                                : Colors.transparent,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
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
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      //-------------------- INVOICE ICON --------------------
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFD4AF37,
                                          ).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFFD4AF37,
                                            ).withOpacity(0.15),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.receipt_long_outlined,
                                          color: Color(0xFFD4AF37),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      //-------------------- INVOICE INFO --------------------
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              invoice.invoiceNumber,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? const Color(0xFFD4AF37)
                                                    : textPrimary,
                                                fontFamily: isDark
                                                    ? 'PlayfairDisplay'
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${invoice.items.length} item(s) · ${_formatDateTime(invoice.date)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      //-------------------- AMOUNT --------------------
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF22C55E,
                                          ).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF22C55E,
                                            ).withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          'Rs. ${invoice.totalAmount.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF22C55E),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 20,
                                        color: textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Divider(
                                  color: isDark
                                      ? const Color(
                                          0xFFD4AF37,
                                        ).withOpacity(0.06)
                                      : border,
                                  height: 0.8,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                            ],
                          );
                        }),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

//-------------------- STAT CARD WIDGET (Premium) --------------------
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? const Color(0xFFD4AF37).withOpacity(0.1) : border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.15) : Colors.transparent,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFFD4AF37).withOpacity(0.08)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isDark ? const Color(0xFFD4AF37) : AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFD4AF37) : textPrimary,
              fontFamily: isDark ? 'PlayfairDisplay' : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textSecondary,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
