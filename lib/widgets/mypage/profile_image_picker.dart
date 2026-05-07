import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ProfileImagePicker extends StatelessWidget {
  final VoidCallback? onTap;

  const ProfileImagePicker({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8F0FE),
              border: Border.all(color: const Color(0xFFD0DCEF), width: 1),
            ),
            child: const Icon(Icons.person, size: 50, color: Color(0xFFB0C4DE)),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
