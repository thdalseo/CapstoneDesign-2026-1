import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GridChips extends StatelessWidget {
  final List<String> items;
  final List<String> selected;
  final void Function(String) onTap;
  final int crossAxisCount;

  const GridChips({
    super.key,
    required this.items,
    required this.selected,
    required this.onTap,
    this.crossAxisCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    const spacing = 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
        final rows = <Widget>[];

        for (int i = 0; i < items.length; i += crossAxisCount) {
          final end = min(i + crossAxisCount, items.length);
          final rowItems = items.sublist(i, end);
          final rowChildren = <Widget>[];

          for (int j = 0; j < rowItems.length; j++) {
            if (j > 0) rowChildren.add(const SizedBox(width: spacing));
            final item = rowItems[j];
            final isSelected = selected.contains(item);
            rowChildren.add(
              GestureDetector(
                onTap: () => onTap(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: itemWidth,
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          }

          rows.add(Row(children: rowChildren));
          if (end < items.length) rows.add(const SizedBox(height: spacing));
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
      },
    );
  }
}
