import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../services/invoice_service.dart';
import '../../models/invoice_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/accent_controller.dart';
import '../../theme/background_theme_controller.dart';
import '../auth/login_screen.dart';
import '../../widgets/staff_sidebar.dart';
import '../../services/attendance_service.dart';
import '../../models/attendance_model.dart';
import '../../services/leave_service.dart';
import '../../models/leave_request_model.dart';
import '../../services/payroll_service.dart';
import '../../models/payroll_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const double kDesktopBreakpoint = 900;

class StaffProfileScreen extends StatefulWidget {
  final UserModel user;
  const StaffProfileScreen({super.key, required this.user});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}



class _StaffProfileScreenState extends State<StaffProfileScreen> {
  bool _isUploadingImage = false;

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final bytes = await image.readAsBytes();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/tdkjl9oo/image/upload'),
      );
      request.fields['upload_preset'] = 'erp_images';
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: image.name),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(respStr);
        final secureUrl = jsonResponse['secure_url'];

        // Update in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .update({'profileImageUrl': secureUrl});

        // Update local object
        setState(() {
          widget.user.profileImageUrl = secureUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Cloudinary upload failed: \${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }
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
                final content = _buildProfileContent(
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
                          currentRoute: 'Profile',
                          user: widget.user,
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
                }

                return Scaffold(
                  backgroundColor: bg,
                  appBar: AppBar(
                    title: const Text('My Profile & Activity'),
                    backgroundColor: card,
                    elevation: 0,
                    foregroundColor: textPrimary,
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

  Widget _buildProfileContent(
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back to Dashboard',
                  style: IconButton.styleFrom(
                    backgroundColor: card,
                    foregroundColor: textPrimary,
                    side: BorderSide(color: border),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'My Profile & Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          //-------------------- PROFILE HEADER CARD --------------------
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black26 : Colors.black12,
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: accentController.value.withValues(alpha: 0.15),
                        backgroundImage: widget.user.profileImageUrl.isNotEmpty
                            ? CachedNetworkImageProvider(widget.user.profileImageUrl)
                            : null,
                        child: widget.user.profileImageUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                size: 36,
                                color: accentController.value,
                              )
                            : null,
                      ),
                      if (_isUploadingImage)
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        ),
                      if (!_isUploadingImage)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: accentController.value,
                              shape: BoxShape.circle,
                              border: Border.all(color: card, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.name.isNotEmpty ? widget.user.name : 'Staff Member',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentController.value.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: accentController.value.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.badge_outlined, size: 14, color: accentController.value),
                                const SizedBox(width: 4),
                                Text(
                                  'STAFF MEMBER',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: accentController.value,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger.withValues(alpha: 0.12),
                    foregroundColor: AppColors.danger,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          //-------------------- STAFF DATA SECTIONS --------------------
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
                'My Employee Logs & Records',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Attendance Logs Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.date_range_outlined, color: accentController.value, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Attendance Logs',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<AttendanceModel>>(
                  stream: AttendanceService().getAttendanceHistory(widget.user.uid),
                  builder: (context, snapshot) {
                    final logs = snapshot.data ?? [];
                    if (logs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text('No attendance logs recorded yet.', style: TextStyle(color: textMuted, fontSize: 12)),
                      );
                    }
                    return Column(
                      children: logs.take(5).map((log) {
                        final isLate = log.status == 'Late';
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: border, width: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(log.date, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'In: ${DateFormat('hh:mm a').format(log.clockIn)}${log.clockOut != null ? " • Out: " + DateFormat('hh:mm a').format(log.clockOut!) : " (Active Shift)"}',
                                    style: TextStyle(color: textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isLate ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  log.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isLate ? Colors.red : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Leave Requests History Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.badge_outlined, color: accentController.value, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Leave Application History',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<LeaveRequestModel>>(
                  stream: LeaveService().getLeaveRequests(),
                  builder: (context, snapshot) {
                    final allLeaves = snapshot.data ?? [];
                    final userLeaves = allLeaves.where((l) => l.userId == widget.user.uid).toList();

                    if (userLeaves.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text('No leave applications requested yet.', style: TextStyle(color: textMuted, fontSize: 12)),
                      );
                    }
                    return Column(
                      children: userLeaves.take(5).map((leave) {
                        final isApproved = leave.status == 'Approved';
                        final isPending = leave.status == 'Pending';
                        final statusColor = isApproved ? Colors.green : (isPending ? Colors.orange : Colors.red);
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: border, width: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${leave.leaveType} Leave (${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM').format(leave.endDate)})',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      leave.reason,
                                      style: TextStyle(color: textSecondary, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  leave.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payroll Receipts Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.payments_outlined, color: accentController.value, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Payroll & Payslips History',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<PayrollModel>>(
                  stream: PayrollService().getPayrollHistory(widget.user.uid),
                  builder: (context, snapshot) {
                    final slips = snapshot.data ?? [];
                    if (slips.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Text('No payslips generated yet.', style: TextStyle(color: textMuted, fontSize: 12)),
                      );
                    }
                    return Column(
                      children: slips.take(5).map((slip) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: border, width: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(slip.month, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Paid on: ${DateFormat('dd MMM yyyy').format(slip.paidAt)}',
                                    style: TextStyle(color: textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                              Text(
                                'Rs. ${slip.netPaid.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: accentController.value,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}


