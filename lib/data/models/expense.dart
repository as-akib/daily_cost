class Expense {
  final String id;
  final double amount;
  final String currency;
  final double amountInBaseCurrency;
  final String category;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.currency,
    required this.amountInBaseCurrency,
    required this.category,
    this.note,
    required this.date,
    required this.createdAt,
  });

  Expense copyWith({
    String? id,
    double? amount,
    String? currency,
    double? amountInBaseCurrency,
    String? category,
    String? note,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      amountInBaseCurrency: amountInBaseCurrency ?? this.amountInBaseCurrency,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'amountInBaseCurrency': amountInBaseCurrency,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'amount_in_base_currency': amountInBaseCurrency,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val != null) {
        try {
          final dynamic dyn = val;
          if (dyn.toDate is Function) {
            return dyn.toDate() as DateTime;
          }
        } catch (_) {}
      }
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return Expense(
      id: docId.isNotEmpty ? docId : (map['id'] as String? ?? ''),
      amount: ((map['amount']) as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'USD',
      amountInBaseCurrency:
          ((map['amountInBaseCurrency'] ?? map['amount_in_base_currency']) as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'other',
      note: map['note'] as String?,
      date: parseDate(map['date']),
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
    );
  }
}
