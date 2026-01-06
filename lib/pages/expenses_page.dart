import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../blocs/expense/expense_bloc.dart';
import '../blocs/expense/expense_event.dart';
import '../blocs/expense/expense_state.dart';
import '../blocs/mytrips/mytrips_bloc.dart';
import '../blocs/mytrips/mytrips_state.dart';
import '../models/expense.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Use addPostFrameCallback to ensure the widget is fully built before loading data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllExpenses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadAllExpenses() {
    // Add a small delay to ensure proper initialization
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        context.read<ExpenseBloc>().add(const LoadAllExpenses());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showAddExpenseBottomSheet(context),
            icon: Icon(PhosphorIcons.plus()),
            tooltip: 'Add Expense',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverviewTab(), _buildCategoriesTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseBottomSheet(context),
        child: Icon(PhosphorIcons.plus()),
        tooltip: 'Add Expense',
      ),
    );
  }

  Widget _buildOverviewTab() {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        if (state.status == ExpenseStatus.loading && state.expenses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ExpenseStatus.failure) {
          return _buildErrorState(state);
        }

        if (state.expenses.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            _loadAllExpenses();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main title with total expenses
                _buildMainTotalHeader(state),

                // Monthly summary cards
                _buildSummaryCards(state),

                // All Categories Grid
                _buildCategoriesGrid(state),

                // Recent expenses list
                _buildRecentExpensesList(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainTotalHeader(ExpenseState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Expenses',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${state.totalExpenses.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Across ${state.expenses.length} expense${state.expenses.length != 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(ExpenseState state) {
    final categoryTotals = state.expensesByCategory;

    if (categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    // Create a list of all categories with their amounts (0 for unused categories)
    final allCategoriesWithAmounts = <String, double>{};

    for (final category in Expense.categories) {
      allCategoriesWithAmounts[category] = categoryTotals[category] ?? 0.0;
    }

    // Sort by amount (highest first), but keep categories with 0 at the end
    final sortedCategories = allCategoriesWithAmounts.entries.toList()
      ..sort((a, b) {
        if (a.value == 0 && b.value == 0) return 0;
        if (a.value == 0) return 1;
        if (b.value == 0) return -1;
        return b.value.compareTo(a.value);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Expenses by Category',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: sortedCategories.length,
            itemBuilder: (context, index) {
              final entry = sortedCategories[index];
              return _buildCategoryTile(
                entry.key,
                entry.value,
                state.totalExpenses,
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCategoryTile(
    String category,
    double amount,
    double totalExpenses,
  ) {
    final categoryIcon = _getCategoryIcon(category);
    final percentage = totalExpenses > 0 ? (amount / totalExpenses * 100) : 0.0;
    final hasExpenses = amount > 0;

    return Card(
      elevation: hasExpenses ? 2 : 1,
      child: Container(
        padding: const EdgeInsets.all(12), // Reduced padding from 16 to 12
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: hasExpenses
              ? Border.all(color: categoryIcon.color.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Added to prevent overflow
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(
                    6,
                  ), // Reduced padding from 8 to 6
                  decoration: BoxDecoration(
                    color: categoryIcon.color.withOpacity(
                      hasExpenses ? 0.1 : 0.05,
                    ),
                    borderRadius: BorderRadius.circular(
                      6,
                    ), // Reduced border radius
                  ),
                  child: Icon(
                    categoryIcon.icon,
                    color: hasExpenses ? categoryIcon.color : Colors.grey,
                    size: 18, // Reduced icon size from 20 to 18
                  ),
                ),
                const Spacer(),
                if (hasExpenses)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4, // Reduced horizontal padding
                      vertical: 1, // Reduced vertical padding
                    ),
                    decoration: BoxDecoration(
                      color: categoryIcon.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 9, // Reduced font size from 10 to 9
                        fontWeight: FontWeight.bold,
                        color: categoryIcon.color,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8), // Reduced spacing from 12 to 8
            Flexible(
              // Wrapped with Flexible to prevent overflow
              child: Text(
                category,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11, // Reduced font size from 12 to 11
                  color: hasExpenses ? Colors.black87 : Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2), // Reduced spacing from 4 to 2
            Text(
              hasExpenses ? '\$${amount.toStringAsFixed(2)}' : '\$0.00',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14, // Reduced font size from 16 to 14
                color: hasExpenses ? categoryIcon.color : Colors.grey,
              ),
            ),
            if (hasExpenses) ...[
              const SizedBox(height: 6), // Reduced spacing from 8 to 6
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(categoryIcon.color),
                minHeight: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExpensesList(ExpenseState state) {
    final recentExpenses = state.expenses.take(5).toList();

    if (recentExpenses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Expenses',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (state.expenses.length > 5)
                TextButton(
                  onPressed: () {
                    // Switch to second tab (Categories) to see all expenses
                    _tabController.animateTo(1);
                  },
                  child: const Text('View All'),
                ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: recentExpenses.length,
          itemBuilder: (context, index) {
            final expense = recentExpenses[index];
            return _buildExpenseCard(expense);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        if (state.status == ExpenseStatus.loading && state.expenses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.expenses.isEmpty) {
          return _buildEmptyState();
        }

        final categoryTotals = state.expensesByCategory;
        final sortedCategories = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return RefreshIndicator(
          onRefresh: () async {
            _loadAllExpenses();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedCategories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCategoryChart(categoryTotals, state.totalExpenses);
              }

              final entry = sortedCategories[index - 1];
              return _buildCategoryCard(
                entry.key,
                entry.value,
                state.totalExpenses,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards(ExpenseState state) {
    final thisMonth = DateTime.now();
    final thisMonthExpenses = state.expenses.where((expense) {
      return expense.date.year == thisMonth.year &&
          expense.date.month == thisMonth.month;
    }).toList();

    final thisMonthTotal = thisMonthExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.wallet(),
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total Spent',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${state.totalExpenses.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.calendar(),
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'This Month',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${thisMonthTotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(Map<String, double> categoryTotals, double total) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spending by Category',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildSimplePieChart(categoryTotals, total),
                  ),
                  Expanded(
                    flex: 3,
                    child: _buildCategoryLegend(categoryTotals, total),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplePieChart(
    Map<String, double> categoryTotals,
    double total,
  ) {
    if (total == 0) return const SizedBox();

    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: categoryTotals.keys.map((category) {
              return _getCategoryIcon(category).color;
            }).toList(),
            stops: _generateStops(categoryTotals, total),
          ),
        ),
        child: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${categoryTotals.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<double> _generateStops(
    Map<String, double> categoryTotals,
    double total,
  ) {
    final stops = <double>[0.0];
    double currentStop = 0.0;

    for (final value in categoryTotals.values) {
      currentStop += value / total;
      stops.add(currentStop);
    }

    return stops;
  }

  Widget _buildCategoryLegend(
    Map<String, double> categoryTotals,
    double total,
  ) {
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedEntries.take(6).map((entry) {
        final percentage = (entry.value / total * 100);
        final categoryIcon = _getCategoryIcon(entry.key);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: categoryIcon.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryCard(String category, double amount, double total) {
    final percentage = (amount / total * 100);
    final categoryIcon = _getCategoryIcon(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: categoryIcon.color.withOpacity(0.1),
              child: Icon(categoryIcon.icon, color: categoryIcon.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      categoryIcon.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final categoryIcon = _getCategoryIcon(expense.category);
    final dateFormatter = DateFormat('MMM dd');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: categoryIcon.color.withOpacity(0.1),
          child: Icon(categoryIcon.icon, color: categoryIcon.color, size: 20),
        ),
        title: Text(
          expense.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Text(expense.category),
            const Text(' • '),
            Text(dateFormatter.format(expense.date)),
            if (expense.description != null &&
                expense.description!.isNotEmpty) ...[
              const Text(' • '),
              Expanded(
                child: Text(
                  expense.description!,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            BlocBuilder<MyTripsBloc, MyTripsState>(
              builder: (context, tripsState) {
                final trips = tripsState.trips.where(
                  (t) => t.id == expense.tripId,
                );
                final tripName = trips.isNotEmpty
                    ? trips.first.tripName
                    : 'Unknown Trip';
                return Text(
                  tripName,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                );
              },
            ),
          ],
        ),
        onTap: () => _showExpenseDetailsDialog(context, expense),
      ),
    );
  }

  Widget _buildErrorState(ExpenseState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.warningCircle(), size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading expenses',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            state.errorMessage ?? 'Unknown error occurred',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAllExpenses,
            child: const Text('Retry'),
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
          Icon(PhosphorIcons.receipt(), size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No Expenses Yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your expenses across all trips',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddExpenseBottomSheet(context),
            icon: Icon(PhosphorIcons.plus()),
            label: const Text('Add First Expense'),
          ),
        ],
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

  void _showAddExpenseBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider.value(
        value: context.read<ExpenseBloc>(),
        child: const AddExpenseBottomSheet(),
      ),
    ).then((result) {
      if (result == true) {
        _loadAllExpenses();
      }
    });
  }

  void _showExpenseDetailsDialog(BuildContext context, Expense expense) {
    showDialog(
      context: context,
      builder: (dialogContext) => ExpenseDetailsDialog(expense: expense),
    ).then((result) {
      if (result == true) {
        _loadAllExpenses();
      }
    });
  }
}

class CategoryIcon {
  final IconData icon;
  final Color color;

  CategoryIcon(this.icon, this.color);
}

class AddExpenseBottomSheet extends StatefulWidget {
  const AddExpenseBottomSheet({super.key});

  @override
  State<AddExpenseBottomSheet> createState() => _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState extends State<AddExpenseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedTripId;
  String _selectedCategory = 'Other';
  String _selectedCurrency = 'USD';
  DateTime _selectedDate = DateTime.now();

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
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
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
              const SizedBox(height: 20),
              // Title
              Row(
                children: [
                  Icon(
                    PhosphorIcons.plus(),
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add New Expense',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Trip selection with expansion tile
                    _buildTripSelector(),
                    const SizedBox(height: 16),
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
                              prefixIcon: Icon(PhosphorIcons.currencyDollar()),
                              prefixText: '\$ ',
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
                            items: ['USD', 'EUR', 'GBP', 'INR', 'JPY']
                                .map(
                                  (currency) => DropdownMenuItem(
                                    value: currency,
                                    child: Text(currency),
                                  ),
                                )
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
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
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
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
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
                          DateFormat('MMM dd, yyyy').format(_selectedDate),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Action Buttons
              BlocBuilder<ExpenseBloc, ExpenseState>(
                builder: (context, state) {
                  return Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.status == ExpenseStatus.loading
                              ? null
                              : () => Navigator.of(context).pop(),
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
                        child: ElevatedButton(
                          onPressed: state.status == ExpenseStatus.loading
                              ? null
                              : _submitExpense,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: state.status == ExpenseStatus.loading
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripSelector() {
    return BlocBuilder<MyTripsBloc, MyTripsState>(
      builder: (context, tripsState) {
        if (tripsState.trips.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(PhosphorIcons.airplane(), size: 24, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'No trips available',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create a trip first to add expenses',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: ExpansionTile(
            leading: Icon(PhosphorIcons.airplane()),
            title: Text(
              _selectedTripId == null
                  ? 'Select Trip'
                  : tripsState.trips
                        .firstWhere((trip) => trip.id == _selectedTripId)
                        .tripName,
            ),
            subtitle: _selectedTripId == null
                ? const Text('Choose which trip this expense belongs to')
                : null,
            children: tripsState.trips.map((trip) {
              final isSelected = _selectedTripId == trip.id;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[200],
                  child: Icon(
                    PhosphorIcons.mapPin(),
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 16,
                  ),
                ),
                title: Text(
                  trip.tripName,
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                subtitle: Text('${trip.destination} • ${trip.currency}'),
                trailing: isSelected
                    ? Icon(
                        PhosphorIcons.check(),
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    _selectedTripId = trip.id;
                    _selectedCurrency = trip.currency;
                  });
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _submitExpense() {
    if (_selectedTripId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a trip')));
      return;
    }

    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);

      context.read<ExpenseBloc>().add(
        AddExpense(
          tripId: _selectedTripId!,
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

class ExpenseDetailsDialog extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailsDialog({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM dd, yyyy');

    return AlertDialog(
      title: Text(expense.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            'Amount',
            '\$${expense.amount.toStringAsFixed(2)} ${expense.currency}',
          ),
          _buildDetailRow('Category', expense.category),
          _buildDetailRow('Date', dateFormatter.format(expense.date)),
          if (expense.description != null && expense.description!.isNotEmpty)
            _buildDetailRow('Description', expense.description!),
          _buildDetailRow('Added', dateFormatter.format(expense.createdAt)),
          // Show trip name
          BlocBuilder<MyTripsBloc, MyTripsState>(
            builder: (context, tripsState) {
              final trips = tripsState.trips.where(
                (t) => t.id == expense.tripId,
              );
              final tripName = trips.isNotEmpty
                  ? trips.first.tripName
                  : 'Unknown Trip';
              return _buildDetailRow('Trip', tripName);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Delete Expense'),
                content: Text(
                  'Are you sure you want to delete "${expense.title}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ExpenseBloc>().add(
                        DeleteExpense(expense.id),
                      );
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}