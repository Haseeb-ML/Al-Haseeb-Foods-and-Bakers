import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../admin/admin_dashboard.dart';
import '../staff/staff_dashboard.dart';
import '../../theme/app_theme.dart';

//-------------------- LOGIN SCREEN WIDGET --------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //-------------------- VARIABLES & CONTROLLERS --------------------
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'Admin';

  //-------------------- DISPOSE CONTROLLERS --------------------
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //-------------------- LOGIN LOGIC --------------------
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final UserModel? user = await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (user != null && mounted) {
        final expectedRole = _selectedRole.toLowerCase();
        if (user.role != expectedRole) {
          await _authService.logout();
          throw 'Role mismatch! Please select your correct login role.';
        }

        if (user.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminDashboard(user: user)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => StaffDashboard(user: user)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.danger,
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

  //-------------------- FORGOT PASSWORD LOGIC --------------------
  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your email address first'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.amber.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset link sent to your email'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.danger,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  //-------------------- INPUT FIELD STYLING --------------------
  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData prefixIcon,
    required Color textMuted,
    required Color card,
    required Color border,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(prefixIcon, size: 18),
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(color: textMuted, fontSize: 13),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
      ),
    );
  }

  //-------------------- BUILD UI --------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final card = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      Center(
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/bakery_logo.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      //-------------------- APP HEADERS --------------------
                      Text(
                        'AL-HASEEB',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Foods & Bakers',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 50,
                        height: 2,
                        color: AppColors.primary,
                        margin: const EdgeInsets.symmetric(horizontal: 150),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Welcome back! Sign in to continue',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),

                       //-------------------- ROLE SELECTION --------------------
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        dropdownColor: card,
                        decoration: _buildInputDecoration(
                          labelText: 'Login As',
                          prefixIcon: Icons.badge_outlined,
                          textMuted: textMuted,
                          card: card,
                          border: border,
                        ),
                        items: ['Admin', 'Staff'].map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRole = val);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      //-------------------- EMAIL FIELD --------------------
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _buildInputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icons.mail_outline_rounded,
                          textMuted: textMuted,
                          card: card,
                          border: border,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      //-------------------- PASSWORD FIELD --------------------
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _buildInputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icons.lock_outline_rounded,
                          textMuted: textMuted,
                          card: card,
                          border: border,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: textMuted,
                              size: 18,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                        ),
                        onFieldSubmitted: (_) => _handleLogin(),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Password is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),

                      //-------------------- FORGOT PASSWORD --------------------
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _handleForgotPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: const Size(0, 30),
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      //-------------------- LOGIN BUTTON --------------------
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppColors.primary
                                .withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.button,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),


                      const SizedBox(height: 16),

                      //-------------------- FOOTER --------------------
                      Center(
                        child: Text(
                          '© 2026 Al-Haseeb. All rights reserved.',
                          style: TextStyle(
                            fontSize: 10,
                            color: textMuted.withOpacity(0.5),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
