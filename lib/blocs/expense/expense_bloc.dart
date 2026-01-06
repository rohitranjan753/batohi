import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../models/expense.dart';
import 'expense_event.dart';
import 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  ExpenseBloc() : super(const ExpenseState()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<LoadAllExpenses>(_onLoadAllExpenses);
    on<AddExpense>(_onAddExpense);
    on<UpdateExpense>(_onUpdateExpense);
    on<DeleteExpense>(_onDeleteExpense);
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<void> _onLoadExpenses(
    LoadExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    if (_userId.isEmpty) return;

    emit(state.copyWith(status: ExpenseStatus.loading));

    try {
      final querySnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: _userId)
          .where('tripId', isEqualTo: event.tripId)
          .orderBy('date', descending: true)
          .get();

      final expenses = querySnapshot.docs
          .map((doc) => Expense.fromDocument(doc))
          .toList();

      emit(state.copyWith(
        status: ExpenseStatus.success,
        expenses: expenses,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'Failed to load expenses: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLoadAllExpenses(
    LoadAllExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    if (_userId.isEmpty) return;

    emit(state.copyWith(status: ExpenseStatus.loading));

    try {
      final querySnapshot = await _firestore
          .collection('expenses')
          .where('userId', isEqualTo: _userId)
          .orderBy('date', descending: true)
          .get();

      final expenses = querySnapshot.docs
          .map((doc) => Expense.fromDocument(doc))
          .toList();

      emit(state.copyWith(
        status: ExpenseStatus.success,
        expenses: expenses,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'Failed to load expenses: ${e.toString()}',
      ));
    }
  }

  Future<void> _onAddExpense(
    AddExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    if (_userId.isEmpty) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'User not authenticated',
      ));
      return;
    }

    emit(state.copyWith(status: ExpenseStatus.loading));

    try {
      final now = DateTime.now();
      final expenseData = {
        'tripId': event.tripId,
        'userId': _userId,
        'title': event.title,
        'description': event.description,
        'amount': event.amount,
        'currency': event.currency,
        'category': event.category,
        'date': Timestamp.fromDate(event.date),
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      final docRef = await _firestore.collection('expenses').add(expenseData);
      
      final newExpense = Expense(
        id: docRef.id,
        tripId: event.tripId,
        userId: _userId,
        title: event.title,
        description: event.description,
        amount: event.amount,
        currency: event.currency,
        category: event.category,
        date: event.date,
        createdAt: now,
        updatedAt: now,
      );

      final updatedExpenses = [newExpense, ...state.expenses];

      emit(state.copyWith(
        status: ExpenseStatus.success,
        expenses: updatedExpenses,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'Failed to add expense: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateExpense(
    UpdateExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    if (_userId.isEmpty) return;

    emit(state.copyWith(status: ExpenseStatus.loading));

    try {
      final updatedExpense = event.expense.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('expenses')
          .doc(updatedExpense.id)
          .update(updatedExpense.toMap());

      final updatedExpenses = state.expenses.map((expense) {
        return expense.id == updatedExpense.id ? updatedExpense : expense;
      }).toList();

      emit(state.copyWith(
        status: ExpenseStatus.success,
        expenses: updatedExpenses,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'Failed to update expense: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    if (_userId.isEmpty) return;

    emit(state.copyWith(status: ExpenseStatus.loading));

    try {
      await _firestore.collection('expenses').doc(event.expenseId).delete();

      final updatedExpenses = state.expenses
          .where((expense) => expense.id != event.expenseId)
          .toList();

      emit(state.copyWith(
        status: ExpenseStatus.success,
        expenses: updatedExpenses,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ExpenseStatus.failure,
        errorMessage: 'Failed to delete expense: ${e.toString()}',
      ));
    }
  }
}