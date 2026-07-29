import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/customer_model.dart';
import '../../models/product_model.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import '../../services/product_service.dart';
import 'customer_picker_screen.dart';
import '../../services/invoice_pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/accent_controller.dart';
import '../../theme/background_theme_controller.dart';
import '../admin/admin_dashboard.dart';
import '../staff/staff_dashboard.dart';
import '../../widgets/staff_sidebar.dart';
import '../../widgets/admin_sidebar.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/admin_header_actions.dart';

//-------------------- DESKTOP BREAKPOINT --------------------
const double _kDesktopBreakpoint = 900;

class NewSaleScreen extends StatefulWidget {
  final String currentUserUid;
  final bool isAdmin;
  const NewSaleScreen({
    super.key,
    required this.currentUserUid,
    this.isAdmin = false,
  });

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  final ProductService _productService = ProductService();

  late Stream<List<ProductModel>> _productsStream;
  CustomerModel? _selectedCustomer;
  final Map<String, ProductModel> _cartProducts = {};
  final Map<String, int> _cartQty = {};
  bool _isSaving = false;
  double _discount = 0.0;
  double _tax = 0.0;

  String _selectedCategory = 'All';
  String _productSearchQuery = '';
  bool _showCartView = false;

  @override
  void initState() {
    super.initState();
    _productsStream = _productService.getProducts();
  }

  //-------------------- SUBTOTAL & TOTAL AMOUNT --------------------
  double get _subTotal {
    double total = 0;
    _cartQty.forEach((productId, qty) {
      total += _cartProducts[productId]!.price * qty;
    });
    return total;
  }

  double get _totalAmount {
    return (_subTotal - _discount + _tax).clamp(0.0, double.infinity);
  }

  int get _totalItems => _cartQty.values.fold(0, (sum, q) => sum + q);

  //-------------------- SELECT CUSTOMER --------------------
  Future<void> _selectCustomer() async {
    final result = await Navigator.push<CustomerModel>(
      context,
      MaterialPageRoute(builder: (_) => const CustomerPickerScreen()),
    );
    if (result != null) {
      setState(() => _selectedCustomer = result);
    }
  }

  //-------------------- CHANGE QUANTITY --------------------
  void _changeQty(String productId, int delta) {
    setState(() {
      final product = _cartProducts[productId]!;
      final newQty = (_cartQty[productId] ?? 0) + delta;
      if (newQty <= 0) {
        _cartQty.remove(productId);
        _cartProducts.remove(productId);
      } else if (newQty <= product.stockQty) {
        _cartQty[productId] = newQty;
      }
    });
  }

