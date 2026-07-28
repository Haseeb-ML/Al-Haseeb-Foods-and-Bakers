import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product_model.dart';
import '../../models/user_model.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/accent_controller.dart';
import '../../theme/background_theme_controller.dart';
import '../../widgets/staff_sidebar.dart';
import '../../widgets/admin_sidebar.dart';

const double kDesktopBreakpoint = 900;

class ProductPickerScreen extends StatefulWidget {
  final bool isAdmin;
  const ProductPickerScreen({super.key, this.isAdmin = false});

  @override
  State<ProductPickerScreen> createState() => _ProductPickerScreenState();
}

class _ProductPickerScreenState extends State<ProductPickerScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                        Icon(Icons.add_shopping_cart, color: accent, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Select Product for Sale',
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
        //-------------------- HEADER & SEARCH --------------------
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
                    child: Icon(Icons.inventory_2_outlined, color: accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'POS Product Picker',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Tap any item to add it directly to current sale cart',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                        ),
                      ],
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
                    hintText: 'Search product by name or barcode...',
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

        //-------------------- REALTIME STREAM PRODUCT CATALOG --------------------
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: _productService.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: accent),
                );
              }

              final allProducts = snapshot.data ?? [];

              final filterOptions = ['All', ...kBakeryCategories];

              // Filter products
              var products = allProducts;
              if (_selectedCategory != 'All') {
                products = products.where((p) => p.category == _selectedCategory).toList();
              }

              if (_searchQuery.isNotEmpty) {
                products = products.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories Pills Row
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: filterOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = filterOptions[index];
                        final isSelected = _selectedCategory == cat;

                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCategory = cat);
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
                      '${products.length} products available',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Empty State
                  if (products.isEmpty)
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
                                Icons.search_off_rounded,
                                size: 48,
                                color: textMuted.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No matching products found.',
                                style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try searching with a different term or category filter.',
                                style: TextStyle(color: textMuted, fontSize: 12),
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
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return _ProductGridCard(
                                  product: product,
                                  card: card,
                                  border: border,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  textMuted: textMuted,
                                  accent: accent,
                                  onSelect: () => Navigator.pop(context, product),
                                );
                              },
                            )
                          : ListView.builder(
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return _ProductTileItem(
                                  product: product,
                                  card: card,
                                  border: border,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  textMuted: textMuted,
                                  accent: accent,
                                  onSelect: () => Navigator.pop(context, product),
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

class _ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final VoidCallback onSelect;

  const _ProductGridCard({
    required this.product,
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
    final isOutOfStock = product.stockQty <= 0;

    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOutOfStock ? AppColors.danger.withValues(alpha: 0.35) : border,
          width: isOutOfStock ? 1.0 : 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isOutOfStock ? null : onSelect,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Prominent Product Image Banner
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: accent.withValues(alpha: 0.08),
                              child: const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            color: accent.withValues(alpha: 0.12),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: accent,
                              size: 34,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),

                // Name & Price
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isOutOfStock ? textMuted : textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rs. ${product.price.toStringAsFixed(0)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isOutOfStock ? textMuted : accent,
                  ),
                ),
                const SizedBox(height: 6),

                // Stock Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? AppColors.danger.withValues(alpha: 0.12)
                          : const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOutOfStock ? 'Out of Stock' : '${product.stockQty} in stock',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isOutOfStock ? AppColors.danger : const Color(0xFF10B981),
                      ),
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

class _ProductTileItem extends StatelessWidget {
  final ProductModel product;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final VoidCallback onSelect;

  const _ProductTileItem({
    required this.product,
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
    final isOutOfStock = product.stockQty <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Material(
        color: card,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
        enabled: !isOutOfStock,
        onTap: onSelect,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: product.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 48,
                  height: 48,
                  color: accent.withValues(alpha: 0.12),
                  child: Icon(Icons.inventory_2_outlined, color: accent, size: 22),
                ),
        ),
        title: Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isOutOfStock ? textMuted : textPrimary,
          ),
        ),
        subtitle: Text(
          isOutOfStock
              ? 'Out of stock'
              : 'Rs. ${product.price.toStringAsFixed(0)} • ${product.stockQty} in stock',
          style: TextStyle(
            fontSize: 12,
            color: isOutOfStock ? AppColors.danger : textSecondary,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOutOfStock ? textMuted.withValues(alpha: 0.12) : accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: 14,
                color: isOutOfStock ? textMuted : accent,
              ),
              const SizedBox(width: 4),
              Text(
                'Select',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isOutOfStock ? textMuted : accent,
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
