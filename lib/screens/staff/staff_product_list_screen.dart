import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../shared/product_details_screen.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../theme/accent_controller.dart';
import '../../theme/background_theme_controller.dart';
import '../admin/theme_settings_screen.dart';
import '../shared/customer_list_screen.dart';
import '../shared/new_sale_screen.dart';
import '../shared/expense_list_screen.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../widgets/staff_sidebar.dart';

//-------------------- DESKTOP BREAKPOINT --------------------
const double kDesktopBreakpoint = 900;

//-------------------- PRODUCT LIST SCREEN (STAFF - VIEW ONLY) --------------------
class StaffProductListScreen extends StatefulWidget {
  const StaffProductListScreen({super.key});

  @override
  State<StaffProductListScreen> createState() => _StaffProductListScreenState();
}

class _StaffProductListScreenState extends State<StaffProductListScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                      children: [
                        StaffSidebar(
                          currentRoute: 'Products',
                          user: UserModel(
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
                                vertical: 0,
                              ),
                              child: content,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                //-------------------- MOBILE LAYOUT --------------------
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
    return Column(
      children: [
        //-------------------- FIXED HEADER --------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              //-------------------- BACK BUTTON + TITLE --------------------
              Row(
                children: [
                  if (!isDesktop)
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
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
                        child: Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  if (!isDesktop) const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inventory',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? accentController.value
                                : textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Products',
                          style: TextStyle(
                            fontSize: isDesktop ? 26 : 20,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? accentController.value
                                : textPrimary,
                            fontFamily: isDark ? 'PlayfairDisplay' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                    hintText: 'Search product...',
                    hintStyle: TextStyle(color: textMuted, fontSize: 13),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark ? accentController.value : textMuted,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(
                              Icons.close,
                              color: textMuted,
                              size: 18,
                            ),
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
            ],
          ),
        ),

        //-------------------- SCROLLABLE STATS + PRODUCT LIST --------------------
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: _productService.getProducts(),
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

              final allProducts = snapshot.data ?? [];

              final totalItems = allProducts.length;
              final lowStockCount = allProducts
                  .where((p) => p.isLowStock)
                  .length;

              var products = allProducts;
              if (_searchQuery.isNotEmpty) {
                products = products
                    .where((p) => p.name.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    //-------------------- STAT CARDS ROW --------------------
                    Row(
                      children: [
                        Expanded(
                          child: _StatMiniCard(
                            label: 'Total items',
                            value: '$totalItems',
                            icon: Icons.inventory_2_outlined,
                            color: accentController.value,
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
                            label: 'Low stock',
                            value: '$lowStockCount',
                            icon: Icons.warning_amber_rounded,
                            color: lowStockCount > 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF22C55E),
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

                    //-------------------- SECTION LABEL --------------------
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 14,
                          color: isDark
                              ? accentController.value
                              : textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ALL PRODUCTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? accentController.value
                                : textSecondary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    //-------------------- PRODUCT LIST CARD --------------------
                    if (products.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: textMuted.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No products found',
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
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: LayoutBuilder(
                            builder: (context, constr) {
                              // Decide columns responsively based on target card width, but cap at 5
                              final width = constr.maxWidth;
                              // target card width ~220px including spacing
                              var desired = (width / 220).floor();
                              if (desired < 2) desired = 2;
                              if (desired > 5) desired = 5;
                              final crossAxisCount = desired;

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: products.length,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 0.78,
                                    ),
                                itemBuilder: (context, index) {
                                  final product = products[index];
                                  return _ProductCard(
                                    product: product,
                                    cardColor: card,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    textMuted: textMuted,
                                    isDark: isDark,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailsScreen(
                                          product: product,
                                          isAdmin: false,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
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
            icon: Icons.point_of_sale_outlined,
            label: 'New Sale',
            selected: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NewSaleScreen(
                  currentUserUid: AuthService().currentUser?.uid ?? '',
                  isAdmin: false,
                ),
              ),
            ),
            textSecondary: textSecondary,
            isDark: isDark,
          ),
          _SidebarItem(
            icon: Icons.receipt_long_outlined,
            label: 'Expenses',
            selected: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExpenseListScreen(
                  createdBy: AuthService().currentUser?.uid ?? '',
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
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const CustomerListScreen(isAdmin: false),
              ),
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
                builder: (_) => const ThemeSettingsScreen(isAdmin: false),
              ),
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

//-------------------- STAT MINI CARD WIDGET (Premium) --------------------
class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.icon,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? accentController.value : textPrimary,
              fontFamily: isDark ? 'PlayfairDisplay' : null,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: textSecondary)),
        ],
      ),
    );
  }
}

//-------------------- PRODUCT ROW WIDGET (View-Only - No Add to Cart) --------------------
class _ProductRow extends StatelessWidget {
  final ProductModel product;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;
  final VoidCallback onTap;

  const _ProductRow({
    required this.product,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stockQty <= 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            //-------------------- PRODUCT IMAGE (Circular with Gold Border) --------------------
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? accentController.value.withValues(alpha: 0.3)
                      : Colors.grey.shade200,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? accentController.value.withValues(alpha: 0.1)
                        : Colors.transparent,
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: product.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: accentController.value.withValues(alpha: 0.05),
                          child: Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  accentController.value,
                                ),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: accentController.value.withValues(alpha: 0.05),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 24,
                            color: textMuted,
                          ),
                        ),
                      )
                    : Container(
                        color: accentController.value.withValues(alpha: 0.05),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 24,
                          color: accentController.value,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            //-------------------- NAME + STOCK BADGE --------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? accentController.value : textPrimary,
                      fontFamily: isDark ? 'PlayfairDisplay' : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isOutOfStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Out of stock',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    )
                  else if (product.isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 10,
                            color: Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${product.stockQty} left',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      '${product.stockQty} in stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                ],
              ),
            ),

            //-------------------- SELLING PRICE --------------------
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'Rs. ${product.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? accentController.value : textPrimary,
                ),
              ),
            ),

            //-------------------- VIEW ICON (Chevron) --------------------
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? accentController.value.withValues(alpha: 0.08)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDark ? accentController.value : textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//-------------------- PRODUCT CARD (Grid) --------------------
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? accentController.value.withValues(alpha: 0.06)
                : Colors.transparent,
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.black12,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (more prominent, taller)
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: accentController.value.withValues(alpha: 0.05),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  accentController.value,
                                ),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: accentController.value.withValues(alpha: 0.05),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: textMuted,
                            size: 36,
                          ),
                        ),
                      )
                    : Container(
                        color: accentController.value.withValues(alpha: 0.04),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: textMuted,
                          size: 36,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? accentController.value : textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Rs. ${product.price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                if (product.stockQty <= 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Out',
                      style: TextStyle(color: textSecondary, fontSize: 11),
                    ),
                  )
                else
                  Text(
                    '${product.stockQty}',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
