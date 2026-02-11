import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_button.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final supabase = ref.read(supabaseDatasourceProvider);
      await supabase.signInWithGoogle();
      if (mounted) context.go('/tutorial');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo / icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryLight,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 24),

              // App title
              const Text(
                'What Now?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'Stop overthinking. Start doing.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 40),

              // Feature bullets
              GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _FeatureBullet(
                      icon: Icons.label_rounded,
                      text: 'Add tasks with tags',
                    ),
                    const SizedBox(height: 16),
                    _FeatureBullet(
                      icon: Icons.auto_awesome_rounded,
                      text: 'Get smart suggestions',
                    ),
                    const SizedBox(height: 16),
                    _FeatureBullet(
                      icon: Icons.emoji_events_rounded,
                      text: 'Earn points & level up',
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Google sign-in button
              GlassButton(
                label: 'Sign in with Google',
                onPressed: _isLoading ? null : _signInWithGoogle,
                isLoading: _isLoading,
                isLarge: true,
                icon: const Icon(Icons.g_mobiledata_rounded,
                    color: Colors.white, size: 24),
              ),

              const SizedBox(height: 12),

              // Continue as Guest button
              GlassButton(
                label: 'Continue as Guest',
                variant: GlassButtonVariant.outline,
                isLarge: true,
                onPressed: () => context.go('/tutorial'),
              ),

              const SizedBox(height: 16),

              // Device-only note
              const Text(
                'Your tasks stay on this device.\nSign in later to sync.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
          child: Icon(icon, color: AppColors.primaryLight, size: 22),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
