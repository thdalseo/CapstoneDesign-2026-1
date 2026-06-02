import 'package:flutter/material.dart';

/// 이름 기반으로 아바타 배경색을 일관되게 결정하는 유틸리티
const _kAvatarColors = [
  Color(0xFF4C80AF),
  Color(0xFF3ABBA0),
  Color(0xFF8B5CF6),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFFEC4899),
  Color(0xFF10B981),
  Color(0xFF6366F1),
];

/// 이름 → 고정 색상 (같은 이름은 항상 같은 색)
Color avatarColorFor(String name) {
  if (name.isEmpty) return _kAvatarColors[0];
  int hash = 0;
  for (final c in name.runes) {
    hash = (hash * 31 + c) & 0x7FFFFFFF;
  }
  return _kAvatarColors[hash % _kAvatarColors.length];
}

/// 이름 첫 글자 (대문자)
String avatarInitial(String name) {
  if (name.isEmpty) return '?';
  return name[0].toUpperCase();
}
