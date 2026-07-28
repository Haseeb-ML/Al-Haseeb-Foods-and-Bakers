import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../theme/accent_controller.dart';
import '../../theme/background_theme_controller.dart';
import 'staff_management_screen.dart';
import '../shared/customer_list_screen.dart';
import 'theme_settings_screen.dart';
import 'backup_restore_screen.dart';
import '../../widgets/admin_sidebar.dart';

//-------------------- DESKTOP BREAKPOINT --------------------
const double kDesktopBreakpoint = 900;

//-------------------- ADD / EDIT PRODUCT SCREEN --------------------
class AddEditProductScreen extends StatefulWidget {
  final ProductModel? existingProduct;
  const AddEditProductScreen({super.key, this.existingProduct});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();

  late TextEditingController _nameController;
  late TextEditingController _imageUrlController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;

  String _selectedCategory = 'Cakes & Sweets';

  bool _isLoading = false;
  bool get _isEditMode => widget.existingProduct != null;

  //-------------------- INIT CONTROLLERS --------------------
  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    _nameController = TextEditingController(text: p?.name ?? '');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
    _priceController = TextEditingController(text: p?.price.toString() ?? '');
    _stockController = TextEditingController(
      text: p?.stockQty.toString() ?? '',
    );
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _selectedCategory = p?.category ?? 'Cakes & Sweets';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  //-------------------- SAVE PRODUCT --------------------
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final product = ProductModel(
      id: widget.existingProduct?.id ?? '',
      name: _nameController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      stockQty: int.parse(_stockController.text.trim()),
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
      createdAt: widget.existingProduct?.createdAt ?? DateTime.now(),
    );