  //-------------------- SAVE INVOICE --------------------
  Future<void> _saveInvoice({
    required double amountPaid,
    required double dueAmount,
    DateTime? dueDate,
  }) async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }
    if (_cartQty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final items = _cartQty.entries.map((entry) {
      final product = _cartProducts[entry.key]!;
      return InvoiceItem(
        productId: product.id,
        productName: product.name,
        quantity: entry.value,
        price: product.price,
        total: product.price * entry.value,
      );
    }).toList();

    try {
      final invoiceData = await _invoiceService.createInvoice(
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        items: items,
        createdBy: widget.currentUserUid,
        amountPaid: amountPaid,
        dueAmount: dueAmount,
        discount: _discount,
        tax: _tax,
        dueDate: dueDate,
      );
      final docId = invoiceData['id'] ?? '';
      final invoiceNumber = invoiceData['invoiceNumber'] ?? '';

      if (mounted) {
        final invoice = InvoiceModel(
          id: docId,
          invoiceNumber: invoiceNumber,
          customerId: _selectedCustomer!.id,
          customerName: _selectedCustomer!.name,
          items: items,
          totalAmount: _totalAmount,
          amountPaid: amountPaid,
          dueAmount: dueAmount,
          createdBy: widget.currentUserUid,
          date: DateTime.now(),
          discount: _discount,
          tax: _tax,
          dueDate: dueDate,
        );

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 10),
                Expanded(child: Text('Sale Completed')),
              ],
            ),
            content: Text(
              'Invoice $invoiceNumber saved successfully.\nTotal: Rs. ${_totalAmount.toStringAsFixed(0)}\nPaid: Rs. ${amountPaid.toStringAsFixed(0)}\nDues: Rs. ${dueAmount.toStringAsFixed(0)}',
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              _DialogActionButton(
                icon: Icons.visibility_outlined,
                label: 'View',
                onTap: () => InvoicePdfService().viewPdf(invoice),
              ),
              _DialogActionButton(
                icon: Icons.download_outlined,
                label: 'Download',
                onTap: () async {
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
                },
              ),
              _DialogActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () => InvoicePdfService().sharePdf(invoice),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                onPressed: () {
                  Navigator.pop(context); // Pop dialog
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context); // Pop NewSaleScreen
                  } else {
                    if (widget.isAdmin) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => AdminDashboard(
                            user: UserModel(
                              uid: widget.currentUserUid,
                              name: AuthService().currentUser?.displayName ?? 'Admin Owner',
                              email: AuthService().currentUser?.email ?? '',
                              role: 'admin',
                              phone: '',
                              createdAt: DateTime.now(),
                            ),
                          ),
                        ),
                      );
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => StaffDashboard(
                            user: UserModel(
                              uid: widget.currentUserUid,
                              name: AuthService().currentUser?.displayName ?? 'Staff',
                              email: AuthService().currentUser?.email ?? '',
                              role: 'staff',
                              phone: '',
                              createdAt: DateTime.now(),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }



  //-------------------- SHOW CHECKOUT PAYMENT DIALOG --------------------
  void _showCheckoutPaymentDialog() {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return;
    }
    if (_cartQty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product')),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final amountController = TextEditingController(text: _totalAmount.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();
    double cashReceived = _totalAmount;
    double dues = 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double changeAmount = (cashReceived - _totalAmount).clamp(0.0, double.infinity);
            dues = (_totalAmount - cashReceived).clamp(0.0, double.infinity);

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              backgroundColor: isDark ? AppColors.darkBg : Colors.white,
              title: const Row(
                children: [
                  Icon(Icons.payments_outlined, color: AppColors.success),
                  SizedBox(width: 10),
                  Text('Collect Payment'),
                ],
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Net Payable: Rs. ${_totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: const InputDecoration(
                        labelText: 'Cash Received (Rs.)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          cashReceived = double.tryParse(val) ?? 0.0;
                        });
                      },
                      validator: (value) {
                        final val = double.tryParse(value ?? '');
                        if (val == null || val < 0) {
                          return 'Enter valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Change to Return:', style: TextStyle(fontSize: 13)),
                        Text('Rs. ${changeAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Added to Dues:', style: TextStyle(fontSize: 13)),
                        Text(
                          'Rs. ${dues.toStringAsFixed(0)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: dues > 0 ? AppColors.danger : Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      _saveInvoice(
                        amountPaid: cashReceived.clamp(0.0, _totalAmount),
                        dueAmount: dues,
                      );
                    }
                  },
                  child: const Text('Confirm', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //==================== INTERACTIVE CATALOG PANEL ====================
  Widget _buildCatalogPanel(
    Color bg,
    Color card,
    Color border,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    bool isDark,
    bool isDesktop,
    Color accent,
  ) {
    final List<String> categories = ['All', ...kBakeryCategories];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 4,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: textSecondary),
                  filled: true,
                  fillColor: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: border),
                  ),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: StreamBuilder<List<ProductModel>>(
                stream: _productsStream,
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  return Autocomplete<ProductModel>(
                    displayStringForOption: (ProductModel option) => option.name,
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<ProductModel>.empty();
                      }
                      return list.where((ProductModel option) {
                        final matchesSearch = option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
                        final matchesCategory = _selectedCategory == 'All' || option.category == _selectedCategory;
                        return matchesSearch && matchesCategory;
                      });
                    },
                    onSelected: (ProductModel selection) {
                      final inCartQty = _cartQty[selection.id] ?? 0;
                      if (selection.stockQty <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${selection.name} is out of stock!'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }
                      if (inCartQty >= selection.stockQty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot add more. Stock limit reached!'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _cartProducts[selection.id] = selection;
                        _cartQty[selection.id] = inCartQty + 1;
                      });
                    },
                    fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        style: TextStyle(color: textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search/Select Dropdown...',
                          hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                          labelText: 'Search Product',
                          labelStyle: TextStyle(color: textSecondary),
                          prefixIcon: Icon(Icons.search, color: textSecondary, size: 18),
                          suffixIcon: Icon(Icons.arrow_drop_down, color: textSecondary),
                          filled: true,
                          fillColor: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: border),
                          ),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(10),
                          color: isDark ? AppColors.darkCard : Colors.white,
                          child: Container(
                            width: 320,
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              border: Border.all(color: border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                          itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border(bottom: BorderSide(color: border, width: 0.5)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            option.name,
                                            style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        Text(
                                          'Rs. ${option.price.toStringAsFixed(0)}',
                                          style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: _productsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = snapshot.data ?? [];
              var filtered = products;

              if (_selectedCategory != 'All') {
                filtered = filtered.where((p) => p.category == _selectedCategory).toList();
              }

              if (_productSearchQuery.isNotEmpty) {
                filtered = filtered
                    .where((p) => p.name.toLowerCase().contains(_productSearchQuery))
                    .toList();
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    'No products found in this category.',
                    style: TextStyle(color: textSecondary),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.only(bottom: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isDesktop ? 3 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final p = filtered[index];
                  final isLow = p.isLowStock;
                  final inCartQty = _cartQty[p.id] ?? 0;

                  return GestureDetector(
                    onTap: () {
                      if (p.stockQty <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${p.name} is out of stock!'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }
                      if (inCartQty >= p.stockQty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot add more. Stock limit reached!'),
                            backgroundColor: AppColors.danger,
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _cartProducts[p.id] = p;
                        _cartQty[p.id] = inCartQty + 1;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: inCartQty > 0 ? accent : border,
                          width: inCartQty > 0 ? 1.5 : 0.8,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                p.imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: p.imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: bgFor(textMuted),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 1.5),
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: bgFor(textMuted),
                                          child: Icon(Icons.bakery_dining_outlined, color: textSecondary, size: 28),
                                        ),
                                      )
                                    : Container(
                                        color: bgFor(textMuted),
                                        child: Icon(Icons.bakery_dining_outlined, color: textSecondary, size: 28),
                                      ),
                                if (isLow || p.stockQty == 0)
                                  Positioned(
                                    top: 6,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: p.stockQty == 0 ? AppColors.danger : Colors.orange,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        p.stockQty == 0 ? 'Out of Stock' : 'Low Stock',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (inCartQty > 0)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: accent,
                                      child: Text(
                                        '$inCartQty',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rs. ${p.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: accent,
                                      ),
                                    ),
                                    Text(
                                      'Stock: ${p.stockQty}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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
    Color textMuted,
    bool isDesktop,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;

    // Cart list items widget
    Widget cartListWidget = _cartQty.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_basket_outlined, size: 48, color: textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                Text('Cart is empty', style: TextStyle(color: textSecondary, fontSize: 13)),
              ],
            ),
          )
        : ListView.builder(
            itemCount: _cartQty.length,
            itemBuilder: (context, index) {
              final productId = _cartQty.keys.elementAt(index);
              final product = _cartProducts[productId]!;
              final qty = _cartQty[productId]!;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rs. ${product.price.toStringAsFixed(0)} each',
                            style: TextStyle(color: textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 18),
                          onPressed: () => _changeQty(productId, -1),
                        ),
                        Text(
                          '$qty',
                          style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          onPressed: () => _changeQty(productId, 1),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );

    // Customer details & Invoice Summary checkout block
    Widget checkoutSummaryPanel = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _selectCustomer,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: border, width: 0.8),
            ),
            child: Row(
              children: [
                Icon(Icons.person_outline, color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedCustomer == null ? 'Select Customer' : _selectedCustomer!.name,
                    style: TextStyle(
                      color: _selectedCustomer == null ? textSecondary : textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: textSecondary, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Quick Discount:',
          style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [5, 10, 15, 20].map((pct) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _discount = _subTotal * (pct / 100);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: border),
                    ),
                    child: Text(
                      '$pct%',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accent),
                    ),
                  ),
                ),
              ),
            );
          }).toList() +
              [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _discount = 0.0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: const Text(
                        'Clear',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.danger),
                      ),
                    ),
                  ),
                )
              ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add Packaging Fee (Rs. 50):',
              style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.bold),
            ),
            Switch(
              value: _tax == 50.0,
              activeColor: accent,
              onChanged: (val) {
                setState(() {
                  _tax = val ? 50.0 : 0.0;
                });
              },
            ),
          ],
        ),
        const Divider(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Subtotal', style: TextStyle(color: textSecondary, fontSize: 13)),
            Text('Rs. ${_subTotal.toStringAsFixed(0)}', style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        if (_discount > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Discount', style: TextStyle(color: textSecondary, fontSize: 13)),
              Text('- Rs. ${_discount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
        ],
        if (_tax > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Packaging / Extra Fee', style: TextStyle(color: textSecondary, fontSize: 13)),
              Text('+ Rs. ${_tax.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Payable', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            Text('Rs. ${_totalAmount.toStringAsFixed(0)}', style: TextStyle(color: accent, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _isSaving ? null : _showCheckoutPaymentDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save & Pay Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.sm,
            isDesktop ? 14 : AppSpacing.xs,
            AppSpacing.sm,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
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
                          border: Border.all(color: border, width: 0.8),
                        ),
                        child: Icon(Icons.arrow_back, size: 18, color: textPrimary),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Point of Sale',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'New Sale',
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isDesktop)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showCartView = !_showCartView;
                        });
                      },
                      icon: Icon(_showCartView ? Icons.menu_book : Icons.shopping_cart, size: 18, color: accent),
                      label: Text(
                        _showCartView ? 'Show Menu' : 'View Cart (${_totalItems})',
                        style: TextStyle(color: accent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  StreamBuilder<UserModel?>(
                    stream: AuthService().getUserStream(widget.currentUserUid),
                    builder: (context, userSnap) {
                      final liveUser = userSnap.data;
                      if (liveUser != null && liveUser.role == 'admin') {
                        return Padding(
                          padding: const EdgeInsets.only(left: 12.0),
                          child: AdminHeaderActions(isDesktop: isDesktop),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isDesktop)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: border, width: 0.8),
                      ),
                      child: _buildCatalogPanel(bg, card, border, textPrimary, textSecondary, textMuted, isDark, true, accent),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: card,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(color: border, width: 0.8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Product Cart (${_totalItems} items)',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                                    ),
                                    if (_cartQty.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.danger),
                                        onPressed: () {
                                          setState(() {
                                            _cartQty.clear();
                                            _cartProducts.clear();
                                            _selectedCustomer = null;
                                            _discount = 0.0;
                                            _tax = 0.0;
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                const Divider(),
                                Expanded(child: cartListWidget),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: card,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(color: border, width: 0.8),
                          ),
                          child: checkoutSummaryPanel,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
              child: _showCartView
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: border, width: 0.8),
                      ),
                      child: Column(
                        children: [
                          Expanded(child: cartListWidget),
                          const Divider(height: 20),
                          checkoutSummaryPanel,
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: card,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: border, width: 0.8),
                      ),
                      child: _buildCatalogPanel(bg, card, border, textPrimary, textSecondary, textMuted, isDark, false, accent),
                    ),
            ),
          ),
      ],
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
                final isDesktop = constraints.maxWidth >= _kDesktopBreakpoint;

                final content = _buildContent(
                  context,
                  accent,
                  card,
                  border,
                  textPrimary,
                  textSecondary,
                  textMuted,
                  isDesktop,
                );

                if (isDesktop) {
                  return Scaffold(
                    backgroundColor: bg,
                    body: Row(
                      children: [
                        if (!widget.isAdmin)
                          StaffSidebar(
                            currentRoute: 'New Sale',
                            user: UserModel(
                              uid: widget.currentUserUid,
                              name: AuthService().currentUser?.displayName ?? 'Staff',
                              email: AuthService().currentUser?.email ?? '',
                              role: 'staff',
                              phone: '',
                              createdAt: DateTime.now(),
                            ),
                          )
                        else
                          const AdminSidebar(
                            currentRoute: 'New Sale',
                          ),
                        Expanded(
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 24,
                                right: 24,
                                top: 0,
                                bottom: 0,
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
                  body: SafeArea(
                    child: content,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Color bgFor(Color textMuted) => textMuted.withValues(alpha: 0.08);
}



class _DialogActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DialogActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: accentController.value),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: accentController.value),
            ),
          ],
        ),
      ),
    );
  }
}
