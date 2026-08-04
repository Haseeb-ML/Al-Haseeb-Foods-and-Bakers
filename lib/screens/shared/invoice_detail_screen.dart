import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import '../../models/invoice_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/staff_sidebar.dart';
import '../../widgets/admin_sidebar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/customer_service.dart';
import '../../services/invoice_pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/background_theme_controller.dart';
import '../../theme/accent_controller.dart';

//-------------------- INVOICE DETAIL SCREEN --------------------
// Ek invoice ki poori detail: customer, date/time, aur har product
// (naam, quantity, unit price, line total).
class InvoiceDetailScreen extends StatelessWidget {
  final InvoiceModel invoice;
  const InvoiceDetailScreen({super.key, required this.invoice});

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

  String _formatDateOnly(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  //-------------------- DOWNLOAD PDF HANDLER --------------------
  Future<void> _handleDownload(BuildContext context) async {
    final path = await InvoicePdfService().downloadPdf(invoice);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to: $path'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: 'Open',
            textColor: Colors.white,
            onPressed: () => OpenFile.open(path),
          ),
        ),
      );
    }
  }

    static const double _kDesktopBreakpoint = 900;

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

        return ValueListenableBuilder<Color>(
          valueListenable: accentController,
          builder: (context, accent, _) {
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('invoices').doc(invoice.id).snapshots(),
              builder: (context, invoiceSnap) {
                InvoiceModel liveInvoice = invoice;
                if (invoiceSnap.hasData && invoiceSnap.data!.exists) {
                  liveInvoice = InvoiceModel.fromMap(
                    invoiceSnap.data!.data() as Map<String, dynamic>,
                    invoiceSnap.data!.id,
                  );
                }

                final isDesktop = MediaQuery.of(context).size.width >= _kDesktopBreakpoint;

                final content = SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 0 : AppSpacing.sm,
                    vertical: isDesktop ? 0 : 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      //-------------------- HEADER: BACK + TITLE + PDF ACTIONS --------------------
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: card,
                                borderRadius: BorderRadius.circular(AppRadius.button),
                                border: Border.all(color: border, width: 0.8),
                              ),
                              child: Icon(
                                Icons.arrow_back,
                                size: 18,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invoice',
                                  style: TextStyle(fontSize: 12, color: textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  liveInvoice.invoiceNumber,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          //-------------------- VIEW BUTTON --------------------
                          GestureDetector(
                            onTap: () => InvoicePdfService().viewPdf(liveInvoice),
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: card,
                                borderRadius: BorderRadius.circular(AppRadius.button),
                                border: Border.all(color: border, width: 0.8),
                              ),
                              child: Icon(
                                Icons.visibility_outlined,
                                size: 17,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          //-------------------- DOWNLOAD BUTTON --------------------
                          GestureDetector(
                            onTap: () => _handleDownload(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: card,
                                borderRadius: BorderRadius.circular(AppRadius.button),
                                border: Border.all(color: border, width: 0.8),
                              ),
                              child: Icon(
                                Icons.download_outlined,
                                size: 17,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          //-------------------- SHARE PDF BUTTON --------------------
                          GestureDetector(
                            onTap: () => InvoicePdfService().sharePdf(liveInvoice),
                            child: Container(
                              width: 36,
                              height: 36,
                              margin: const EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(AppRadius.button),
                              ),
                              child: const Icon(
                                Icons.share_outlined,
                                size: 17,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      //-------------------- SHOP BRANDING HEADER --------------------
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
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.storefront_outlined,
                                color: accent,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AL-HASEEB FOODS & BAKERS',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: textPrimary,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                   Text(
                                     'Taste & Quality You Can Trust',
                                     style: TextStyle(
                                       fontSize: 11,
                                       color: textSecondary,
                                     ),
                                   ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Phone: 051X-XXXXXXX · Email: alhaseeb@gmail.com',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textSecondary.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      //-------------------- CUSTOMER + DATE CARD (primary/accent color) --------------------
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.person_outline,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    liveInvoice.customerName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 13,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDateTime(liveInvoice.date),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      //-------------------- SECTION LABEL --------------------
                      Text(
                        'PRODUCTS (${liveInvoice.items.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      //-------------------- FULL PRODUCT LIST --------------------
                      Container(
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: border, width: 0.8),
                        ),
                        child: Column(
                          children: List.generate(liveInvoice.items.length, (index) {
                            final item = liveInvoice.items[index];
                            final isLast = index == liveInvoice.items.length - 1;

                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 13,
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
                                          Icons.inventory_2_outlined,
                                          color: accent,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${item.quantity} × Rs. ${item.price.toStringAsFixed(0)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'Rs. ${item.total.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ],
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

                      //-------------------- TOTAL CARD WITH DUES BREAKDOWN --------------------
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (liveInvoice.discount > 0 || liveInvoice.tax > 0) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Subtotal',
                                    style: TextStyle(fontSize: 13, color: textSecondary),
                                  ),
                                  Text(
                                    'Rs. ${(liveInvoice.totalAmount + liveInvoice.discount - liveInvoice.tax).toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              if (liveInvoice.discount > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Discount',
                                      style: TextStyle(fontSize: 13, color: textSecondary),
                                    ),
                                    Text(
                                      '- Rs. ${liveInvoice.discount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (liveInvoice.tax > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Tax',
                                      style: TextStyle(fontSize: 13, color: textSecondary),
                                    ),
                                    Text(
                                      '+ Rs. ${liveInvoice.tax.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(height: 16),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: TextStyle(fontSize: 13, color: textSecondary),
                                ),
                                Text(
                                  'Rs. ${liveInvoice.totalAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Paid Amount',
                                  style: TextStyle(fontSize: 13, color: textSecondary),
                                ),
                                Text(
                                  'Rs. ${liveInvoice.amountPaid.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (liveInvoice.dueDate != null && liveInvoice.dueAmount > 0) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Due Date',
                                    style: TextStyle(fontSize: 13, color: textSecondary),
                                  ),
                                  Text(
                                    _formatDateOnly(liveInvoice.dueDate!),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            Divider(color: AppColors.success.withOpacity(0.2), height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pending/Due Amount',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: liveInvoice.dueAmount > 0 ? AppColors.danger : AppColors.success,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Rs. ${liveInvoice.dueAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: liveInvoice.dueAmount > 0 ? AppColors.danger : AppColors.success,
                                      ),
                                    ),
                                    if (liveInvoice.dueAmount > 0) ...[
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.danger,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.payments_outlined,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          'Pay Dues',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        onPressed: () => _showPayDuesDialog(context, liveInvoice),
                                      ),
                                    ] else ...[
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Fully Paid',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.success,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= _kDesktopBreakpoint;

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
                                  child: SafeArea(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      child: content,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }

                    return Scaffold(
                      backgroundColor: bg,
                      body: SafeArea(child: content),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
  //-------------------- PAY DUES DIALOG --------------------
  void _showPayDuesDialog(BuildContext context, InvoiceModel liveInvoice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountController = TextEditingController(
      text: liveInvoice.dueAmount.toStringAsFixed(0),
    );
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isDark ? AppColors.darkBg : Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.danger,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pay Dues',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer: ${liveInvoice.customerName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remaining Dues: Rs. ${liveInvoice.dueAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount Paid (Rs.)',
                      labelStyle: TextStyle(
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      prefixText: 'Rs. ',
                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter amount';
                      }
                      final amt = double.tryParse(value);
                      if (amt == null || amt <= 0) {
                        return 'Enter a valid amount';
                      }
                      if (amt > liveInvoice.dueAmount) {
                        return 'Cannot pay more than Rs. ${liveInvoice.dueAmount.toStringAsFixed(0)}';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setDialogState(() => isLoading = true);
                        try {
                          final currentUid = AuthService().currentUser?.uid ?? '';
                          final liveUser = await AuthService().getUserData(currentUid);
                          final userName = liveUser?.name ?? 'Staff';

                          await CustomerService().receivePaymentForInvoice(
                            customerId: liveInvoice.customerId,
                            invoiceId: liveInvoice.id,
                            amount: double.parse(amountController.text),
                            receivedBy: userName,
                            notes: 'Paid dues for ${liveInvoice.invoiceNumber}',
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Payment registered successfully!'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.danger,
                              ),
                            );
                          }
                        } finally {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Pay Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
