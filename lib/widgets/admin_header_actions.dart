import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/alert_service.dart';
import '../models/user_model.dart';
import '../models/urgent_alert_model.dart';
import '../theme/app_theme.dart';
import '../theme/accent_controller.dart';
import '../screens/admin/theme_settings_screen.dart';
import '../screens/admin/admin_profile_screen.dart';

class AdminHeaderActions extends StatelessWidget {
  final bool isDesktop;

  const AdminHeaderActions({
    super.key,
    required this.isDesktop,
  });

  void _showAlertsListDialog(
    BuildContext context,
    List<UrgentAlertModel> activeAlerts,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? AppColors.darkBg : Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Active Staff Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 300,
            child: activeAlerts.isEmpty
                ? Center(
                    child: Text(
                      'No active notifications found.',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: activeAlerts.length,
                    separatorBuilder: (context, idx) => Divider(color: border),
                    itemBuilder: (context, index) {
                      final alert = activeAlerts[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alert.message,
                                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'By ${alert.userName} at ${DateFormat('hh:mm a').format(alert.createdAt)}',
                                    style: TextStyle(color: textSecondary, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                              tooltip: 'Acknowledge & Dismiss',
                              onPressed: () async {
                                await AlertService().markAsRead(alert.id);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final user = AuthService().currentUser;

    if (user == null) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        //---------- THEME PALETTE BUTTON ----------
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

        //---------- NOTIFICATION BELL BUTTON ----------
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

        //---------- ADMIN PROFILE AVATAR ----------
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
}
