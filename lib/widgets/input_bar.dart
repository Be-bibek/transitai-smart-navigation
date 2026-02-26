import 'dart:ui';
import 'package:flutter/material.dart';

/// Glass-style text input bar with send button.
class InputBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onSend;

  const InputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
  });

  @override
  State<InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<InputBar>
    with SingleTickerProviderStateMixin {
  bool _hasText = false;

  late final AnimationController _sendCtrl = AnimationController(
    duration: const Duration(milliseconds: 180),
    vsync: this,
  );
  late final Animation<double> _sendScale =
      Tween<double>(begin: 1.0, end: 0.88)
          .animate(CurvedAnimation(parent: _sendCtrl, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = widget.controller.text.isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  void _onSendTap() async {
    if (!_hasText) return;
    await _sendCtrl.forward();
    await _sendCtrl.reverse();
    widget.onSend(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _sendCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.20),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                  cursorColor: const Color(0xFF4FC3F7),
                  cursorWidth: 2,
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: widget.onSend,
                  decoration: InputDecoration(
                    hintText: 'Ask anything…',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Send button
              ScaleTransition(
                scale: _sendScale,
                child: GestureDetector(
                  onTap: _onSendTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _hasText
                          ? const LinearGradient(
                              colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: _hasText
                          ? null
                          : Colors.white.withValues(alpha: 0.08),
                      boxShadow: _hasText
                          ? [
                              BoxShadow(
                                color:
                                    const Color(0xFF4FC3F7).withValues(alpha: 0.45),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: _hasText
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
