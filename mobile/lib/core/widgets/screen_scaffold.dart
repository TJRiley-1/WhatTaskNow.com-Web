import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Common scaffold for non-tabbed screens with a back button and title
class ScreenScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onBack;
  final String? stepIndicator;
  final List<Widget>? actions;

  const ScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.onBack,
    this.stepIndicator,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                onPressed: onBack,
              )
            : null,
        title: Text(title),
        centerTitle: true,
        actions: [
          if (stepIndicator != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  stepIndicator!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          if (actions != null) ...actions!,
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}
