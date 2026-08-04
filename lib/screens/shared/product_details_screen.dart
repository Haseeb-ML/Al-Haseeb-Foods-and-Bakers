import 'package:flutter/material.dart';
import 'dart:ui';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../admin/add_edit_product_screen.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../theme/accent_controller.dart';
import '../../theme/background_theme_controller.dart';
import '../admin/staff_management_screen.dart';
import '../shared/customer_list_screen.dart';
import '../admin/theme_settings_screen.dart';
import '../admin/theme_settings_screen.dart';
import '../admin/backup_restore_screen.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/staff_sidebar.dart';

//-------------------- DESKTOP BREAKPOINT --------------------
const double kDesktopBreakpoint = 900;

//-------------------- PRODUCT DETAILS SCREEN --------------------
class ProductDetailsScreen extends StatelessWidget {
  final ProductModel product;
  final bool isAdmin;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    this.isAdmin = false,
  });

  //-------------------- DELETE CONFIRMATION --------------------
  void _confirmDelete(BuildContext context) {
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
              await ProductService().deleteProduct(product.id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
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

  //-------------------- MONTH NAME HELPER --------------------
  String _monthName(int month) {
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
    return months[month - 1];
  }

  //-------------------- BUILD UI --------------------
  @override
  Widget build(BuildContext context) {
    final stockValue = product.price * product.stockQty;

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
                  stockValue,
                );

                if (isDesktop) {
                  return Scaffold(
                    backgroundColor: bg,
                    body: Row(
                      children: [
                        isAdmin
                            ? const AdminSidebar(currentRoute: 'Products')
                            : const StaffSidebar(currentRoute: 'Products'),
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

                //-------------------- MOBILE: SCAFFOLD WITH BACK BUTTON --------------------
                return Scaffold(
                  backgroundColor: bg,
                  body: SafeArea(child: SingleChildScrollView(child: content)),
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
    double stockValue,
  ) {
    // The top row (breadcrumbs + action buttons)
    final topRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(
                    color: isDark ? accentController.value.withValues(alpha: 0.2) : border,
                    width: 0.8,
                  ),
                ),
                child: Icon(Icons.arrow_back, size: 18, color: textPrimary),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory / ${product.category}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? accentController.value : textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Product Details',
                  style: TextStyle(
                    fontSize: isDesktop ? 22 : 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    fontFamily: isDark ? 'PlayfairDisplay' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (isAdmin)
          Row(
            children: [
              if (isDesktop)
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Product'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: border),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditProductScreen(existingProduct: product),
                      ),
                    );
                  },
                )
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: border),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.edit_outlined, color: textPrimary, size: 18),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditProductScreen(existingProduct: product),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(width: 8),
              if (isDesktop)
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => _confirmDelete(context),
                )
              else
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                    onPressed: () => _confirmDelete(context),
                  ),
                ),
            ],
          ),
      ],
    );

    final heroImage = Container(
      width: double.infinity,
      height: 320,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Blurred Background
            if (product.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: product.imageUrl,
                fit: BoxFit.cover,
              )
            else
              Container(color: accentController.value.withValues(alpha: 0.1)),
            if (product.imageUrl.isNotEmpty)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            // 2. Clear uncropped image
            if (product.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: product.imageUrl,
                fit: BoxFit.contain,
              )
            else
              const Icon(
                Icons.inventory_2_outlined,
                size: 90,
                color: Colors.black26,
              ),

            // 3. Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.4, 0.6, 1.0],
                ),
              ),
            ),

            // 4. Content Overlay
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          product.category.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, color: Color(0xFFFBBF24), size: 14),
                            SizedBox(width: 4),
                            Text(
                              '4.8 (124 reviews)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'PlayfairDisplay',
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Price per Unit',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rs. ${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 32),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'In Stock',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${product.stockQty}',
                                style: TextStyle(
                                  color: product.isLowStock ? const Color(0xFFEF4444) : Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Units',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
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

    final leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heroImage,
        const SizedBox(height: 24),
        _buildDescriptionSection(isDark, textSecondary, card, border, product.description),
      ],
    );

    final rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total Inventory Value
        _buildRightCard(
          card, border, isDark, textPrimary, textSecondary,
          icon: Icons.payments_outlined,
          badgeText: 'LIVE VALUE',
          badgeColor: const Color(0xFF3B82F6), // Blue
          title: 'Total Inventory Value',
          value: 'Rs. ${stockValue.toStringAsFixed(0)}',
          valueColor: const Color(0xFF3B82F6),
        ),
        const SizedBox(height: 16),
        // Expiry / Fresh Until (Dummy / createdAt)
        _buildRightCard(
          card, border, isDark, textPrimary, textSecondary,
          icon: Icons.calendar_today_outlined,
          badgeText: 'LAST UPDATED',
          badgeColor: textSecondary,
          title: 'Added / Fresh Since',
          value: '${product.createdAt.day} ${_monthName(product.createdAt.month)} ${product.createdAt.year}',
          valueColor: textPrimary,
        ),
        const SizedBox(height: 16),
        // Restock Product Blue Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F4C81), // Deep blue
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F4C81).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Restock Product',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Need to update your inventory counts? Add stock instantly.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F4C81),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isAdmin
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddEditProductScreen(existingProduct: product),
                            ),
                          );
                        }
                      : null,
                  child: const Text(
                    'Update Stock Count',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Stock Movement (Dummy layout as requested)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock Movement',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              _buildMovementItem(
                icon: Icons.add,
                iconBg: const Color(0xFF22C55E).withValues(alpha: 0.1),
                iconColor: const Color(0xFF22C55E),
                title: 'Stock Added (+20)',
                subtitle: 'Added by Admin • 2 hours ago',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 16),
              _buildMovementItem(
                icon: Icons.remove,
                iconBg: const Color(0xFFEF4444).withValues(alpha: 0.1),
                iconColor: const Color(0xFFEF4444),
                title: 'Sold (5 units)',
                subtitle: 'POS Terminal #2 • 5 hours ago',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
              const SizedBox(height: 16),
              _buildMovementItem(
                icon: Icons.sync,
                iconBg: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                iconColor: const Color(0xFF3B82F6),
                title: 'Inventory Reconciled',
                subtitle: 'System Audit • Yesterday',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ],
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          topRow,
          const SizedBox(height: 24),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: leftColumn),
                const SizedBox(width: 24),
                Expanded(flex: 4, child: rightColumn),
              ],
            )
          else ...[
            leftColumn,
            const SizedBox(height: 24),
            rightColumn,
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(bool isDark, Color textSecondary, Color card, Color border, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? accentController.value.withValues(alpha: 0.1) : border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 16,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(width: 8),
              const Text(
                'PRODUCT DESCRIPTION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B82F6),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description.isNotEmpty ? description : 'No description added.',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              height: 1.8,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightCard(
    Color card,
    Color border,
    bool isDark,
    Color textPrimary,
    Color textSecondary, {
    required IconData icon,
    required String badgeText,
    required Color badgeColor,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: badgeColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              color: textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 26,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
