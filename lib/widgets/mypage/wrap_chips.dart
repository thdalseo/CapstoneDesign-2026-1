import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class WrapChips extends StatelessWidget {
  final List<String> items;
  final List<String> selected;
  final void Function(String) onTap;

  const WrapChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selected.contains(item);
        return GestureDetector(
          onTap: () => onTap(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? AppTheme.primary : const Color(0xFFDDE4EE),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
