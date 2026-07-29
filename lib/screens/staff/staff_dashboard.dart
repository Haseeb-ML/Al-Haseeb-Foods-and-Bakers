import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import '../../models/invoice_model.dart';
import '../../services/invoice_service.dart';
import 'staff_profile_screen.dart';
import '../../widgets/staff_sidebar.dart';
import '../../theme/app_theme.dart';
import '../../theme/accent_controller.dart';
import '../../theme/background_theme_controller.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';
import '../../models/stock_request_model.dart';
import '../../models/wastage_log_model.dart';
import '../../services/inventory_alert_service.dart';
import '../../models/urgent_alert_model.dart';
import '../../services/alert_service.dart';
import '../../models/leave_request_model.dart';
import '../../services/leave_service.dart';
import '../../models/payroll_model.dart';
import '../../services/payroll_service.dart';
import 'package:intl/intl.dart';

//-------------------- DESKTOP BREAKPOINT --------------------
const double kDesktopBreakpoint = 900;

//-------------------- STAFF DASHBOARD --------------------
class StaffDashboard extends StatefulWidget {
  final UserModel user;
  final bool isAdminPreview;
  final String? previewLabel;
  const StaffDashboard({
    super.key,
    required this.user,
    this.isAdminPreview = false,
    this.previewLabel,
  });

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final AttendanceService _attendanceService = AttendanceService();
  final InventoryAlertService _inventoryAlertService = InventoryAlertService();
  final AlertService _alertService = AlertService();
  final LeaveService _leaveService = LeaveService();

  //-------------------- DISPOSE STREAMS --------------------
  @override
  void dispose() {
    // Dispose any active streams if needed
    super.dispose();
  }

