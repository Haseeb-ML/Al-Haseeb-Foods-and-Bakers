import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/supplier_model.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../services/supplier_service.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/accent_controller.dart';
import '../../theme/background_theme_controller.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/admin_header_actions.dart';

const double _kDesktopBreakpoint = 900;

class SupplierListScreen extends StatefulWidget {
  final UserModel? user;
  const SupplierListScreen({super.key, this.user});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final SupplierService _supplierService = SupplierService();
  final ProductService _productService = ProductService();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  //-------------------- ADD SUPPLIER DIALOG --------------------
  void _showAddSupplierDialog([SupplierModel? supplierToEdit]) {
    final formKey = GlobalKey<FormState>();
    final companyController = TextEditingController(text: supplierToEdit?.companyName ?? '');
    final contactController = TextEditingController(text: supplierToEdit?.contactPerson ?? '');
    final phoneController = TextEditingController(text: supplierToEdit?.phone ?? '');
    final addressController = TextEditingController(text: supplierToEdit?.address ?? '');
    final duesController = TextEditingController(
      text: supplierToEdit != null ? supplierToEdit.payableBalance.toStringAsFixed(0) : '0',
    );

    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final accent = accentController.value;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                supplierToEdit == null ? 'Add New Supplier' : 'Edit Supplier',
                style: TextStyle(fontWeight: FontWeight.bold, color: accent),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: companyController,
                        decoration: const InputDecoration(
                          labelText: 'Company / Business Name *',
                          prefixIcon: Icon(Icons.business_rounded),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: contactController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Contact Person Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Address / Location',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: duesController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Payable Balance / Dues (Rs.)',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isLoading = true);

                          final supplier = SupplierModel(
                            id: supplierToEdit?.id ?? '',
                            companyName: companyController.text.trim(),
                            contactPerson: contactController.text.trim(),
                            phone: phoneController.text.trim(),
                            address: addressController.text.trim(),
                            payableBalance: double.tryParse(duesController.text.trim()) ?? 0.0,
                            createdAt: supplierToEdit?.createdAt ?? DateTime.now(),
                          );

                          if (supplierToEdit == null) {
                            await _supplierService.addSupplier(supplier);
                          } else {
                            await _supplierService.updateSupplier(supplierToEdit.id, supplier);
                          }

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(supplierToEdit == null
                                  ? 'Supplier added successfully!'
                                  : 'Supplier updated!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(supplierToEdit == null ? 'Save Supplier' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //-------------------- STOCK-IN (PURCHASE ENTRY) DIALOG --------------------
  void _showStockInDialog(List<SupplierModel> suppliers, List<ProductModel> products, [SupplierModel? selectedSupplier]) {
    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add products first before recording Stock In.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    SupplierModel? chosenSupplier = selectedSupplier ?? (suppliers.isNotEmpty ? suppliers.first : null);
    ProductModel chosenProduct = products.first;
    final qtyController = TextEditingController(text: '10');
    final totalCostController = TextEditingController(text: (products.first.price * 10).toStringAsFixed(0));
    final paidAmountController = TextEditingController(text: '0');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        final accent = accentController.value;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: accent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'New Stock-In Entry',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Supplier:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<SupplierModel>(
                      value: chosenSupplier,
                      isExpanded: true,
                      items: suppliers.map((sup) {
                        return DropdownMenuItem(
                          value: sup,
                          child: SizedBox(
                            width: 180, // Hard limit to prevent popup intrinsic width overflow
                            child: Text(
                              sup.companyName,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setDialogState(() => chosenSupplier = val),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    const Text('Select Product to Add Stock:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<ProductModel>(
                      value: chosenProduct,
                      isExpanded: true,
                      items: products.map((prod) {
                        return DropdownMenuItem(
                          value: prod,
                          child: SizedBox(
                            width: 180, // Hard limit to prevent popup intrinsic width overflow
                            child: Text(
                              '${prod.name} (Current Stock: ${prod.stockQty})',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            chosenProduct = val;
                            final qty = int.tryParse(qtyController.text) ?? 10;
                            totalCostController.text = (val.price * qty).toStringAsFixed(0);
                          });
                        }
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Qty Received *',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (v) {
                              final qty = int.tryParse(v) ?? 0;
                              totalCostController.text = (chosenProduct.price * qty).toStringAsFixed(0);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: totalCostController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Total Cost (Rs.) *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: paidAmountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Amount Paid Now (Rs.)',
                        helperText: 'Remaining will be added to Supplier Dues',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: accent),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final qty = int.tryParse(qtyController.text.trim()) ?? 0;
                          final totalCost = double.tryParse(totalCostController.text.trim()) ?? 0.0;
                          final paidAmount = double.tryParse(paidAmountController.text.trim()) ?? 0.0;

                          if (qty <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter valid quantity.')),
                            );
                            return;
                          }

                          setDialogState(() => isLoading = true);

                          await _supplierService.recordStockPurchase(
                            supplierId: chosenSupplier?.id ?? '',
                            supplierName: chosenSupplier?.companyName ?? 'General Supplier',
                            items: [
                              {
                                'productId': chosenProduct.id,
                                'name': chosenProduct.name,
                                'qtyAdded': qty,
                                'costPrice': totalCost / qty,
                              }
                            ],
                            totalAmount: totalCost,
                            paidAmount: paidAmount,
                          );

                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Received +$qty units of ${chosenProduct.name}! Stock updated.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Receive Stock'),
                ),
              ],
            );
          },
        );
      },
    );
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

                final content = _buildSupplierContent(
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
                          currentRoute: 'Suppliers',
                          user: currentUser,
                        ),
                        Expanded(
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 24, // AppSpacing.lg equivalent
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
                  drawer: Drawer(
                    width: 230,
                    child: AdminSidebar(
                      currentRoute: 'Suppliers',
                      user: widget.user,
                    ),
                  ),

                  floatingActionButton: FloatingActionButton.extended(
                    backgroundColor: accent,
                    onPressed: () => _showAddSupplierDialog(),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add Supplier', style: TextStyle(color: Colors.white)),
                  ),
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0), // AppSpacing.sm equivalent is usually 16 or 12. Let's use 16
                      child: content,
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

  Widget _buildSupplierContent(
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
    return StreamBuilder<List<SupplierModel>>(
      stream: _supplierService.getSuppliers(),
      builder: (context, supplierSnapshot) {
        return StreamBuilder<List<ProductModel>>(
          stream: _productService.getProducts(),
          builder: (context, productSnapshot) {
            if (supplierSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: accent));
            }

            final allSuppliers = supplierSnapshot.data ?? [];
            final allProducts = productSnapshot.data ?? [];

            final filteredSuppliers = allSuppliers.where((sup) {
              final query = _searchQuery.toLowerCase();
              return sup.companyName.toLowerCase().contains(query) ||
                  sup.contactPerson.toLowerCase().contains(query) ||
                  sup.phone.contains(query);
            }).toList();

            final totalPayableDues = allSuppliers.fold<double>(
              0.0,
              (sum, sup) => sum + sup.payableBalance,
            );

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isDesktop) ...[
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
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Icon(Icons.menu, size: 20, color: textPrimary),
                            ),
                          ),
                        ),
                        const AdminHeaderActions(isDesktop: false),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  //-------------------- HEADER & ACTION BAR --------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Suppliers & Stock Procurement',
                              style: TextStyle(
                                fontSize: isDesktop ? 22 : 18,
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Manage vendor directory and record incoming stock orders',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (isDesktop) ...[
                        Row(
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accent,
                                side: BorderSide(color: accent),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              onPressed: () => _showStockInDialog(allSuppliers, allProducts),
                              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                              label: const Text('New Stock In', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: accent,
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              ),
                              onPressed: () => _showAddSupplierDialog(),
                              icon: const Icon(Icons.business_center_rounded, size: 18),
                              label: const Text('Add Supplier', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (isDesktop) AdminHeaderActions(isDesktop: isDesktop),
                    ],
                  ),
                  const SizedBox(height: 16),

                  //-------------------- STAT METRICS ROW --------------------
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Vendors', style: TextStyle(fontSize: 12, color: textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                '${allSuppliers.length}',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Supplier Dues', style: TextStyle(fontSize: 12, color: textSecondary)),
                              const SizedBox(height: 4),
                              Text(
                                'Rs. ${totalPayableDues.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.danger),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  //-------------------- SEARCH BAR --------------------
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search suppliers by company or phone...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      fillColor: card,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  //-------------------- SUPPLIERS GRID / LIST --------------------
                  if (filteredSuppliers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          _searchQuery.isEmpty ? 'No suppliers added yet. Click "Add Supplier"!' : 'No suppliers match search.',
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isDesktop ? 3 : 1,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: isDesktop ? 1.6 : 1.9,
                      ),
                      itemCount: filteredSuppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = filteredSuppliers[index];

                        return Container(
                          padding: const EdgeInsets.all(16),
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          supplier.companyName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          supplier.contactPerson.isEmpty ? 'Vendor' : supplier.contactPerson,
                                          style: TextStyle(fontSize: 12, color: textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'edit') {
                                        _showAddSupplierDialog(supplier);
                                      } else if (val == 'delete') {
                                        _supplierService.deleteSupplier(supplier.id);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit Vendor')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete Vendor', style: TextStyle(color: AppColors.danger))),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined, size: 14, color: textSecondary),
                                  const SizedBox(width: 6),
                                  Text(supplier.phone, style: TextStyle(fontSize: 12, color: textSecondary)),
                                ],
                              ),
                              Divider(color: border, height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Payable Dues:', style: TextStyle(fontSize: 10, color: textSecondary)),
                                      Text(
                                        'Rs. ${supplier.payableBalance.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: supplier.payableBalance > 0 ? AppColors.danger : const Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _showStockInDialog(allSuppliers, allProducts, supplier),
                                    icon: Icon(Icons.add_circle_outline, size: 16, color: accent),
                                    label: Text('Stock In', style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
