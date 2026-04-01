import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';

import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class SocialLoginButtons extends StatelessWidget {
  final bool isSignUp;

  const SocialLoginButtons({super.key, this.isSignUp = false});

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final provider = context.read<AppProvider>();
    final success = await provider.signInWithGoogle();

    if (success && context.mounted) {
      Navigator.of(context).pushReplacementNamed('/main');
    } else if (context.mounted && provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: AppColors.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = isSignUp ? 'Sign up with social account' : 'Sign in with social account';

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialButton(
              svgPath: 'icons/google.svg',
              onTap: () => _handleGoogleSignIn(context),
            ),
            const SizedBox(width: 16),
            _SocialButton(
              svgPath: 'icons/apple.svg',
              onTap: () => _showComingSoon(context, 'Apple'),
            ),
            const SizedBox(width: 16),
            _SocialButton(
              svgPath: 'icons/microsoft.svg',
              onTap: () => _showComingSoon(context, 'Microsoft'),
            ),
            if (!isSignUp) ...[
              const SizedBox(width: 16),
              _SocialButton(
                svgPath: 'icons/linkdin.svg',
                onTap: () => _showComingSoon(context, 'LinkedIn'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider sign-in coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String svgPath;
  final VoidCallback onTap;

  const _SocialButton({
    required this.svgPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: SvgPicture.asset(
            svgPath,
            width: 24,
            height: 24,
          ),
        ),
      ),
    );
  }
}
