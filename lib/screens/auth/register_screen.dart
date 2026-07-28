import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  //-------------------- VARIABLES & CONTROLLERS --------------------
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final String _role = 'admin';
  bool _isLoading = false;
  bool _obscurePassword = true;

  //-------------------- DISPOSE CONTROLLERS --------------------
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //-------------------- REGISTER LOGIC --------------------
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: _role,
        phone: _phoneController.text,
      );

      if (user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Account created successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
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
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
          padding: const EdgeInsets.all(8),
        ),
      ),
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
                      //-------------------- LOGO DESIGN --------------------
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.15),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            size: 44,
                            color: AppColors.primary,
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
                        'Create your admin account to manage the shop',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      //-------------------- NAME FIELD --------------------
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _buildInputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icons.person_outline_rounded,
                          textMuted: textMuted,
                          card: card,
                          border: border,
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.xs),

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
                          if (value == null || value.trim().isEmpty)
                            return 'Email is required';
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      //-------------------- PHONE FIELD --------------------
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(color: textPrimary, fontSize: 14),
                        decoration: _buildInputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icons.phone_outlined,
                          textMuted: textMuted,
                          card: card,
                          border: border,
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Phone number is required'
                            : null,
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
                        onFieldSubmitted: (_) => _handleRegister(),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Password is required';
                          if (value.length < 6)
                            return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      //-------------------- REGISTER BUTTON --------------------
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRegister,
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
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      //-------------------- OR DIVIDER --------------------
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: border, thickness: 0.8),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: border, thickness: 0.8),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),

                      //-------------------- NAVIGATE TO LOGIN --------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
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
