import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/screen_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSignUpMode = false;
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;
  bool _showResendButton = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabase = ref.read(supabaseDatasourceProvider);
      await supabase.signInWithGoogle();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = 'Google sign in failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _showResendButton = false;
    });

    try {
      final supabase = ref.read(supabaseDatasourceProvider);
      await supabase.signInWithEmail(email, password);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        if (msg.contains('Email not confirmed') || msg.contains('confirm')) {
          setState(() {
            _error = 'Email not confirmed. Check your inbox or resend the link.';
            _showResendButton = true;
          });
        } else {
          setState(() => _error = 'Sign in failed: $msg');
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendConfirmation() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseDatasourceProvider);
      await supabase.resendConfirmation(email);
      if (mounted) {
        setState(() {
          _error = 'Confirmation email sent! Check your inbox.';
          _showResendButton = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to resend: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createAccount() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = ref.read(supabaseDatasourceProvider);
      await supabase.signUp(email, password,
          displayName: name.isNotEmpty ? name : null);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = 'Sign up failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: _isSignUpMode ? 'Create Account' : 'Sign In',
      onBack: () => context.pop(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // Google sign-in
            GlassButton(
              label: 'Continue with Google',
              onPressed: _isLoading ? null : _signInWithGoogle,
              isLoading: _isLoading,
              icon: const Icon(Icons.g_mobiledata_rounded,
                  color: Colors.white, size: 24),
            ),

            const SizedBox(height: 24),

            // Divider with "or"
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.glassBorder,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'or',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.glassBorder,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Email & password fields inside a glass card
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Name field (sign-up mode only)
                  if (_isSignUpMode) ...[
                    _GlassTextField(
                      controller: _nameController,
                      label: 'Display Name',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _GlassTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),

                  const SizedBox(height: 16),

                  _GlassTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _isSignUpMode
                        ? _createAccount()
                        : _signInWithEmail(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ],
              ),
            ),

            // Error display
            if (_error != null) ...[
              const SizedBox(height: 16),
              GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: _error!.contains('sent') || _error!.contains('Sent')
                    ? Colors.green
                    : AppColors.error,
                child: Row(
                  children: [
                    Icon(
                      _error!.contains('sent') || _error!.contains('Sent')
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      color: _error!.contains('sent') || _error!.contains('Sent')
                          ? Colors.green
                          : AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: _error!.contains('sent') || _error!.contains('Sent')
                              ? Colors.green
                              : AppColors.error,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Resend confirmation button
            if (_showResendButton) ...[
              const SizedBox(height: 12),
              GlassButton(
                label: 'Resend Confirmation Email',
                variant: GlassButtonVariant.outline,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _resendConfirmation,
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            if (_isSignUpMode) ...[
              GlassButton(
                label: 'Create Account',
                isLarge: true,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _createAccount,
              ),
              const SizedBox(height: 12),
              GlassButton(
                label: 'Already have an account? Sign In',
                variant: GlassButtonVariant.outline,
                onPressed: () => setState(() {
                  _isSignUpMode = false;
                  _error = null;
                  _showResendButton = false;
                }),
              ),
            ] else ...[
              GlassButton(
                label: 'Sign In',
                isLarge: true,
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _signInWithEmail,
              ),
              const SizedBox(height: 12),
              GlassButton(
                label: 'Create Account',
                variant: GlassButtonVariant.secondary,
                onPressed: () => setState(() {
                  _isSignUpMode = true;
                  _error = null;
                  _showResendButton = false;
                }),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Continue without account
            Center(
              child: TextButton(
                onPressed: () => context.go('/home'),
                child: const Text(
                  'Continue without account',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  const _GlassTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.glassWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