  //-------------------- LOGOUT --------------------
  Future<void> _handleLogout() async {
    try {
      await AuthService().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout error: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  //-------------------- GREETING --------------------
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }



  //-------------------- NAVIGATION HELPERS --------------------
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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

                //-------------------- ADMIN PREVIEW BANNER --------------------
                Widget previewBanner = const SizedBox.shrink();
                if (widget.isAdminPreview) {
                  previewBanner = Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent,
                          Color.lerp(accent, Colors.deepPurple, 0.4)!,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          const Icon(Icons.visibility, color: Colors.white, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.previewLabel ?? 'Admin Preview: Viewing Staff Dashboard',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              StaffSidebar.adminPreviewMode = false;
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.arrow_back, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Exit Preview',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (isDesktop) {
                  return Scaffold(
                    backgroundColor: bg,
                    body: Column(
                      children: [
                        previewBanner,
                        Expanded(
                          child: Row(
                            children: [
                              StaffSidebar(
                                  currentRoute: 'Dashboard',
                                  user: widget.user,
                                  isAdminPreview: widget.isAdminPreview,
                                ),
                              Expanded(
                                child: SafeArea(
                                  top: !widget.isAdminPreview,
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
                        ),
                      ],
                    ),
                  );
                }

                //-------------------- MOBILE LAYOUT --------------------
                return Scaffold(
                  backgroundColor: bg,
                  body: Column(
                    children: [
                      previewBanner,
                      Expanded(
                        child: SafeArea(
                          top: !widget.isAdminPreview,
                          child: content,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }



  //-------------------- STOCK REQUEST DIALOG --------------------
  void _showStockRequestDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemNameController = TextEditingController();
    final qtyController = TextEditingController();
    String selectedUnit = 'pcs';
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? AppColors.darkBg : Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentController.value.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.inventory_2_outlined, color: accentController.value, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Request Stock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: itemNameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Item Name (e.g. Flour, Sugar)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter item name' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: TextFormField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'Qty',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) {
                            final parsed = double.tryParse(v ?? '');
                            if (parsed == null || parsed <= 0) return 'Enter quantity';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: DropdownButtonFormField<String>(
                          value: selectedUnit,
                          dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: ['pcs', 'kg', 'bags', 'packs', 'liters'].map((u) {
                            return DropdownMenuItem<String>(value: u, child: Text(u));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedUnit = val);
                            }
                          },
                        ),
                      ),
                    ],
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
                backgroundColor: accentController.value,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isLoading = true);
                      try {
                        final req = StockRequestModel(
                          id: '',
                          userId: widget.user.uid,
                          userName: widget.user.name,
                          itemName: itemNameController.text.trim(),
                          quantity: double.parse(qtyController.text.trim()),
                          unit: selectedUnit,
                          status: 'Pending',
                          createdAt: DateTime.now(),
                        );
                        await _inventoryAlertService.submitStockRequest(req);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Request submitted for ${req.itemName}.'),
                              backgroundColor: Colors.green,
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
                  : const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }





  //-------------------- WASTAGE LOG DIALOG --------------------
  void _showWastageLogDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productNameController = TextEditingController();
    final qtyController = TextEditingController();
    String selectedReason = 'Expired';
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Log Wastage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: productNameController,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Product Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter product name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Wastage Qty',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) {
                      final parsed = int.tryParse(v ?? '');
                      if (parsed == null || parsed <= 0) return 'Enter valid quantity';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Reason',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['Expired', 'Damaged', 'Spoiled', 'Returned'].map((r) {
                      return DropdownMenuItem<String>(value: r, child: Text(r));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedReason = val);
                      }
                    },
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
                backgroundColor: AppColors.danger,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isLoading = true);
                      try {
                        final log = WastageLogModel(
                          id: '',
                          userId: widget.user.uid,
                          userName: widget.user.name,
                          productName: productNameController.text.trim(),
                          quantity: int.parse(qtyController.text.trim()),
                          reason: selectedReason,
                          createdAt: DateTime.now(),
                        );
                        await _inventoryAlertService.submitWastageLog(log);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Wastage logged for ${log.productName}.'),
                              backgroundColor: AppColors.danger,
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
                  : const Text('Log Wastage'),
            ),
          ],
        ),
      ),
    );
  }

  //-------------------- URGENT ALERT DIALOG --------------------
  void _showUrgentAlertDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    final presets = [
      'Need Change / Cash at Till',
      'Inventory / Ingredient Finished',
      'Urgent Customer Assistance',
      'Equipment / POS Machine Issue',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? AppColors.darkBg : Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Alert Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 340,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Select a preset alert or type your message below:',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: presets.map((preset) {
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            messageController.text = preset;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: messageController.text == preset
                                  ? accentController.value
                                  : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            preset,
                            style: TextStyle(
                              fontSize: 11,
                              color: messageController.text == preset
                                  ? accentController.value
                                  : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: messageController.text == preset ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: messageController,
                    maxLines: 2,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Custom Alert Message',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter alert message' : null,
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
                backgroundColor: Colors.amber[700],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isLoading = true);
                      try {
                        final alert = UrgentAlertModel(
                          id: '',
                          userId: widget.user.uid,
                          userName: widget.user.name,
                          message: messageController.text.trim(),
                          isRead: false,
                          createdAt: DateTime.now(),
                        );
                        await _alertService.sendUrgentAlert(alert);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Urgent Alert sent to Admin Console.'),
                              backgroundColor: Colors.amber,
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
                  : const Text('Send Alert'),
            ),
          ],
        ),
      ),
    );
  }

  //-------------------- TARGET PROGRESS & HANDOVER HELPERS --------------------
  Widget _buildTargetProgressCard(
    BuildContext context,
    Color card,
    Color border,
    Color textPrimary,
    Color textSecondary,
    List<InvoiceModel> todayInvoices,
    bool isDark,
  ) {
    final todayStaffInvoices = todayInvoices.where((inv) => inv.createdBy == widget.user.uid).toList();
    final todayStaffRevenue = todayStaffInvoices.fold<double>(0, (sum, inv) => sum + inv.totalAmount);
    const double targetAmount = 50000.0;
    final double progressPercent = (todayStaffRevenue / targetAmount).clamp(0.0, 1.0);
    final isTargetMet = todayStaffRevenue >= targetAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.track_changes_outlined, color: accentController.value, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Sales Target',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isTargetMet ? Colors.green.withValues(alpha: 0.12) : accentController.value.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isTargetMet ? 'Target Achieved! 🎉' : '${(progressPercent * 100).toStringAsFixed(0)}% Completed',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isTargetMet ? Colors.green : accentController.value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Sales Today', style: TextStyle(fontSize: 11, color: textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    'Rs. ${todayStaffRevenue.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Daily Target', style: TextStyle(fontSize: 11, color: textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    'Rs. ${targetAmount.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressPercent,
              minHeight: 8,
              backgroundColor: isDark ? Colors.black26 : Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(isTargetMet ? Colors.green : accentController.value),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTargetMet ? 'Phenomenal work! Keep pushing!' : 'Rs. ${(targetAmount - todayStaffRevenue).clamp(0.0, double.infinity).toStringAsFixed(0)} remaining to target',
                style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: textSecondary),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(Icons.receipt_long_outlined, size: 14, color: accentController.value),
                label: Text(
                  'Shift Handover Report',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentController.value),
                ),
                onPressed: () => _showShiftHandoverDialog(todayStaffInvoices, todayStaffRevenue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showShiftHandoverDialog(List<InvoiceModel> todayStaffInvoices, double todayStaffRevenue) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalInvoices = todayStaffInvoices.length;
    final cashCollected = todayStaffInvoices.fold<double>(0, (sum, inv) => sum + inv.amountPaid);
    final totalDues = todayStaffInvoices.fold<double>(0, (sum, inv) => sum + inv.dueAmount);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.assignment_turned_in_outlined, color: Colors.green, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Shift Handover Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHandoverRow('Total Invoices Handled', '$totalInvoices', isDark),
              _buildHandoverRow('Total Sales Revenue', 'Rs. ${todayStaffRevenue.toStringAsFixed(0)}', isDark),
              _buildHandoverRow('Cash Collected (Paid)', 'Rs. ${cashCollected.toStringAsFixed(0)}', isDark),
              _buildHandoverRow('Outstanding Dues Created', 'Rs. ${totalDues.toStringAsFixed(0)}', isDark),
              const Divider(height: 24),
              Text(
                'Verify the cash drawer amount tally matches the Cash Collected value before closing the counter shift.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildHandoverRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  //-------------------- LEAVE REQUEST DIALOG --------------------
  void _showLeaveRequestDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedType = 'Sick';
    final reasonController = TextEditingController();
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? AppColors.darkBg : Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.date_range_outlined, color: Colors.blue, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Apply for Leave', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 325,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    dropdownColor: isDark ? AppColors.darkCard : Colors.white,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Leave Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: ['Sick', 'Casual', 'Shift Exchange'].map((t) {
                      return DropdownMenuItem<String>(value: t, child: Text(t));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedType = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.calendar_today, size: 14),
                          label: Text(
                            'Start: ${DateFormat('dd MMM').format(startDate)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                startDate = picked;
                                if (endDate.isBefore(startDate)) {
                                  endDate = startDate;
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.calendar_today, size: 14),
                          label: Text(
                            'End: ${DateFormat('dd MMM').format(endDate)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => endDate = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 2,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Reason / Explanation',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter explanation reason' : null,
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
                backgroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => isLoading = true);
                      try {
                        final req = LeaveRequestModel(
                          id: '',
                          userId: widget.user.uid,
                          userName: widget.user.name,
                          leaveType: selectedType,
                          startDate: startDate,
                          endDate: endDate,
                          reason: reasonController.text.trim(),
                          status: 'Pending',
                          createdAt: DateTime.now(),
                        );
                        await _leaveService.submitLeaveRequest(req);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Leave request (${req.leaveType}) submitted.'),
                              backgroundColor: Colors.blue,
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
                  : const Text('Submit Application'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayrollHistoryDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? AppColors.darkBg : Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments_outlined, color: Colors.green, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Salary & Payroll History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 350,
            child: StreamBuilder<List<PayrollModel>>(
              stream: PayrollService().getPayrollHistory(widget.user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No payroll slips recorded yet.',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (context, idx) => Divider(color: border),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.month,
                                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Paid',
                                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Base Salary:', style: TextStyle(color: textSecondary, fontSize: 12)),
                              Text('Rs. ${item.baseSalary.toStringAsFixed(0)}', style: TextStyle(color: textPrimary, fontSize: 12)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Bonus / Allowance:', style: TextStyle(color: textSecondary, fontSize: 12)),
                              Text('+Rs. ${item.bonus.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Deductions / Advances:', style: TextStyle(color: textSecondary, fontSize: 12)),
                              Text('-Rs. ${item.deductions.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ],
                          ),
                          const Divider(height: 10, thickness: 0.5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Net Received:', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Rs. ${item.netPaid.toStringAsFixed(0)}', style: TextStyle(color: accentController.value, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Paid on: ${DateFormat('dd MMM yyyy, hh:mm a').format(item.paidAt)}',
                            style: TextStyle(color: textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  },
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

  void _showAttendanceHistoryDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? AppColors.darkBg : Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.date_range_outlined, color: Colors.blue, size: 22),
              ),
              const SizedBox(width: 12),
              const Text('Your Attendance Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 350,
            child: StreamBuilder<List<AttendanceModel>>(
              stream: _attendanceService.getAttendanceHistory(widget.user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No attendance records found.',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (context, idx) => Divider(color: border),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final isLate = item.status == 'Late';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.date,
                                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.login_rounded, size: 12, color: textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'In: ${DateFormat('hh:mm a').format(item.clockIn)}',
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(Icons.logout_rounded, size: 12, color: textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.clockOut != null
                                        ? 'Out: ${DateFormat('hh:mm a').format(item.clockOut!)}'
                                        : 'Active Shift',
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLate ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isLate ? Colors.red : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
    return RefreshIndicator(
      color: accentController.value,
      backgroundColor: card,
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //-------------------- HEADER --------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()}, ${widget.user.name.isNotEmpty ? widget.user.name : "Staff"}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? accentController.value : textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
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
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'Staff Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [

                    Container(
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
                      child: IconButton(
                        onPressed: _handleLogout,
                        padding: const EdgeInsets.all(10),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.danger,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    GestureDetector(
                      onTap: () => _navigateTo(context, StaffProfileScreen(user: widget.user)),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: card,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? accentController.value.withValues(alpha: 0.2)
                                : border,
                            width: 0.8,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor:
                              accentController.value.withValues(alpha: 0.12),
                          backgroundImage: widget.user.profileImageUrl.isNotEmpty
                              ? CachedNetworkImageProvider(widget.user.profileImageUrl)
                              : null,
                          child: widget.user.profileImageUrl.isEmpty
                              ? Icon(
                                  Icons.person_outline,
                                  color: isDark
                                      ? accentController.value
                                      : textSecondary,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            //-------------------- HERO WORKSPACE BANNER --------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    accentController.value,
                    Color.lerp(accentController.value, const Color(0xFF0F172A), 0.35)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentController.value.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Employee Portal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your attendance logs, view monthly payroll details, request leaves, and alert admin directly.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            //-------------------- ATTENDANCE CLOCK IN / OUT --------------------
            StreamBuilder<AttendanceModel?>(
              stream: _attendanceService.getTodayAttendance(widget.user.uid),
              builder: (context, attendanceSnap) {
                final attendance = attendanceSnap.data;
                final isClockedIn = attendance != null && attendance.clockOut == null;
                final isClockedOut = attendance != null && attendance.clockOut != null;

                String statusText = 'Not Checked In';
                Color statusColor = Colors.orange;
                IconData statusIcon = Icons.login;

                if (isClockedIn) {
                  statusText = 'Active Shift (In: ${DateFormat('hh:mm a').format(attendance.clockIn)})';
                  statusColor = Colors.green;
                  statusIcon = Icons.timer_outlined;
                } else if (isClockedOut) {
                  final hours = attendance.clockOut!.difference(attendance.clockIn).inHours;
                  final minutes = attendance.clockOut!.difference(attendance.clockIn).inMinutes % 60;
                  statusText = 'Shift Completed (Worked: ${hours}h ${minutes}m)';
                  statusColor = Colors.grey;
                  statusIcon = Icons.check_circle_outline;
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(statusIcon, color: statusColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shift Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (!isClockedOut)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isClockedIn ? AppColors.danger : accentController.value,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: widget.isAdminPreview
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Attendance updates are disabled during Staff Inspection Mode.'),
                                      backgroundColor: AppColors.danger,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              : () async {
                                  if (isClockedIn) {
                                    await _attendanceService.clockOut(widget.user.uid);
                                  } else {
                                    await _attendanceService.clockIn(widget.user.uid, widget.user.name);
                                  }
                                },
                          child: Text(
                            isClockedIn ? 'Clock Out' : 'Clock In',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        const Icon(Icons.check_circle_outline, color: Colors.green),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            //-------------------- STAFF DATA STREAM BUILDERS --------------------
            StreamBuilder<List<AttendanceModel>>(
              stream: _attendanceService.getAttendanceHistory(widget.user.uid),
              builder: (context, attendanceSnap) {
                final attendanceList = attendanceSnap.data ?? [];
                final now = DateTime.now();
                final thisMonthAttendance = attendanceList.where((log) {
                  // Basic parse check or safe Date check
                  try {
                    return log.clockIn.year == now.year && log.clockIn.month == now.month;
                  } catch (_) {
                    return false;
                  }
                }).toList();

                return StreamBuilder<List<LeaveRequestModel>>(
                  stream: _leaveService.getLeaveRequests(),
                  builder: (context, leaveSnap) {
                    final allLeaves = leaveSnap.data ?? [];
                    final userLeaves = allLeaves.where((l) => l.userId == widget.user.uid).toList();
                    final pendingLeaves = userLeaves.where((l) => l.status == 'Pending').length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.payments_outlined,
                                label: 'Monthly Base Salary',
                                value: 'Rs. ${widget.user.monthlySalary.toStringAsFixed(0)}',
                                badgeText: 'Payroll',
                                color: const Color(0xFF10B981),
                                card: card,
                                border: border,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.calendar_today_outlined,
                                label: 'Days Present (Month)',
                                value: '${thisMonthAttendance.length} Days',
                                badgeText: 'Attendance',
                                color: const Color(0xFF3B82F6),
                                card: card,
                                border: border,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.hourglass_empty_rounded,
                                label: 'Pending Leave Requests',
                                value: '$pendingLeaves',
                                badgeText: 'Leaves',
                                color: const Color(0xFFEC4899),
                                card: card,
                                border: border,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.schedule_outlined,
                                label: 'Assigned Shift',
                                value: 'Morning Shift',
                                badgeText: '08:00 AM - 04:00 PM',
                                color: const Color(0xFFD97706),
                                card: card,
                                border: border,
                                textPrimary: textPrimary,
                                textSecondary: textSecondary,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            //-------------------- QUICK ACCESS GRID --------------------
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: accentController.value,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Employee Self-Service Actions',
                  style: TextStyle(
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isDesktop ? 180 : (MediaQuery.of(context).size.width - 48) / 3,
                  child: _QuickActionButton(
                    icon: Icons.payments_outlined,
                    label: 'Salary History',
                    subtitle: 'View payslips',
                    color: const Color(0xFF10B981),
                    card: card,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    isDark: isDark,
                    onTap: _showPayrollHistoryDialog,
                  ),
                ),
                SizedBox(
                  width: isDesktop ? 180 : (MediaQuery.of(context).size.width - 48) / 3,
                  child: _QuickActionButton(
                    icon: Icons.date_range_outlined,
                    label: 'Attendance Log',
                    subtitle: 'Clock ins history',
                    color: const Color(0xFF3B82F6),
                    card: card,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    isDark: isDark,
                    onTap: _showAttendanceHistoryDialog,
                  ),
                ),
                SizedBox(
                  width: isDesktop ? 180 : (MediaQuery.of(context).size.width - 48) / 3,
                  child: _QuickActionButton(
                    icon: Icons.badge_outlined,
                    label: 'Apply Leave',
                    subtitle: 'Sick/Casual request',
                    color: const Color(0xFFEC4899),
                    card: card,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    isDark: isDark,
                    onTap: () {
                      if (widget.isAdminPreview) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Leave applications are disabled during Staff Inspection Mode.'),
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      _showLeaveRequestDialog();
                    },
                  ),
                ),
                SizedBox(
                  width: isDesktop ? 180 : (MediaQuery.of(context).size.width - 48) / 3,
                  child: _QuickActionButton(
                    icon: Icons.warning_amber_rounded,
                    label: 'Alert Admin',
                    subtitle: 'Send emergency',
                    color: const Color(0xFFD97706),
                    card: card,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    isDark: isDark,
                    onTap: () {
                      if (widget.isAdminPreview) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Urgent alerts are disabled during Staff Inspection Mode.'),
                            backgroundColor: AppColors.danger,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      _showUrgentAlertDialog();
                    },
                  ),
                ),
                SizedBox(
                  width: isDesktop ? 180 : (MediaQuery.of(context).size.width - 48) / 3,
                  child: _QuickActionButton(
                    icon: Icons.person_outline_rounded,
                    label: 'My Profile',
                    subtitle: 'Personal details',
                    color: Colors.deepPurple,
                    card: card,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    isDark: isDark,
                    onTap: () => _navigateTo(
                      context,
                      StaffProfileScreen(user: widget.user),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}



//-------------------- STAT CARD --------------------
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String badgeText;
  final Color color;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.badgeText,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? accentController.value.withValues(alpha: 0.12)
              : border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
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
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

//-------------------- QUICK ACTION BUTTON --------------------
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? accentController.value.withValues(alpha: 0.12)
              : border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 10,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 10,
                    color: textMuted,
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
