import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/background_theme_controller.dart';
import '../../theme/accent_controller.dart';
import 'product_list_screen.dart';
import 'theme_settings_screen.dart';
import '../shared/customer_list_screen.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/admin_header_actions.dart';

//-------------------- DESKTOP BREAKPOINT --------------------
const double kDesktopBreakpoint = 900;

//-------------------- STAFF MANAGEMENT SCREEN --------------------
class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  //-------------------- GET INITIALS FROM NAME --------------------
  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  //-------------------- AVATAR COLOR (Gold tints) --------------------
  Color _colorFor(String name) {
    final opacities = [0.12, 0.20, 0.28, 0.36, 0.44];
    final index = name.isNotEmpty ? name.codeUnitAt(0) % opacities.length : 0;
    return accentController.value.withValues(alpha: opacities[index]);
  }

  //-------------------- ADD STAFF DIALOG (Premium) --------------------
  void _showAddStaffDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading = false;
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final card = isDark ? AppColors.darkCard : AppColors.lightCard;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              backgroundColor: isDark ? AppColors.darkBg : Colors.white,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: isDark
                        ? accentController.value.withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //-------------------- DIALOG HEADER --------------------
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Add Staff Member',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? accentController.value
                                  : Colors.black87,
                              fontFamily: isDark ? 'PlayfairDisplay' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    //-------------------- FORM FIELDS --------------------
                    Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _DialogField(
                            controller: nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            isDark: isDark,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _DialogField(
                            controller: emailController,
                            label: 'Email Address',
                            icon: Icons.mail_outline,
                            isDark: isDark,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || !v.contains('@')
                                ? 'Invalid email'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _DialogField(
                            controller: phoneController,
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            isDark: isDark,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          StatefulBuilder(
                            builder: (context, setPwState) => _DialogField(
                              controller: passwordController,
                              label: 'Password',
                              icon: Icons.lock_outline,
                              isDark: isDark,
                              obscureText: obscurePassword,
                              validator: (v) => v == null || v.length < 6
                                  ? 'Min 6 characters'
                                  : null,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                onPressed: () => setPwState(
                                  () => obscurePassword = !obscurePassword,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    //-------------------- DIALOG ACTIONS --------------------
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    setStateDialog(() => isLoading = true);
                                    try {
                                      await _authService.createStaffAccount(
                                        name: nameController.text,
                                        email: emailController.text,
                                        password: passwordController.text,
                                        phone: phoneController.text,
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Staff account created ✨',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor:
                                                accentController.value,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setStateDialog(() => isLoading = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor: AppColors.danger,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentController.value.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_circle_outline,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Add Staff',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  //-------------------- EDIT STAFF DIALOG (Premium) --------------------
  void _showEditStaffDialog(UserModel staff) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: staff.name);
    final phoneController = TextEditingController(text: staff.phone);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final card = isDark ? AppColors.darkCard : AppColors.lightCard;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              backgroundColor: isDark ? AppColors.darkBg : Colors.white,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBg : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: isDark
                        ? accentController.value.withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //-------------------- DIALOG HEADER --------------------
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Update Staff details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? accentController.value
                                  : Colors.black87,
                              fontFamily: isDark ? 'PlayfairDisplay' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    //-------------------- FORM FIELDS --------------------
                    Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _DialogField(
                            controller: nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            isDark: isDark,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _DialogField(
                            controller: phoneController,
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            isDark: isDark,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    //-------------------- ACTION BUTTONS --------------------
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) {
                                      return;
                                    }
                                    setStateDialog(() => isLoading = true);
                                    try {
                                      await _authService.updateStaffInfo(
                                        uid: staff.uid,
                                        name: nameController.text.trim(),
                                        phone: phoneController.text.trim(),
                                      );
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Staff details updated ✨',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor:
                                                accentController.value,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setStateDialog(() => isLoading = false);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor: AppColors.danger,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentController.value.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.save_outlined,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  //-------------------- READ-ONLY STAFF DETAILS (Premium) --------------------
  void _showStaffDetails(UserModel staff) {
    final avatarBg = _colorFor(staff.name);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBg : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: isDark
                  ? accentController.value.withValues(alpha: 0.1)
                  : Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //-------------------- PROFILE HEADER --------------------
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accentController.value.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _getInitials(staff.name),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? accentController.value
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? accentController.value
                                : Colors.black87,
                            fontFamily: isDark ? 'PlayfairDisplay' : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () async {
                            await _authService.toggleStaffStatus(staff.uid, staff.isActive);
                            if (mounted) Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (staff.isActive ? const Color(0xFF22C55E) : AppColors.danger)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (staff.isActive ? const Color(0xFF22C55E) : AppColors.danger)
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: staff.isActive ? const Color(0xFF22C55E) : AppColors.danger,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  staff.isActive ? 'Active (Click to Disable)' : 'Inactive (Click to Enable)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: staff.isActive ? const Color(0xFF22C55E) : AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              //-------------------- DETAILS CARD --------------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? accentController.value.withValues(alpha: 0.08)
                        : Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.mail_outline,
                      label: 'Email',
                      value: staff.email,
                      isDark: isDark,
                    ),
                    const Divider(height: 16),
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: staff.phone,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              //-------------------- ACTION BUTTONS --------------------
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _showEditStaffDialog(staff);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accentController.value,
                              Color.lerp(accentController.value, Colors.black, 0.2)!,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: accentController.value.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Update',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Status Toggle Button (Active/Inactive)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    backgroundColor: (staff.isActive
                            ? const Color(0xFF22C55E)
                            : AppColors.danger)
                        .withValues(alpha: 0.1),
                    foregroundColor: staff.isActive
                        ? const Color(0xFF22C55E)
                        : AppColors.danger,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    await _authService.toggleStaffStatus(staff.uid, staff.isActive);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        staff.isActive ? Icons.toggle_on : Icons.toggle_off_outlined,
                        size: 18,
                        color: staff.isActive ? const Color(0xFF22C55E) : AppColors.danger,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        staff.isActive ? 'Disable Staff' : 'Enable Staff',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: staff.isActive ? const Color(0xFF22C55E) : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
              // Danger Zone: Remove Staff
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    foregroundColor: AppColors.danger,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmDelete(staff);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                      SizedBox(width: 6),
                      Text(
                        'Remove Staff Member',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //-------------------- DELETE STAFF CONFIRMATION --------------------
  void _confirmDelete(UserModel staff) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.danger,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Remove Staff',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Remove ${staff.name} from staff list? This action cannot be undone.',
          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              await _authService.deleteStaffAccount(staff.uid);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminSidebar(
                          currentRoute: 'Staff',
                        ),
                        Expanded(
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
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

                //-------------------- MOBILE: PLAIN SCAFFOLD --------------------
                return Scaffold(
                  backgroundColor: bg,
                  drawer: const Drawer(width: 230, child: AdminSidebar(currentRoute: "Staff")),
                  floatingActionButton: FloatingActionButton(
                    onPressed: _showAddStaffDialog,
                    backgroundColor: accent,
                    child: const Icon(Icons.add, color: Colors.white),
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

  //==================== SHARED CONTENT ====================
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
                      border: Border.all(color: border, width: 0.8),
                    ),
                    child: Icon(Icons.menu, size: 20, color: textPrimary),
                  ),
                ),
              ),
              AdminHeaderActions(isDesktop: false),
            ],
          ),
          const SizedBox(height: 16),
        ],
        //-------------------- HEADER --------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? accentController.value : textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Staff Management',
                    style: TextStyle(
                      fontSize: isDesktop ? 26 : 19,
                      fontWeight: FontWeight.w600,
                      color: isDark ? accentController.value : textPrimary,
                      fontFamily: isDark ? 'PlayfairDisplay' : null,
                    ),
                  ),
                ],
              ),
            ),
            if (isDesktop) ...[
              GestureDetector(
                onTap: _showAddStaffDialog,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Add staff',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AdminHeaderActions(isDesktop: true),
            ],
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
              hintText: 'Search by name, email or phone...',
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

        //-------------------- SCROLLABLE STATS + GROUPED LIST --------------------
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _authService.getStaffList(),
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

              final allStaff = snapshot.data ?? [];

              final totalStaff = allStaff.length;
              final now = DateTime.now();
              final addedThisMonth = allStaff.where((s) {
                try {
                  final created = (s as dynamic).createdAt as DateTime?;
                  return created != null &&
                      created.year == now.year &&
                      created.month == now.month;
                } catch (_) {
                  return false;
                }
              }).length;

              var staffList = allStaff;
              if (_searchQuery.isNotEmpty) {
                staffList = staffList
                    .where(
                      (s) =>
                          s.name.toLowerCase().contains(_searchQuery) ||
                          s.email.toLowerCase().contains(_searchQuery) ||
                          s.phone.contains(_searchQuery),
                    )
                    .toList();
              }

              final sorted = List<UserModel>.from(staffList)
                ..sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );

              final Map<String, List<UserModel>> grouped = {};
              for (var staff in sorted) {
                final letter = staff.name.isNotEmpty
                    ? staff.name[0].toUpperCase()
                    : '#';
                grouped.putIfAbsent(letter, () => []).add(staff);
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    //-------------------- STAT CARDS ROW --------------------
                    Row(
                      children: [
                        Expanded(
                          child: _StatMiniCard(
                            label: 'Total staff',
                            value: '$totalStaff',
                            icon: Icons.people_outline,
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
                            label: 'Added this month',
                            value: '$addedThisMonth',
                            icon: Icons.person_add_alt_1,
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

                    //-------------------- GROUPED LIST --------------------
                    if (staffList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 48,
                                color: textMuted.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                allStaff.isEmpty
                                    ? 'No staff members yet'
                                    : 'No staff found',
                                style: TextStyle(color: textMuted),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...grouped.entries.map((entry) {
                        final letter = entry.key;
                        final group = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                letter,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? accentController.value
                                      : textSecondary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: card,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.card,
                                  ),
                                  border: Border.all(
                                    color: isDark
                                        ? accentController.value.withValues(
                                            alpha: 0.1,
                                          )
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
                                child: Column(
                                  children: List.generate(group.length, (i) {
                                    final staff = group[i];
                                    final isLast = i == group.length - 1;
                                    final avatarBg = _colorFor(staff.name);

                                    return Column(
                                      children: [
                                        _StaffRow(
                                          staff: staff,
                                          initials: _getInitials(staff.name),
                                          avatarBg: avatarBg,
                                          textPrimary: textPrimary,
                                          textSecondary: textSecondary,
                                          isDark: isDark,
                                          onTap: () => _showStaffDetails(staff),
                                          onEdit: () => _showEditStaffDialog(staff),
                                          onDelete: () => _confirmDelete(staff),
                                          onToggleStatus: () => _authService
                                              .toggleStaffStatus(staff.uid, staff.isActive),
                                          ),
                                          if (!isLast)
                                          Divider(
                                            color: isDark
                                                ? accentController.value
                                                      .withValues(alpha: 0.08)
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
                            ],
                          ),
                        );
                      }),
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
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProductListScreen()),
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
            onTap: () {},
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

//-------------------- STAT MINI CARD WIDGET (Premium) --------------------
class _StatMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _StatMiniCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isDark ? accentController.value.withValues(alpha: 0.1) : border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.transparent,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark
                  ? accentController.value.withValues(alpha: 0.08)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: isDark ? accentController.value : AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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

//-------------------- STAFF ROW WIDGET (Premium) --------------------
class _StaffRow extends StatelessWidget {
  final UserModel staff;
  final String initials;
  final Color avatarBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const _StaffRow({
    super.key,
    required this.staff,
    required this.initials,
    required this.avatarBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            //-------------------- AVATAR WITH GOLD BORDER --------------------
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: avatarBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? accentController.value.withValues(alpha: 0.2)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? accentController.value : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),

            //-------------------- NAME + EMAIL --------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? accentController.value : textPrimary,
                      fontFamily: isDark ? 'PlayfairDisplay' : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        staff.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: (staff.isActive ? const Color(0xFF22C55E) : AppColors.danger)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          staff.isActive ? 'Active' : 'Disabled',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: staff.isActive ? const Color(0xFF22C55E) : AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            //-------------------- ACTIONS --------------------
            Builder(
              builder: (context) {
                final isDesktop = MediaQuery.of(context).size.width >= 600;
                if (isDesktop) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // STATUS TOGGLE BUTTON (Active/Inactive)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: (staff.isActive ? const Color(0xFF22C55E) : AppColors.danger)
                              .withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            staff.isActive ? Icons.toggle_on : Icons.toggle_off_outlined,
                            size: 20,
                            color: staff.isActive ? const Color(0xFF22C55E) : AppColors.danger,
                          ),
                          onPressed: onToggleStatus,
                          splashRadius: 20,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          tooltip: staff.isActive ? 'Disable staff' : 'Enable staff',
                        ),
                      ),
                      // EDIT STAFF DETAILS BUTTON
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? accentController.value.withValues(alpha: 0.1)
                              : accentController.value.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: accentController.value,
                          ),
                          onPressed: onEdit,
                          splashRadius: 20,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                          tooltip: 'Update details',
                        ),
                      ),
                      // DELETE BUTTON
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          onPressed: onDelete,
                          splashRadius: 20,
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  );
                } else {
                  return PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: textSecondary),
                    onSelected: (val) {
                      if (val == 'toggle') onToggleStatus();
                      if (val == 'edit') onEdit();
                      if (val == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'toggle',
                        child: Row(
                          children: [
                            Icon(
                              staff.isActive ? Icons.toggle_on : Icons.toggle_off_outlined,
                              size: 20,
                              color: staff.isActive ? const Color(0xFF22C55E) : AppColors.danger,
                            ),
                            const SizedBox(width: 8),
                            Text(staff.isActive ? 'Disable' : 'Enable'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

//-------------------- DETAIL ROW WIDGET (for staff details dialog) --------------------
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark
                ? accentController.value.withValues(alpha: 0.08)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isDark ? accentController.value : Colors.grey[600],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

//-------------------- REUSABLE DIALOG TEXT FIELD (Premium) --------------------
class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool isDark;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? accentController.value : Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: isDark ? accentController.value : Colors.grey[400],
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.grey.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? accentController.value.withValues(alpha: 0.15)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? accentController.value.withValues(alpha: 0.15)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accentController.value, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
      ),
    );
  }
}