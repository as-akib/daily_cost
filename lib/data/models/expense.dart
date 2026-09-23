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
      'date': date.toUtc().toIso8601String(),
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val.toLocal();
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed.toLocal();
      }
      return DateTime.now();
    }

    final rawId = docId.isNotEmpty
        ? docId
        : ((map['id'] ?? map['doc_id']) as String? ?? '');
    final validId = rawId.trim().isNotEmpty
        ? rawId
        : 'exp_${DateTime.now().microsecondsSinceEpoch}_${(map['amount'] ?? 0)}';

    final num? rawAmount = (map['amount'] ?? map['amountInBaseCurrency'] ?? map['amount_in_base_currency']) as num?;
    final double parsedAmount = rawAmount?.toDouble() ?? 0.0;

    return Expense(
      id: validId,
      amount: parsedAmount,
      currency: map['currency'] as String? ?? 'BDT',
      amountInBaseCurrency: parsedAmount,
      category: map['category'] as String? ?? 'food',
      note: map['note'] as String?,
      date: parseDate(map['date']),
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
    );
  }
}