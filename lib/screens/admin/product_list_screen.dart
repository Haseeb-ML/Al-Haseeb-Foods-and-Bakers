import 'package:flutter/material.dart';
import '../../utils/image_cache_manager.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../shared/product_details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'add_edit_product_screen.dart';
import 'staff_management_screen.dart';
import 'theme_settings_screen.dart';
import '../shared/customer_list_screen.dart';
import '../shared/new_sale_screen.dart';
import '../../services/auth_service.dart';
import '../../services/alert_service.dart';
import '../../models/urgent_alert_model.dart';
import '../../models/user_model.dart';
import 'admin_profile_screen.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../theme/background_theme_controller.dart';
import '../../theme/accent_controller.dart';
import 'backup_restore_screen.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/admin_header_actions.dart';
import '../../utils/bakery_data_seeder.dart';

//-------------------- DESKTOP BREAKPOINT --------------------
const double kDesktopBreakpoint = 900;

//-------------------- PRODUCT LIST SCREEN (ADMIN) --------------------
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showLowStockOnly = false;
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildHeaderActions({
    required BuildContext context,
    required bool isDesktop,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final firebaseUser = AuthService().currentUser;
    final user = UserModel(
      uid: firebaseUser?.uid ?? '',
      name: firebaseUser?.displayName ?? 'Admin Owner',
      email: firebaseUser?.email ?? '',
      role: 'admin',
      phone: '',
      createdAt: DateTime.now(),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ThemeSettingsScreen(isAdmin: true),
              ),
            );
          },
          child: Container(
            width: isDesktop ? 44 : 36,
            height: isDesktop ? 44 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentController.value.withValues(alpha: 0.12),
              border: Border.all(
                color: accentController.value.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.palette_outlined,
              size: isDesktop ? 26 : 21,
              color: accentController.value,
            ),
          ),
        ),
        const SizedBox(width: 8),
        StreamBuilder<List<UrgentAlertModel>>(
          stream: AlertService().getActiveAlerts(),
          builder: (context, alertSnap) {
            final activeAlerts = alertSnap.data ?? [];
            final count = activeAlerts.length;
            final hasAlerts = count > 0;

            return GestureDetector(
              onTap: () => _showAlertsListDialog(context, activeAlerts, isDark, textPrimary, textSecondary),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: isDesktop ? 44 : 36,
                    height: isDesktop ? 44 : 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasAlerts 
                          ? AppColors.danger.withValues(alpha: 0.12)
                          : accentController.value.withValues(alpha: 0.12),
                      border: Border.all(
                        color: hasAlerts 
                            ? AppColors.danger.withValues(alpha: 0.35)
                            : accentController.value.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      hasAlerts ? Icons.notifications_active_outlined : Icons.notifications_outlined,
                      size: isDesktop ? 24 : 19,
                      color: hasAlerts ? AppColors.danger : accentController.value,
                    ),
                  ),
                  if (hasAlerts)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        StreamBuilder<UserModel?>(
          stream: AuthService().getUserStream(user.uid),
          builder: (context, userSnap) {
            final liveUser = userSnap.data ?? user;
            final imgUrl = liveUser.profileImageUrl;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminProfileScreen(user: liveUser),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentController.value.withValues(alpha: 0.35),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentController.value.withValues(alpha: 0.15),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: isDesktop ? 26 : 19,
                  backgroundColor: accentController.value.withValues(
                    alpha: 0.12,
                  ),
                  backgroundImage: imgUrl.isNotEmpty
                      ? CachedNetworkImageProvider(imgUrl)
                      : null,
                  child: imgUrl.isEmpty
                      ? Text(
                          liveUser.name.isNotEmpty
                              ? liveUser.name[0].toUpperCase()
                              : 'A',
                          style: TextStyle(
                            fontSize: isDesktop ? 17 : 13,
                            fontWeight: FontWeight.bold,
                            color: accentController.value,
                          ),
                        )
                      : null,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showAlertsListDialog(BuildContext context, List<UrgentAlertModel> alerts, bool isDark, Color textPrimary, Color textSecondary) {
    showDialog(
      context: context,
      builder: (ctx) {
        final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
        final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        return AlertDialog(
          backgroundColor: cardColor,
          title: Text(
            'Urgent Alerts (${alerts.length})',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          ),
          content: alerts.isEmpty
              ? Text('No active alerts', style: TextStyle(color: textSecondary))
              : SizedBox(
                  width: 400,
                  height: 300,
                  child: ListView.builder(
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.userName,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                            ),
                            const SizedBox(height: 4),
                            Text(alert.message, style: TextStyle(color: textPrimary, fontSize: 13)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }

  //-------------------- DELETE CONFIRMATION --------------------
  void _confirmDelete(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _productService.deleteProduct(product.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  //-------------------- COMPACT NUMBER FORMAT --------------------
  String _formatCompact(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
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
                        const AdminSidebar(
                          currentRoute: 'Products',
                        ),
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

                //-------------------- MOBILE: PLAIN SCAFFOLD WITH BACK & DRAWER BUTTONS --------------------
                return Scaffold(
                  backgroundColor: bg,
                  drawer: Drawer(
                    width: 230,
                    child: const AdminSidebar(
                      currentRoute: 'Products',
                    ),
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

  //==================== SHARED CONTENT (header, stats, list/grid) ====================
  Widget _buildContent(
    BuildContext context,
    Color card,
    Color border,
    Color textPrimary,
    Color textSecondary,
    Color textMuted,
    bool isDesktop,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(
                        color: accentController.value.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(Icons.menu, size: 20, color: textPrimary),
                  ),
                ),
              ),
              AdminHeaderActions(isDesktop: false),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        //-------------------- HEADER: TITLE + ADD BUTTON --------------------
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory',
                    style: TextStyle(
                      fontSize: 12,
                      color: accentController.value,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Products',
                    style: TextStyle(
                      fontSize: isDesktop ? 26 : 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? accentController.value : textPrimary,
                      fontFamily: isDark ? 'PlayfairDisplay' : null,
                    ),
                  ),
                ],
              ),
            ),
            // SEED DEMO DATA BUTTON (one time use)
            GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Seed Demo Products?'),
                    content: const Text('This will add 26 sample bakery products across 4 categories.\n\nOnly do this once to avoid duplicates.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: accentController.value),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Add Demo Products'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await BakeryDataSeeder().seedProducts();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('✅ 26 demo products added successfully!'),
                        backgroundColor: accentController.value,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Container(
                height: 38,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: accentController.value, width: 1.2),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dataset_outlined, color: accentController.value, size: 16),
                    if (isDesktop) const SizedBox(width: 6),
                    if (isDesktop)
                      Text(
                        'Seed Demo',
                        style: TextStyle(
                          color: accentController.value,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditProductScreen(),
                  ),
                );
              },
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
                            'Add product',
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
            if (isDesktop) const SizedBox(width: 12),
            if (isDesktop) AdminHeaderActions(isDesktop: isDesktop),
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
              color: isDark ? accentController.value.withValues(alpha: 0.15) : border,
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

        //-------------------- CATEGORY FILTER CHIPS BAR --------------------
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              'All',
              ...kBakeryCategories,
            ].map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: accentController.value,
                  backgroundColor: card,
                  side: BorderSide(
                    color: isSelected ? accentController.value : border,
                    width: 0.8,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : textPrimary,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = cat);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        //-------------------- SCROLLABLE STATS + PRODUCT LIST/GRID --------------------
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
              final stockValue = allProducts.fold<double>(
                0,
                (sum, p) => sum + (p.price * p.stockQty),
              );
              final lowStockCount = allProducts
                  .where((p) => p.isLowStock)
                  .length;

              var products = List<ProductModel>.from(allProducts);
              if (_selectedCategory != 'All') {
                products = products.where((p) => p.category == _selectedCategory).toList();
              }
              if (_showLowStockOnly) {
                products = products.where((p) => p.isLowStock).toList();
              }
              if (_searchQuery.isNotEmpty) {
                products = products
                    .where((p) => p.name.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    //-------------------- STAT CARDS ROW --------------------
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _showLowStockOnly = false),
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
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _StatMiniCard(
                            label: 'Stock value',
                            value: 'Rs. ${_formatCompact(stockValue)}',
                            icon: Icons.attach_money,
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
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _showLowStockOnly = true),
                            child: _StatMiniCard(
                              label: _showLowStockOnly
                                  ? 'Showing Low Stock'
                                  : 'Low stock',
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
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    //-------------------- SECTION LABEL --------------------
                    Row(
                      children: [
                        Icon(
                          _showLowStockOnly
                              ? Icons.warning_amber_rounded
                              : Icons.shopping_bag_outlined,
                          size: 14,
                          color: accentController.value,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _showLowStockOnly
                              ? 'LOW STOCK PRODUCTS'
                              : 'ALL PRODUCTS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: accentController.value,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    //-------------------- PRODUCT LIST (mobile) / GRID (desktop) --------------------
                    if (products.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No products found',
                            style: TextStyle(color: textMuted),
                          ),
                        ),
                      )
                    else if (isDesktop)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        // Fixed max width per card (instead of a fixed
                        // crossAxisCount) so the number of columns adapts to
                        // the actual available width on any PC/monitor, and
                        // a fixed mainAxisExtent (instead of childAspectRatio)
                        // so the card height never shrinks below what the
                        // name/price/Edit-Delete row needs — that's what was
                        // causing the Edit/Delete buttons to get clipped off
                        // on narrower screens.
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 260,
                              crossAxisSpacing: 18,
                              mainAxisSpacing: 18,
                              mainAxisExtent: 320,
                            ),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return _ProductCard(
                            product: product,
                            card: card,
                            border: border,
                            textPrimary: textPrimary,
                            textSecondary: textSecondary,
                            textMuted: textMuted,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailsScreen(
                                  product: product,
                                  isAdmin: true,
                                ),
                              ),
                            ),
                            onEdit: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddEditProductScreen(
                                  existingProduct: product,
                                ),
                              ),
                            ),
                            onDelete: () => _confirmDelete(product),
                          );
                        },
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
                        ),
                        child: Column(
                          children: List.generate(products.length, (index) {
                            final product = products[index];
                            final isLast = index == products.length - 1;

                            return Column(
                              children: [
                                _ProductRow(
                                  product: product,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  textMuted: textMuted,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailsScreen(
                                        product: product,
                                        isAdmin: true,
                                      ),
                                    ),
                                  ),
                                  onEdit: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddEditProductScreen(
                                        existingProduct: product,
                                      ),
                                    ),
                                  ),
                                  onDelete: () => _confirmDelete(product),
                                ),
                                if (!isLast)
                                  Divider(
                                    color: isDark
                                        ? accentController.value.withValues(
                                            alpha: 0.08,
                                          )
                                        : border,
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

//-------------------- DESKTOP SIDEBAR (Premium with Gold Accents) --------------------
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
                  isAdmin: true,
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
              MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
            ),
            textSecondary: textSecondary,
            isDark: isDark,
          ),
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
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? accentController.value.withValues(alpha: 0.1) : border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.transparent,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 12, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? accentController.value : textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//-------------------- PRODUCT ROW WIDGET (Mobile List - Premium) --------------------
class _ProductRow extends StatelessWidget {
  final ProductModel product;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductRow({
    required this.product,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            //-------------------- PRODUCT IMAGE (Circular with Gold Border) --------------------
            Container(
              width: 52,
              height: 52,
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
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: ClipOval(
                child: product.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        cacheManager: CustomImageCacheManager.instance,
                        imageUrl: product.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        memCacheWidth: 100,
                        memCacheHeight: 100,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
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
                          alignment: Alignment.center,
                          color: accentController.value.withValues(alpha: 0.05),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 24,
                            color: textMuted,
                          ),
                        ),
                      )
                    : Container(
                        alignment: Alignment.center,
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
            //-------------------- PRODUCT INFO --------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? accentController.value : textPrimary,
                      fontFamily: isDark ? 'PlayfairDisplay' : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.isLowStock)
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
                ],
              ),
            ),
            //-------------------- PRICE --------------------
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                'Rs. ${product.price.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? accentController.value : textPrimary,
                ),
              ),
            ),
            //-------------------- EDIT BUTTON --------------------
            GestureDetector(
              onTap: onEdit,
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(left: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentController.value.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accentController.value.withValues(alpha: 0.15),
                  ),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: accentController.value,
                ),
              ),
            ),
            const SizedBox(width: 6),
            //-------------------- DELETE BUTTON --------------------
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  ),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//-------------------- PREMIUM PRODUCT CARD WIDGET (Desktop Grid) --------------------
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? card : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isDark
                ? accentController.value.withValues(alpha: 0.15)
                : border.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: isDark
                  ? accentController.value.withValues(alpha: 0.05)
                  : Colors.transparent,
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            //-------------------- IMAGE WITH GOLD BORDER (TOP) --------------------
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.35,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accentController.value.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentController.value.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: product.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              cacheManager: CustomImageCacheManager.instance,
                              imageUrl: product.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              memCacheWidth: 350,
                              memCacheHeight: 350,
                              fadeInDuration: Duration.zero,
                              fadeOutDuration: Duration.zero,
                              placeholder: (context, url) => Container(
                                color: isDark
                                    ? accentController.value.withValues(alpha: 0.05)
                                    : Colors.grey.shade100,
                              ),
                              errorWidget: (context, url, error) => Container(
                                alignment: Alignment.center,
                                color: isDark
                                    ? accentController.value.withValues(alpha: 0.05)
                                    : Colors.grey.shade100,
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  size: 40,
                                  color: textMuted,
                                ),
                              ),
                            )
                          : Container(
                              alignment: Alignment.center,
                              color: isDark
                                  ? accentController.value.withValues(alpha: 0.05)
                                  : Colors.grey.shade100,
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 40,
                                color: textMuted,
                              ),
                            ),
                    ),
                  ),
                ),

                //-------------------- STOCK BADGE (Top-Right) --------------------
                Positioned(
                  top: 18,
                  right: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: product.isLowStock
                          ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                          : const Color(0xFF22C55E).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: product.isLowStock
                            ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                            : const Color(0xFF22C55E).withValues(alpha: 0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.transparent,
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          product.isLowStock
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle,
                          size: 12,
                          color: product.isLowStock
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF22C55E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.isLowStock
                              ? '${product.stockQty} left'
                              : '${product.stockQty} in stock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: product.isLowStock
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            //-------------------- PRODUCT INFO --------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name (Gold accent)
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: isDark ? 'PlayfairDisplay' : null,
                      color: isDark ? accentController.value : textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Price with Rs. text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rs. ${product.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? accentController.value : textPrimary,
                        ),
                      ),
                      // Reorder button (appears on hover)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
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
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: accentController.value.withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Text(
                            'Reorder',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            //-------------------- ACTION BUTTONS (Edit/Delete) --------------------
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade50,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? accentController.value.withValues(alpha: 0.08)
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: isDark ? accentController.value : Colors.blue,
                    onTap: onEdit,
                  ),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: const Color(0xFFEF4444),
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//-------------------- REUSABLE ACTION BUTTON --------------------
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}