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

  static const Map<int, IconData> _iconRegistry = {
    0xe532: Icons.restaurant_rounded,
    0xe1d5: Icons.directions_bus_rounded,
    0xf2ea: Icons.receipt_long_rounded,
    0xf016e: Icons.shopping_bag_rounded,
    0xe406: Icons.movie_rounded,
    0xe395: Icons.local_hospital_rounded,
    0xe391: Icons.local_grocery_store_rounded,
    0xe318: Icons.home_rounded,
    0xe402: Icons.more_horiz_rounded,
    0xe177: Icons.coffee_rounded,
    0xe3cb: Icons.local_bar_rounded,
    0xe1d7: Icons.directions_car_rounded,
    0xe1e1: Icons.flight_rounded,
    0xf071b: Icons.electric_bolt_rounded,
    0xe6c4: Icons.wifi_rounded,
    0xf639: Icons.checkroom_rounded,
    0xe5d2: Icons.sports_esports_rounded,
    0xe405: Icons.music_note_rounded,
    0xe29e: Icons.fitness_center_rounded,
    0xe5ca: Icons.spa_rounded,
    0xe496: Icons.pets_rounded,
    0xe556: Icons.school_rounded,
    0xe55a: Icons.work_rounded,
    0xf014d: Icons.savings_rounded,
    0xe1b8: Icons.card_giftcard_rounded,
    0xe112: Icons.brush_rounded,
    0xe4a2: Icons.phone_android_rounded,
    0xe0bb: Icons.beach_access_rounded,
    0xe104: Icons.build_rounded,
  };

  IconData get iconData => _iconRegistry[iconCodePoint] ?? Icons.category_rounded;

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
