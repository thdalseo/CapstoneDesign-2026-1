import 'package:flutter/material.dart';

/// 아바타 배경색
const _kAvatarColors = [
       
  Color(0xFFA78BFA),
  Color(0xFFFBBF24),       
  Color(0xFFFC7171),       
  Color(0xFFF472B6),       
  Color(0xFF34D399),       
  Color(0xFF818CF8),       
];

/// 이름 → 고정 색상
Color avatarColorFor(String name) {
  if (name.isEmpty) return _kAvatarColors[0];
  int hash = 0;
  for (final c in name.runes) {
    hash = (hash * 31 + c) & 0x7FFFFFFF;
  }
  return _kAvatarColors[hash % _kAvatarColors.length];
}

/// 이름 첫 글자
String avatarInitial(String name) {
  if (name.isEmpty) return '?';
  return name[0].toUpperCase();
}
