import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class MyPageMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const MyPageMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? Colors.red.shade400 : AppTheme.textSecondary,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: isDestructive ? Colors.red.shade400 : AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            if (!isDestructive)
              const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFCCCCCC)),
          ],
        ),
      ),
    );
  }
}
