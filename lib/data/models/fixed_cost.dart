class FixedCost {
  final String id;
  final String label;
  final double amount;
  final bool isPreset;

  const FixedCost({
    required this.id,
    required this.label,
    required this.amount,
    this.isPreset = false,
  });

  FixedCost copyWith({
    String? id,
    String? label,
    double? amount,
    bool? isPreset,
  }) {
    return FixedCost(
      id: id ?? this.id,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      isPreset: isPreset ?? this.isPreset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'amount': amount,
      'isPreset': isPreset,
    };
  }

  factory FixedCost.fromMap(Map<String, dynamic> map) {
    return FixedCost(
      id: map['id'] as String? ?? '',
      label: map['label'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      isPreset: map['isPreset'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FixedCost &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          label == other.label &&
          amount == other.amount &&
          isPreset == other.isPreset;

  @override
  int get hashCode =>
      id.hashCode ^ label.hashCode ^ amount.hashCode ^ isPreset.hashCode;
}
