import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:solar_icons/solar_icons.dart';

import 'package:roommate_finder/config/app_colors.dart';

/// Glass text field. Replaces `custom_text_field.dart`.
///
/// The label is a real visible label, not a placeholder - a hint that vanishes
/// on focus leaves the user guessing what the field was for.
///
/// `errorText` is passed in rather than held here, so it can be derived from the
/// parent's state and never goes stale after a fix (DESIGN.md "Form validation").
class MkTextField extends StatefulWidget {
  const MkTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.onChanged,
    this.errorText,
    this.optional = false,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final void Function(String)? onChanged;

  /// Derived by the caller; shown inline under the field.
  final String? errorText;

  /// Marks the field optional in the label, so everything else reads as required
  /// without a wall of asterisks.
  final bool optional;

  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  @override
  State<MkTextField> createState() => _MkTextFieldState();
}

class _MkTextFieldState extends State<MkTextField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final radius = BorderRadius.circular(14.r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.textInk,
              ),
            ),
            if (widget.optional) ...[
              SizedBox(width: 6.w),
              Text(
                '(optional)',
                style: TextStyle(fontSize: 12.sp, color: AppColors.textFaint),
              ),
            ],
          ],
        ),
        SizedBox(height: 7.h),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText && _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          onChanged: widget.onChanged,
          enabled: widget.enabled,
          autofillHints: widget.autofillHints,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitted,
          style: TextStyle(fontSize: 15.sp, color: AppColors.textInk),
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: true,
            fillColor: AppColors.glassFillSubtle,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Padding(
                    padding: EdgeInsets.only(left: 14.w, right: 10.w),
                    child: Icon(
                      widget.prefixIcon,
                      size: 20.sp,
                      color: hasError ? AppColors.error : AppColors.primary,
                    ),
                  ),
            prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? SolarIconsOutline.eyeClosed
                          : SolarIconsOutline.eye,
                      size: 20.sp,
                      color: AppColors.textMuted,
                    ),
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : widget.suffixIcon,
            // Errors render below the field instead of in the decoration, so the
            // border and the message can't disagree about error state.
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: AppColors.glassBorderInk),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.glassBorderInk,
                width: hasError ? 1.4 : 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
                width: 1.8,
              ),
            ),
          ),
        ),
        // AnimatedSize so the layout shift when an error appears is explained
        // rather than abrupt.
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: EdgeInsets.only(top: 6.h, left: 4.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        SolarIconsOutline.infoCircle,
                        size: 13.sp,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 5.w),
                      Expanded(
                        child: Text(
                          widget.errorText!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
