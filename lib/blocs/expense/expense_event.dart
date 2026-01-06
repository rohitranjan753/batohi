import 'package:equatable/equatable.dart';
import '../../models/expense.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class LoadExpenses extends ExpenseEvent {
  final String tripId;

  const LoadExpenses(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class LoadAllExpenses extends ExpenseEvent {
  const LoadAllExpenses();
}

class AddExpense extends ExpenseEvent {
  final String tripId;
  final String title;
  final String? description;
  final double amount;
  final String currency;
  final String category;
  final DateTime date;

  const AddExpense({
    required this.tripId,
    required this.title,
    this.description,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
  });

  @override
  List<Object?> get props => [
        tripId,
        title,
        description,
        amount,
        currency,
        category,
        date,
      ];
}

class UpdateExpense extends ExpenseEvent {
  final Expense expense;

  const UpdateExpense(this.expense);

  @override
  List<Object?> get props => [expense];
}

class DeleteExpense extends ExpenseEvent {
  final String expenseId;

  const DeleteExpense(this.expenseId);

  @override
  List<Object?> get props => [expenseId];
}