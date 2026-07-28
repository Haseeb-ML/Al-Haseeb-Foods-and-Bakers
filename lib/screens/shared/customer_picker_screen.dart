import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../services/customer_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/accent_controller.dart';
import '../../theme/background_theme_controller.dart';
import '../../widgets/staff_sidebar.dart';
import '../../widgets/admin_sidebar.dart';

const double kDesktopBreakpoint = 900;

class CustomerPickerScreen extends StatefulWidget {
  final bool isAdmin;
  const CustomerPickerScreen({super.key, this.isAdmin = false});

  @override
  State<CustomerPickerScreen> createState() => _CustomerPickerScreenState();
}

class _CustomerPickerScreenState extends State<CustomerPickerScreen> {
  final CustomerService _customerService = CustomerService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  void _showAddCustomerDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              backgroundColor: isDark ? AppColors.darkBg : Colors.white,
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentController.value.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.person_add_alt_1, color: accentController.value, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Quick Add Customer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Customer Full Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Name required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Phone required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: addressController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Address (Optional)',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: accentController.value,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) return;
                                      setDialogState(() => isLoading = true);
                                      try {
                                        final newCust = CustomerModel(
                                          id: '',
                                          name: nameController.text.trim(),
                                          phone: phoneController.text.trim(),
                                          address: addressController.text.trim(),
                                          balance: 0.0,
                                          createdAt: DateTime.now(),
                                        );
                                        await _customerService.addCustomer(newCust);
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Customer "${newCust.name}" added successfully'),
                                              backgroundColor: const Color(0xFF10B981),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        setDialogState(() => isLoading = false);
                                      }
                                    },
                              child: isLoading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Add Customer'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

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

                final content = _buildPickerContent(
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
                  return StreamBuilder<UserModel?>(
                    stream: AuthService().getUserStream(AuthService().currentUser?.uid ?? ''),
                    builder: (context, userSnap) {
                      final currentUser = userSnap.data;
                      final isAdmin = widget.isAdmin || (currentUser?.isAdmin ?? false);

                      return Scaffold(
                        backgroundColor: bg,
                        body: Row(
                          children: [
                            isAdmin
                                ? const AdminSidebar(currentRoute: 'New Sale')
                                : StaffSidebar(
                                    currentRoute: 'New Sale',
                                    user: currentUser ??
                                        UserModel(
                                          uid: AuthService().currentUser?.uid ?? '',
                                          name: AuthService().currentUser?.displayName ?? 'Staff',
                                          email: AuthService().currentUser?.email ?? '',
                                          role: 'staff',
                                          phone: '',
                                          createdAt: DateTime.now(),
                                        ),
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
                  appBar: AppBar(
                    backgroundColor: card,
                    elevation: 0,
                    foregroundColor: textPrimary,
                    title: Row(
                      children: [
                        Icon(Icons.people_outline_rounded, color: accent, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Select Customer for Sale',
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
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

  Widget _buildPickerContent(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //-------------------- HEADER & SEARCH CARD --------------------
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.person_search_outlined, color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'POS Customer Selector',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Pick a customer to link with this POS sale invoice',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddCustomerDialog,
                    icon: const Icon(Icons.person_add_rounded, size: 16),
                    label: const Text('Add Customer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.2),
                    width: 0.8,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search customer by name or phone number...',
                    hintStyle: TextStyle(color: textMuted, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: accent, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, color: textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        //-------------------- REALTIME STREAM CUSTOMERS LIST --------------------
        Expanded(
          child: StreamBuilder<List<CustomerModel>>(
            stream: _customerService.getCustomers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: accent),
                );
              }

              final allCustomers = snapshot.data ?? [];
              final filterOptions = ['All', 'Has Dues', 'Clear Dues'];

              // Filter logic
              var customers = allCustomers;
              if (_selectedFilter == 'Has Dues') {
                customers = customers.where((c) => c.balance > 0).toList();
              } else if (_selectedFilter == 'Clear Dues') {
                customers = customers.where((c) => c.balance <= 0).toList();
              }

              if (_searchQuery.isNotEmpty) {
                customers = customers
                    .where((c) => c.name.toLowerCase().contains(_searchQuery) || c.phone.contains(_searchQuery))
                    .toList();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Chips Row
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filterOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final filter = filterOptions[index];
                        final isSelected = _selectedFilter == filter;

                        return ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedFilter = filter);
                          },
                          selectedColor: accent,
                          backgroundColor: card,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? accent : border,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Results count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '${customers.length} customers listed',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Empty State
                  if (customers.isEmpty)
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_off_outlined,
                                size: 48,
                                color: textMuted.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No matching customers found.',
                                style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _showAddCustomerDialog,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add New Customer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: isDesktop
                          ? GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                childAspectRatio: 1.15,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: customers.length,
                              itemBuilder: (context, index) {
                                final customer = customers[index];
                                return _CustomerGridCard(
                                  customer: customer,
                                  initials: _getInitials(customer.name),
                                  card: card,
                                  border: border,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  textMuted: textMuted,
                                  accent: accent,
                                  onSelect: () => Navigator.pop(context, customer),
                                );
                              },
                            )
                          : ListView.builder(
                              itemCount: customers.length,
                              itemBuilder: (context, index) {
                                final customer = customers[index];
                                return _CustomerTileItem(
                                  customer: customer,
                                  initials: _getInitials(customer.name),
                                  card: card,
                                  border: border,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  textMuted: textMuted,
                                  accent: accent,
                                  onSelect: () => Navigator.pop(context, customer),
                                );
                              },
                            ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CustomerGridCard extends StatelessWidget {
  final CustomerModel customer;
  final String initials;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final VoidCallback onSelect;

  const _CustomerGridCard({
    required this.customer,
    required this.initials,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final hasDues = customer.balance > 0;
    final statusColor = hasDues ? AppColors.danger : const Color(0xFF10B981);

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasDues ? AppColors.danger.withValues(alpha: 0.35) : border,
          width: hasDues ? 1.0 : 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Initials Avatar
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                    border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.2),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: accent,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                // Name & Phone
                Column(
                  children: [
                    Text(
                      customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.phone.isNotEmpty ? customer.phone : 'No phone',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),

                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 0.8),
                  ),
                  child: Text(
                    hasDues ? 'Dues: Rs. ${customer.balance.toStringAsFixed(0)}' : 'Clear Dues',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
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

class _CustomerTileItem extends StatelessWidget {
  final CustomerModel customer;
  final String initials;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final VoidCallback onSelect;

  const _CustomerTileItem({
    required this.customer,
    required this.initials,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final hasDues = customer.balance > 0;
    final statusColor = hasDues ? AppColors.danger : const Color(0xFF10B981);

    return Card(
      color: card,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: border, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: onSelect,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.12),
            border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.2),
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: accent,
                fontSize: 15,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              customer.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.verified_rounded, size: 14, color: accent),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              customer.phone,
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                hasDues
                    ? 'Pending Dues: Rs. ${customer.balance.toStringAsFixed(0)}'
                    : 'Clear Account Balance',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
