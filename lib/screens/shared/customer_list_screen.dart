import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/accent_controller.dart';
import '../../theme/background_theme_controller.dart';
import '../admin/product_list_screen.dart';
import '../staff/staff_product_list_screen.dart';
import '../admin/staff_management_screen.dart';
import '../admin/theme_settings_screen.dart';
import '../admin/backup_restore_screen.dart';
import '../shared/new_sale_screen.dart';
import 'expense_list_screen.dart';
import '../../models/user_model.dart';
import '../../widgets/staff_sidebar.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/admin_header_actions.dart';

//-------------------- DESKTOP BREAKPOINT --------------------
const double kDesktopBreakpoint = 900;

//-------------------- CUSTOMER LIST SCREEN --------------------
class CustomerListScreen extends StatefulWidget {
  final bool isAdmin;
  const CustomerListScreen({super.key, this.isAdmin = false});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  //-------------------- GET INITIALS FROM NAME --------------------
  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  //-------------------- AVATAR COLOR (Gold tints) --------------------
  Color _colorFor(String name) {
    final opacities = [0.12, 0.20, 0.28, 0.36, 0.44];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % opacities.length : 0;
    return accentController.value.withValues(alpha: opacities[index]);
  }

  //-------------------- ADD / EDIT CUSTOMER DIALOG --------------------
  void _showCustomerDialog({CustomerModel? existingCustomer}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: existingCustomer?.name ?? '',
    );
    final phoneController = TextEditingController(
      text: existingCustomer?.phone ?? '',
    );
    final addressController = TextEditingController(
      text: existingCustomer?.address ?? '',
    );
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              backgroundColor: isDark ? AppColors.darkBg : Colors.white,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: isDark
                        ? accentController.value.withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accentController.value,
                                Color.lerp(
                                  accentController.value,
                                  Colors.black,
                                  0.2,
                                )!,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            existingCustomer == null
                                ? Icons.person_add_alt_1
                                : Icons.edit_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            existingCustomer == null
                                ? 'Add Customer'
                                : 'Edit Customer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: accentController.value,
                              fontFamily: isDark ? 'PlayfairDisplay' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _DialogField(
                            controller: nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            isDark: isDark,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _DialogField(
                            controller: phoneController,
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            isDark: isDark,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _DialogField(
                            controller: addressController,
                            label: 'Address (optional)',
                            icon: Icons.location_on_outlined,
                            isDark: isDark,
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        if (existingCustomer != null && widget.isAdmin)
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _confirmDelete(existingCustomer);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.danger,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (existingCustomer != null && widget.isAdmin)
                          const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    setStateDialog(() => isLoading = true);

                                    final customer = CustomerModel(
                                      id: existingCustomer?.id ?? '',
                                      name: nameController.text.trim(),
                                      phone: phoneController.text.trim(),
                                      address: addressController.text.trim(),
                                      createdAt:
                                          existingCustomer?.createdAt ??
                                          DateTime.now(),
                                    );

                                    try {
                                      if (existingCustomer == null) {
                                        await _customerService.addCustomer(
                                          customer,
                                        );
                                      } else {
                                        await _customerService.updateCustomer(
                                          existingCustomer.id,
                                          customer,
                                        );
                                      }
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              existingCustomer == null
                                                  ? 'Customer added ✨'
                                                  : 'Customer updated ✨',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor:
                                                accentController.value,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setStateDialog(() => isLoading = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: AppColors.danger,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentController.value,
                                    Color.lerp(
                                      accentController.value,
                                      Colors.black,
                                      0.2,
                                    )!,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentController.value.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            existingCustomer == null
                                                ? Icons.add_circle_outline
                                                : Icons.update_outlined,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            existingCustomer == null
                                                ? 'Add'
                                                : 'Update',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  //-------------------- READ-ONLY DETAILS --------------------
  void _showReadOnlyDetails(CustomerModel customer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarBg = _colorFor(customer.name);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBg : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isDark
                  ? accentController.value.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentController.value.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _getInitials(customer.name),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: accentController.value,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      customer.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: accentController.value,
                        fontFamily: isDark ? 'PlayfairDisplay' : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? accentController.value.withValues(alpha: 0.08)
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: customer.phone,
                      isDark: isDark,
                    ),
                    if (customer.address.isNotEmpty) ...[
                      const Divider(height: 16),
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value: customer.address,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        if (StaffSidebar.adminPreviewMode) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Customer editing is disabled during Staff Inspection Mode.'),
                              backgroundColor: AppColors.danger,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        _showCustomerDialog(existingCustomer: customer);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentController.value,
                              Color.lerp(accentController.value, Colors.black, 0.2)!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: accentController.value.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Update',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  //-------------------- DELETE CONFIRMATION --------------------
  void _confirmDelete(CustomerModel customer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.danger,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Customer',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Delete "${customer.name}"? This cannot be undone.',
          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              await _customerService.deleteCustomer(customer.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  //-------------------- RECEIVE PAYMENT DIALOG (Point 5) --------------------
  void _showReceivePaymentDialog(CustomerModel customer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountController = TextEditingController(
      text: customer.balance > 0 ? customer.balance.toStringAsFixed(0) : '',
    );
    final notesController = TextEditingController();
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payments_outlined,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receive Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      customer.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Pending Balance:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Rs. ${customer.balance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: customer.balance > 0 ? AppColors.danger : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Amount Received (Rs.)',
                      prefixIcon: const Icon(Icons.money, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) {
                      final parsed = double.tryParse(v ?? '');
                      if (parsed == null || parsed <= 0) return 'Enter valid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Notes / Ref (optional)',
                      prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isLoading = true);
                      try {
                        final amt = double.parse(amountController.text.trim());
                        final user = AuthService().currentUser;
                        await _customerService.receivePayment(
                          customerId: customer.id,
                          amount: amt,
                          receivedBy: user?.displayName ?? user?.email ?? 'Staff',
                          notes: notesController.text.trim(),
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Payment of Rs. ${amt.toStringAsFixed(0)} received from ${customer.name}'),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
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
                final isDesktop = constraints.maxWidth >= kDesktopBreakpoint;

                if (isDesktop) {
                  return Scaffold(
                    backgroundColor: bg,
                    body: Row(
                      children: [
                        if (!widget.isAdmin)
                          StaffSidebar(
                            currentRoute: 'Customers',
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
                            currentRoute: 'Customers',
                          ),
                        Expanded(
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: AppSpacing.lg,
                              ),
                              child: _buildContent(
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

                return Scaffold(
                  backgroundColor: bg,
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: _buildContent(
                        context,
                        card,
                        border,
                        textPrimary,
                        textSecondary,
                        textMuted,
                        isDesktop: false,
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

  //==================== SHARED CONTENT ====================
  Widget _buildContent(
    BuildContext context,
    Color card,
    Color border,
    Color textPrimary,
    Color textSecondary,
    Color textMuted, {
    required bool isDesktop,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        //-------------------- HEADER --------------------
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!isDesktop)
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(
                      color: isDark
                          ? accentController.value.withValues(alpha: 0.2)
                          : border,
                      width: 0.8,
                    ),
                  ),
                  child: Icon(Icons.arrow_back, size: 18, color: textPrimary),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Directory',
                    style: TextStyle(
                      fontSize: 12,
                      color: accentController.value,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Customers',
                    style: TextStyle(
                      fontSize: isDesktop ? 26 : 19,
                      fontWeight: FontWeight.w600,
                      color: accentController.value,
                      fontFamily: isDark ? 'PlayfairDisplay' : null,
                    ),
                  ),
                ],
              ),
            ),
            if (!StaffSidebar.adminPreviewMode)
              GestureDetector(
                onTap: () => _showCustomerDialog(),
                child: Container(
                  height: 38,
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 0),
                  width: isDesktop ? null : 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentController.value,
                        Color.lerp(accentController.value, Colors.black, 0.2)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    boxShadow: [
                      BoxShadow(
                        color: accentController.value.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: isDesktop
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Add customer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            if (widget.isAdmin) ...[
              const SizedBox(width: 12),
              AdminHeaderActions(isDesktop: isDesktop),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        //-------------------- SEARCH BAR --------------------
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: isDark
                  ? accentController.value.withValues(alpha: 0.15)
                  : border,
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? accentController.value.withValues(alpha: 0.05)
                    : Colors.transparent,
                blurRadius: 10,
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name or phone...',
              hintStyle: TextStyle(color: textMuted, fontSize: 13),
              prefixIcon: Icon(
                Icons.search,
                color: accentController.value,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: Icon(Icons.close, color: textMuted, size: 18),
                    )
                  : null,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (value) =>
                setState(() => _searchQuery = value.toLowerCase()),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        //-------------------- SCROLLABLE CONTENT --------------------
        Expanded(
          child: StreamBuilder<List<CustomerModel>>(
            stream: _customerService.getCustomers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      accentController.value,
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: textSecondary),
                  ),
                );
              }

              final allCustomers = snapshot.data ?? [];

              final totalCustomers = allCustomers.length;
              final now = DateTime.now();
              final addedThisMonth = allCustomers
                  .where(
                    (c) =>
                        c.createdAt.year == now.year &&
                        c.createdAt.month == now.month,
                  )
                  .length;

              var customers = allCustomers;
              if (_searchQuery.isNotEmpty) {
                customers = customers
                    .where(
                      (c) =>
                          c.name.toLowerCase().contains(_searchQuery) ||
                          c.phone.contains(_searchQuery),
                    )
                    .toList();
              }

              final sorted = List<CustomerModel>.from(customers)
                ..sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    //-------------------- STAT CARDS ROW --------------------
                    Row(
                      children: [
                        Expanded(
                          child: _StatMiniCard(
                            label: 'Total customers',
                            value: '$totalCustomers',
                            icon: Icons.people_outline,
                            card: card,
                            border: border,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _StatMiniCard(
                            label: 'Added this month',
                            value: '$addedThisMonth',
                            icon: Icons.person_add_alt_1,
                            card: card,
                            border: border,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    //-------------------- TABLE HEADER (Desktop only) --------------------
                    if (isDesktop && customers.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.grey.shade100,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.card),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? accentController.value.withValues(
                                      alpha: 0.08,
                                    )
                                  : Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 44),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'CUSTOMER',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'PHONE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'ORDERS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'SPENT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),
                      ),

                    //-------------------- CUSTOMER LIST --------------------
                    if (customers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 48,
                                color: textMuted.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No customers found',
                                style: TextStyle(color: textMuted),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(
                              isDesktop ? AppRadius.card : 0,
                            ),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? accentController.value.withValues(
                                      alpha: 0.1,
                                    )
                                  : border,
                              width: 0.8,
                            ),
                            left: BorderSide(
                              color: isDark
                                  ? accentController.value.withValues(
                                      alpha: 0.1,
                                    )
                                  : border,
                              width: 0.8,
                            ),
                            right: BorderSide(
                              color: isDark
                                  ? accentController.value.withValues(
                                      alpha: 0.1,
                                    )
                                  : border,
                              width: 0.8,
                            ),
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
                          children: List.generate(customers.length, (index) {
                            final customer = customers[index];
                            final isLast = index == customers.length - 1;
                            final avatarBg = _colorFor(customer.name);
                            final orders = (index + 1) * 3;
                            final spent = (index + 1) * 1190.0;

                            return Column(
                              children: [
                                _CustomerTableRow(
                                  customer: customer,
                                  initials: _getInitials(customer.name),
                                  avatarBg: avatarBg,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  textMuted: textMuted,
                                  isDark: isDark,
                                  isDesktop: isDesktop,
                                  orders: orders,
                                  spent: spent,
                                  isAdmin: widget.isAdmin,
                                  onTap: () {
                                    _showReadOnlyDetails(customer);
                                  },
                                  onReceivePayment: () {
                                    if (StaffSidebar.adminPreviewMode) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                              'Payment actions are disabled during Staff Inspection Mode.'),
                                          backgroundColor: AppColors.danger,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }
                                    _showReceivePaymentDialog(customer);
                                  },
                                  onDelete: () {
                                    if (StaffSidebar.adminPreviewMode) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                              'Delete actions are disabled during Staff Inspection Mode.'),
                                          backgroundColor: AppColors.danger,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }
                                    _confirmDelete(customer);
                                  },
                                ),
                                if (!isLast)
                                  Divider(
                                    color: isDark
                                        ? accentController.value.withValues(
                                            alpha: 0.06,
                                          )
                                        : border,
                                    height: 0.8,
                                    indent: isDesktop ? 14 : 0,
                                    endIndent: isDesktop ? 14 : 0,
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
      ],
    );
  }
}

//-------------------- DESKTOP SIDEBAR --------------------
class _DesktopSidebar extends StatelessWidget {
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final bool isAdmin;
  final String selectedLabel;

  const _DesktopSidebar({
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.isAdmin,
    required this.selectedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentController.value,
                        Color.lerp(accentController.value, Colors.black, 0.2)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: accentController.value.withValues(alpha: 0.3),
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
                      color: accentController.value,
                      fontFamily: isDark ? 'PlayfairDisplay' : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            selected: selectedLabel == 'Dashboard',
            onTap: () => Navigator.pop(context),
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          _SidebarItem(
            icon: Icons.inventory_2_outlined,
            label: 'Products',
            selected: selectedLabel == 'Products',
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => isAdmin
                    ? const ProductListScreen()
                    : const StaffProductListScreen(),
              ),
            ),
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          _SidebarItem(
            icon: Icons.point_of_sale_outlined,
            label: 'New Sale',
            selected: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewSaleScreen(
                  currentUserUid: AuthService().currentUser?.uid ?? '',
                  isAdmin: isAdmin,
                ),
              ),
            ),
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          _SidebarItem(
            icon: Icons.people_outline,
            label: 'Customers',
            selected: selectedLabel == 'Customers',
            onTap: () {},
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          if (!isAdmin)
            _SidebarItem(
              icon: Icons.receipt_long_outlined,
              label: 'Expenses',
              selected: selectedLabel == 'Expenses',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ExpenseListScreen()),
              ),
              textSecondary: textSecondary,
              isDark: isDark,
            ),
          if (isAdmin)
            _SidebarItem(
              icon: Icons.badge_outlined,
              label: 'Staff',
              selected: selectedLabel == 'Staff',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const StaffManagementScreen(),
                ),
              ),
              textSecondary: textSecondary,
              isDark: isDark,
            ),

          if (isAdmin)
            _SidebarItem(
              icon: Icons.backup_outlined,
              label: 'Backup & Restore',
              selected: selectedLabel == 'Backup & Restore',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
              ),
              textSecondary: textSecondary,
              isDark: isDark,
            ),

          _SidebarItem(
            icon: Icons.palette_outlined,
            label: 'Appearance',
            selected: selectedLabel == 'Appearance',
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ThemeSettingsScreen(isAdmin: isAdmin),
              ),
            ),
            textSecondary: textSecondary,
            isDark: isDark,
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
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? accentController.value : textSecondary;

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

//-------------------- STAT MINI CARD WIDGET --------------------
class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _StatMiniCard({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? accentController.value.withValues(alpha: 0.08)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: accentController.value),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: accentController.value,
              fontFamily: isDark ? 'PlayfairDisplay' : null,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: textSecondary)),
        ],
      ),
    );
  }
}

//-------------------- CUSTOMER TABLE ROW WIDGET --------------------
class _CustomerTableRow extends StatelessWidget {
  final CustomerModel customer;
  final String initials;
  final Color avatarBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;
  final bool isDesktop;
  final int orders;
  final double spent;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onReceivePayment;
  final VoidCallback onDelete;

  const _CustomerTableRow({
    required this.customer,
    required this.initials,
    required this.avatarBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
    required this.isDesktop,
    required this.orders,
    required this.spent,
    required this.isAdmin,
    required this.onTap,
    required this.onReceivePayment,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasPending = customer.balance > 0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 14 : 12,
          vertical: isDesktop ? 14 : 12,
        ),
        child: isDesktop
            ? Row(
                children: [
                  //-------------------- AVATAR --------------------
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? accentController.value.withValues(alpha: 0.2)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: accentController.value,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  //-------------------- CUSTOMER INFO --------------------
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: accentController.value,
                            fontFamily: isDark ? 'PlayfairDisplay' : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer.phone,
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ),

                  //-------------------- PHONE --------------------
                  Expanded(
                    flex: 1,
                    child: Text(
                      customer.phone,
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                  ),

                  //-------------------- PENDING BALANCE --------------------
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasPending
                              ? 'Rs. ${customer.balance.toStringAsFixed(0)}'
                              : 'Clear',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: hasPending ? AppColors.danger : const Color(0xFF10B981),
                          ),
                        ),
                        Text(
                          hasPending ? 'Pending Dues' : 'No Balance',
                          style: TextStyle(fontSize: 10, color: textMuted),
                        ),
                      ],
                    ),
                  ),

                  //-------------------- RECEIVE PAYMENT BUTTON --------------------
                  IconButton(
                    tooltip: 'Receive Payment',
                    icon: const Icon(Icons.payments_outlined, color: Color(0xFF10B981), size: 20),
                    onPressed: onReceivePayment,
                  ),

                  IconButton(
                    tooltip: 'Delete Customer',
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                    onPressed: onDelete,
                  ),

                  //-------------------- ACTION ICON --------------------
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? accentController.value.withValues(alpha: 0.08)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isAdmin ? Icons.edit_outlined : Icons.visibility_outlined,
                      size: 16,
                      color: accentController.value,
                    ),
                  ),
                ],
              )
            : //-------------------- MOBILE ROW --------------------
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? accentController.value.withValues(alpha: 0.2)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: accentController.value,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: accentController.value,
                            fontFamily: isDark ? 'PlayfairDisplay' : null,
                          ),
                        ),
                        Text(
                          customer.phone,
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                        if (hasPending)
                          Text(
                            'Pending Dues: Rs. ${customer.balance.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Receive Payment',
                    icon: const Icon(Icons.payments_outlined, color: Color(0xFF10B981), size: 20),
                    onPressed: onReceivePayment,
                  ),
                  IconButton(
                    tooltip: 'Delete Customer',
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                    onPressed: onDelete,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? accentController.value.withValues(alpha: 0.08)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isAdmin ? Icons.edit_outlined : Icons.visibility_outlined,
                      size: 16,
                      color: accentController.value,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

//-------------------- DETAIL ROW WIDGET --------------------
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark
                ? accentController.value.withValues(alpha: 0.08)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: accentController.value),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

//-------------------- REUSABLE DIALOG TEXT FIELD --------------------
class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool isDark;
  final int maxLines;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: accentController.value,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, size: 18, color: accentController.value),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? AppColors.darkCard
            : Colors.grey.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? accentController.value.withValues(alpha: 0.15)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? accentController.value.withValues(alpha: 0.15)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentController.value, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
      ),
    );
  }
}
