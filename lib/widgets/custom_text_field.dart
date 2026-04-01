import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final String hintText;
  final IconData? prefixIcon;
  final String? prefixSvg;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool enabled;

  const CustomTextField({
    super.key,
    required this.hintText,
    this.prefixIcon,
    this.prefixSvg,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.keyboardType,
    this.enabled = true,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      enabled: widget.enabled,
      style: TextStyle(
        color: isDark ? AppColors.darkText : AppColors.lightText,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          fontSize: 15,
        ),
        prefixIcon: widget.prefixIcon != null
            ? Icon(
                widget.prefixIcon,
                color: isDark ? AppColors.accentTeal : AppColors.accentBlue,
                size: 20,
              )
            : null,
        suffixIcon: widget.isPassword
            ? GestureDetector(
                onTap: () => setState(() => _obscureText = !_obscureText),
                child: Icon(
                  _obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }
}
