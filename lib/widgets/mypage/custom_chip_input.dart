import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'hover_button.dart';

class CustomChipInput extends StatelessWidget {
  final TextEditingController controller;
  final List<String> customItems;
  final String hintText;
  final VoidCallback onAdd;
  final void Function(String) onRemove;

  const CustomChipInput({
    super.key,
    required this.controller,
    required this.customItems,
    required this.hintText,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (customItems.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: customItems.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.mint.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.mint),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item,
                      style: const TextStyle(fontSize: 13, color: AppTheme.mint),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onRemove(item),
                      child: const Icon(Icons.close, size: 14, color: AppTheme.mint),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) => onAdd(),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(fontSize: 13),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDDE4EE)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDDE4EE)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64),
              child: HoverButton(
                label: 'edit_profile.add'.tr(),
                onPressed: onAdd,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