    try {
      if (_isEditMode) {
        await _productService.updateProduct(
          widget.existingProduct!.id,
          product,
        );
      } else {
        await _productService.addProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Product updated successfully ✨'
                  : 'Product added successfully ✨',
            ),
            backgroundColor: accentController.value,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //-------------------- INPUT FIELD STYLING (Premium) --------------------
  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    required Color textMuted,
    required Color card,
    required Color border,
    required bool isDark,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(prefixIcon, size: 20, color: accentController.value),
      labelStyle: TextStyle(
        color: isDark ? accentController.value : textMuted,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: TextStyle(
        color: accentController.value,
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? accentController.value.withValues(alpha: 0.1) : border,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? accentController.value.withValues(alpha: 0.1) : border,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: accentController.value, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
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

                final content = _buildContent(
                  context,
                  bg,
                  card,
                  border,
                  textPrimary,
                  textSecondary,
                  textMuted,
                  isDark,
                  isDesktop,
                );

                if (isDesktop) {
                  return Scaffold(
                    backgroundColor: bg,
                    body: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminSidebar(currentRoute: 'Products'),
                        Expanded(
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: AppSpacing.lg,
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
                    foregroundColor: textPrimary,
                    title: Text(
                      _isEditMode ? 'Edit Product' : 'Add Product',
                      style: TextStyle(
                        color: isDark ? accentController.value : textPrimary,
                        fontFamily: isDark ? 'PlayfairDisplay' : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    centerTitle: true,
                  ),
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
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

  //-------------------- SHARED CONTENT --------------------
  Widget _buildContent(
    BuildContext context,
    Color bg,
    Color card,
    Color border,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    bool isDark,
    bool isDesktop,
  ) {
    // Left column: Image preview
    final imagePreviewSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PRODUCT PHOTO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? accentController.value.withValues(alpha: 0.15) : border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentController.value.withValues(alpha: 0.4),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentController.value.withValues(alpha: 0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _imageUrlController.text.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: _imageUrlController.text,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => Icon(
                                Icons.image_outlined,
                                size: 60,
                                color: textSecondary.withValues(alpha: 0.5),
                              ),
                            )
                          : Container(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 60,
                                color: textSecondary.withValues(alpha: 0.5),
                              ),
                            ),
                    ),
                  ),
                  if (_imageUrlController.text.isNotEmpty)
                    Positioned(
                      bottom: 8,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _imageUrlController,
                style: TextStyle(color: textPrimary),
                decoration: _buildInputDecoration(
                  labelText: 'Image URL',
                  prefixIcon: Icons.link_outlined,
                  textMuted: textMuted,
                  card: bg,
                  border: border,
                  isDark: isDark,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
      ],
    );

    final formSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'PRODUCT DETAILS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? accentController.value.withValues(alpha: 0.15) : border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: _buildInputDecoration(
                    labelText: 'Product Name',
                    prefixIcon: Icons.inventory_2_outlined,
                    textMuted: textMuted,
                    card: bg,
                    border: border,
                    isDark: isDark,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                  dropdownColor: card,
                  decoration: _buildInputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icons.category_outlined,
                    textMuted: textMuted,
                    card: bg,
                    border: border,
                    isDark: isDark,
                  ),
                  items: kBakeryCategories.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
                        decoration: _buildInputDecoration(
                          labelText: 'Price (Rs.)',
                          prefixIcon: Icons.attach_money,
                          textMuted: textMuted,
                          card: bg,
                          border: border,
                          isDark: isDark,
                        ),
                        validator: (value) => (value == null || double.tryParse(value) == null) ? 'Invalid' : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
                        decoration: _buildInputDecoration(
                          labelText: 'Stock Qty',
                          prefixIcon: Icons.numbers,
                          textMuted: textMuted,
                          card: bg,
                          border: border,
                          isDark: isDark,
                        ),
                        validator: (value) => (value == null || int.tryParse(value) == null) ? 'Invalid' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: TextStyle(color: textPrimary, fontSize: 16),
                  decoration: _buildInputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icons.description_outlined,
                    textMuted: textMuted,
                    card: bg,
                    border: border,
                    isDark: isDark,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    minimumSize: const Size(0, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: EdgeInsets.zero,
                    elevation: 0,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accentController.value, Color.lerp(accentController.value, Colors.black, 0.2)!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: accentController.value.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isEditMode ? Icons.update_outlined : Icons.add_circle_outline,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isEditMode ? 'Update Product' : 'Add Product',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //-------------------- HEADER WITH BACK BUTTON --------------------
          if (isDesktop)
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    margin: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border, width: 1),
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      size: 20,
                      color: isDark ? accentController.value : textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditMode ? 'Edit Product' : 'Add Product',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          fontFamily: isDark ? 'PlayfairDisplay' : null,
                        ),
                      ),
                      Text(
                        _isEditMode ? 'Update your product details' : 'Create a new product',
                        style: TextStyle(fontSize: 14, color: textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (!isDesktop) const SizedBox(height: AppSpacing.sm),
          const SizedBox(height: 32),

          //-------------------- TWO-COLUMN LAYOUT --------------------
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: imagePreviewSection),
                const SizedBox(width: 32),
                Expanded(flex: 7, child: formSection),
              ],
            )
          else
            Column(
              children: [
                imagePreviewSection,
                const SizedBox(height: 24),
                formSection,
              ],
            ),
        ],
      ),
    );
  }
}

//-------------------- DESKTOP SIDEBAR (Matching Product List) --------------------
class _DesktopSidebar extends StatelessWidget {
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final String selectedLabel;

  const _DesktopSidebar({
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
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
          //-------------------- LOGO WITH GOLD ACCENT --------------------
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
                      color: isDark ? accentController.value : textPrimary,
                      fontFamily: isDark ? 'PlayfairDisplay' : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          //-------------------- NAV ITEMS --------------------
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
            onTap: () {},
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          _SidebarItem(
            icon: Icons.people_outline,
            label: 'Customers',
            selected: selectedLabel == 'Customers',
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomerListScreen(isAdmin: true),
              ),
            ),
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          _SidebarItem(
            icon: Icons.badge_outlined,
            label: 'Staff',
            selected: selectedLabel == 'Staff',
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StaffManagementScreen()),
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
              MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
            ),
            textSecondary: textSecondary,
            isDark: isDark,
          ),
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

          const Spacer(),
        ],
      ),
    );
  }
}

//-------------------- SIDEBAR NAV ITEM (Premium) --------------------
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
          color: selected ? accentController.value.withValues(alpha: 0.12) : null,
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
