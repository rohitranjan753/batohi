import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../blocs/expense/expense_bloc.dart';
import '../blocs/expense/expense_event.dart';
import '../blocs/expense/expense_state.dart';
import '../models/expense.dart';
import '../models/trip.dart';

class TripExpensesPage extends StatefulWidget {
  final Trip trip;

  const TripExpensesPage({super.key, required this.trip});

  @override
  State<TripExpensesPage> createState() => _TripExpensesPageState();
}

class _TripExpensesPageState extends State<TripExpensesPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        if (state.status == ExpenseStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ExpenseStatus.failure) {
          return _buildErrorState(state);
        }

        if (state.expenses.isEmpty) {
          return _buildEmptyState();
        }

        return _buildExpensesList(state);
      },
    );
  }

  Widget _buildErrorState(ExpenseState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.warning(), size: 48, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            state.errorMessage ?? 'Failed to load expenses',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ExpenseBloc>().add(LoadExpenses(widget.trip.id));
            },
            icon: Icon(PhosphorIcons.arrowClockwise()),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.receipt(),
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No expenses yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your spending for this trip',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddExpenseSheet(context),
            icon: Icon(PhosphorIcons.plus()),
            label: const Text('Add Expense'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(ExpenseState state) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Summary header
            SliverToBoxAdapter(
              child: _buildSummaryHeader(state),
            ),
            // Category breakdown
            SliverToBoxAdapter(
              child: _buildCategoryBreakdown(state),
            ),
            // Expenses list
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final expense = state.expenses[index];
                    return _buildExpenseCard(expense);
                  },
                  childCount: state.expenses.length,
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'add_expense',
            onPressed: () => _showAddExpenseSheet(context),
            icon: Icon(PhosphorIcons.plus()),
            label: const Text('Add Expense'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(ExpenseState state) {
    final budgetUsed = widget.trip.budget > 0
        ? (state.totalExpenses / widget.trip.budget * 100)
        : 0.0;
    final remaining = widget.trip.budget - state.totalExpenses;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green,
            Colors.green.withOpacity(0.8),
            Colors.teal.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: PhosphorIcons.wallet(),
                  label: 'Total Spent',
                  value: '${widget.trip.currency} ${state.totalExpenses.toStringAsFixed(0)}',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildSummaryItem(
                  icon: PhosphorIcons.target(),
                  label: 'Budget',
                  value: '${widget.trip.currency} ${widget.trip.budget.toStringAsFixed(0)}',
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildSummaryItem(
                  icon: remaining >= 0
                      ? PhosphorIcons.trendUp()
                      : PhosphorIcons.trendDown(),
                  label: remaining >= 0 ? 'Remaining' : 'Over Budget',
                  value: '${widget.trip.currency} ${remaining.abs().toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
          if (widget.trip.budget > 0) ...[
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget Used',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${budgetUsed.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (budgetUsed / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      budgetUsed > 100 ? Colors.red[300]! : Colors.white,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(ExpenseState state) {
    final categoryTotals = state.expensesByCategory;
    if (categoryTotals.isEmpty) return const SizedBox.shrink();

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(4).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: topCategories.map((entry) {
              final icon = _getCategoryIcon(entry.key);
              final percentage = state.totalExpenses > 0
                  ? (entry.value / state.totalExpenses * 100)
                  : 0.0;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: icon.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(icon.icon, color: icon.color, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: icon.color,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        entry.key.split(' ').first,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final categoryIcon = _getCategoryIcon(expense.category);
    final dateFormat = DateFormat('MMM d');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showExpenseDetailsSheet(context, expense),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryIcon.color.withOpacity(0.2),
                        categoryIcon.color.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    categoryIcon.icon,
                    color: categoryIcon.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: categoryIcon.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              expense.category,
                              style: TextStyle(
                                fontSize: 10,
                                color: categoryIcon.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            PhosphorIcons.calendar(),
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(expense.date),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${expense.currency} ${expense.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: categoryIcon.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  CategoryIcon _getCategoryIcon(String category) {
    switch (category) {
      case 'Transportation':
        return CategoryIcon(PhosphorIcons.car(), Colors.blue);
      case 'Accommodation':
        return CategoryIcon(PhosphorIcons.house(), Colors.purple);
      case 'Food & Dining':
        return CategoryIcon(PhosphorIcons.forkKnife(), Colors.orange);
      case 'Entertainment':
        return CategoryIcon(PhosphorIcons.gameController(), Colors.pink);
      case 'Shopping':
        return CategoryIcon(PhosphorIcons.shoppingBag(), Colors.green);
      case 'Health & Medical':
        return CategoryIcon(PhosphorIcons.firstAid(), Colors.red);
      case 'Communication':
        return CategoryIcon(PhosphorIcons.phone(), Colors.cyan);
      case 'Insurance':
        return CategoryIcon(PhosphorIcons.shield(), Colors.indigo);
      case 'Tours & Activities':
        return CategoryIcon(PhosphorIcons.camera(), Colors.amber);
      default:
        return CategoryIcon(PhosphorIcons.wallet(), Colors.grey);
    }
  }

  void _showAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<ExpenseBloc>(),
        child: AddTripExpenseBottomSheet(
          tripId: widget.trip.id,
          tripCurrency: widget.trip.currency,
        ),
      ),
    );
  }

  void _showExpenseDetailsSheet(BuildContext context, Expense expense) {
    final categoryIcon = _getCategoryIcon(expense.category);
    final dateFormat = DateFormat('MMM d, yyyy');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryIcon.color.withOpacity(0.2),
                        categoryIcon.color.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    categoryIcon.icon,
                    color: categoryIcon.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${expense.currency} ${expense.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: categoryIcon.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow(
              PhosphorIcons.tag(),
              'Category',
              expense.category,
            ),
            _buildDetailRow(
              PhosphorIcons.calendar(),
              'Date',
              dateFormat.format(expense.date),
            ),
            if (expense.description != null && expense.description!.isNotEmpty)
              _buildDetailRow(
                PhosphorIcons.note(),
                'Description',
                expense.description!,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _confirmDeleteExpense(context, expense);
                    },
                    icon: Icon(PhosphorIcons.trash(), color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExpense(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ExpenseBloc>().add(DeleteExpense(expense.id));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class CategoryIcon {
  final IconData icon;
  final Color color;

  CategoryIcon(this.icon, this.color);
}

class AddTripExpenseBottomSheet extends StatefulWidget {
  final String tripId;
  final String tripCurrency;

  const AddTripExpenseBottomSheet({
    super.key,
    required this.tripId,
    required this.tripCurrency,
  });

  @override
  State<AddTripExpenseBottomSheet> createState() =>
      _AddTripExpenseBottomSheetState();
}

class _AddTripExpenseBottomSheetState extends State<AddTripExpenseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedCategory = 'Other';
  late String _selectedCurrency;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.tripCurrency;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        if (state.status == ExpenseStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to add expense'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state.status == ExpenseStatus.success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green,
                          Colors.green.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(PhosphorIcons.receipt(), color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Expense',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Track your spending',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Expense Title',
                        prefixIcon: Icon(PhosphorIcons.tag()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter expense title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              prefixIcon: Icon(PhosphorIcons.wallet()),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter amount';
                              }
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'Invalid amount';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCurrency,
                            decoration: InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: ['INR', 'USD', 'EUR', 'GBP', 'JPY']
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCurrency = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(PhosphorIcons.tag()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: Expense.categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(PhosphorIcons.calendar()),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          DateFormat('MMM d, yyyy').format(_selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        prefixIcon: Icon(PhosphorIcons.note()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              BlocBuilder<ExpenseBloc, ExpenseState>(
                builder: (context, state) {
                  final isLoading = state.status == ExpenseStatus.loading;
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              isLoading ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submitExpense,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Add Expense'),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _submitExpense() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);

      context.read<ExpenseBloc>().add(
            AddExpense(
              tripId: widget.tripId,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              amount: amount,
              currency: _selectedCurrency,
              category: _selectedCategory,
              date: _selectedDate,
            ),
          );
    }
  }
}
