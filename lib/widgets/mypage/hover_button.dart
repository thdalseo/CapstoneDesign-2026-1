import 'package:flutter/material.dart';

class HoverButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final double? width;
  final double? height;
  final double fontSize;

  const HoverButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.color,
    this.width,
    this.height,
    this.fontSize = 13,
  });

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          height: widget.height,
          alignment: Alignment.center,
          padding: widget.width == null
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
              : null,
          decoration: BoxDecoration(
            color: _hovered ? widget.color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.color),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _hovered ? Colors.white : widget.color,
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
