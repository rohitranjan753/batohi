import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final String id;
  final String tripId;
  final String userId;
  final String title;
  final String? description;
  final double amount;
  final String currency;
  final String category;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Expense({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.title,
    this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'USD',
      category: data['category'] ?? 'Other',
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'userId': userId,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Expense copyWith({
    String? id,
    String? tripId,
    String? userId,
    String? title,
    String? description,
    double? amount,
    String? currency,
    String? category,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tripId,
        userId,
        title,
        description,
        amount,
        currency,
        category,
        date,
        createdAt,
        updatedAt,
      ];

  static const List<String> categories = [
    'Transportation',
    'Accommodation',
    'Food & Dining',
    'Entertainment',
    'Shopping',
    'Health & Medical',
    'Communication',
    'Insurance',
    'Tours & Activities',
    'Other',
  ];
}