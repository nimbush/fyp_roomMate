import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:roommate_finder/config/app_colors.dart';

class OtpField extends StatefulWidget {
  final int length;
  final void Function(String) onCompleted;
  final void Function(String)? onChanged;

  const OtpField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
  });

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < widget.length && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final nextIndex = (digits.length).clamp(0, widget.length - 1);
      _nodes[nextIndex].requestFocus();
    } else if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _nodes[index + 1].requestFocus();
      } else {
        _nodes[index].unfocus();
      }
    }

    widget.onChanged?.call(_otp);
    if (_otp.length == widget.length) {
      widget.onCompleted(_otp);
    }
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _nodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Size the boxes from the space actually available rather than a fixed
    // width: 6 fixed-width boxes overflow the card once padding is accounted
    // for, and the overflow only appears at this exact box count.
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final available = constraints.maxWidth - gap * widget.length;
        final boxWidth =
            (available / widget.length).clamp(34.0, 46.r.toDouble());

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _boxes(boxWidth, gap / 2),
        );
      },
    );
  }

  List<Widget> _boxes(double boxWidth, double sideGap) {
    return List.generate(widget.length, (i) {
        // A filled box gets the accent treatment, so progress through the code
        // is visible at a glance rather than only from the digits.
        final filled = _controllers[i].text.isNotEmpty;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: sideGap),
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (e) => _onKeyEvent(i, e),
            child: SizedBox(
              width: boxWidth,
              height: 56.r,
              child: TextFormField(
                controller: _controllers[i],
                focusNode: _nodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 21.sp,
                  fontWeight: FontWeight.w800,
                  color: filled ? AppColors.accentInk : AppColors.textInk,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: filled
                      ? AppColors.primarySoft
                      : AppColors.glassFillSubtle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(color: AppColors.glassBorderInk),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(
                      color: filled
                          ? AppColors.primary.withValues(alpha: 0.45)
                          : AppColors.glassBorderInk,
                      width: filled ? 1.4 : 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => _onChanged(i, v),
              ),
            ),
          ),
        );
    });
  }
}
