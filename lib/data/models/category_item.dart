import 'package:flutter/material.dart';

class CategoryItem {
  final String id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final bool isCustom;
  final bool isHidden;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    this.isCustom = false,
    this.isHidden = false,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get iconData => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Color get color => Color(colorValue);

  CategoryItem copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    bool? isCustom,
    bool? isHidden,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isCustom: isCustom ?? this.isCustom,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
      'isCustom': isCustom,
      'isHidden': isHidden,
    };
  }

  factory CategoryItem.fromMap(Map<String, dynamic> map, String docId) {
    return CategoryItem(
      id: docId.isNotEmpty ? docId : (map['id'] as String? ?? ''),
      name: map['name'] as String? ?? '',
      iconCodePoint: (map['iconCodePoint'] as num?)?.toInt() ?? 0xe402,
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFF64748B,
      isCustom: map['isCustom'] as bool? ?? false,
      isHidden: map['isHidden'] as bool? ?? false,
    );
  }
}
