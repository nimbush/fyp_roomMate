import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_colors.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (e) => _onKeyEvent(i, e),
            child: SizedBox(
              width: 48,
              height: 58,
              child: TextFormField(
                controller: _controllers[i],
                focusNode: _nodes[i],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => _onChanged(i, v),
              ),
            ),
          ),
        );
      }),
    );
  }
}
