import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../blocs/authentication/authentication_bloc.dart';
import '../blocs/authentication/authentication_event.dart';
import '../blocs/mytrips/mytrips_bloc.dart';
import '../blocs/mytrips/mytrips_event.dart';
import '../blocs/mytrips/mytrips_state.dart';
import '../blocs/expense/expense_bloc.dart';
import '../blocs/expense/expense_event.dart';
import '../blocs/expense/expense_state.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key});

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyTripsBloc>().add(const LoadTrips());
      _fabAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _showAddTripBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 400),
      ),
      builder: (context) => BlocProvider.value(
        value: this.context.read<MyTripsBloc>(),
        child: const AddTripBottomSheet(),
      ),
    );
  }

  void _navigateToTripDetail(BuildContext context, String tripId) {
    context.push('/trip/$tripId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'My Trips',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            key: const Key('myTripsPage_logout_iconButton'),
            icon: Icon(PhosphorIcons.signOut()),
            onPressed: () {
              context
                  .read<AuthenticationBloc>()
                  .add(const AuthenticationLogoutRequested());
            },
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.grey[50]!,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: BlocBuilder<MyTripsBloc, MyTripsState>(
          builder: (context, state) {
            return SafeArea(child: _buildTripsContent(context, state));
          },
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddTripBottomSheet(context),
          icon: Icon(PhosphorIcons.plus()),
          label: const Text('New Trip'),
          elevation: 8,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTripsContent(BuildContext context, MyTripsState state) {
    if (state.status == MyTripsStatus.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 2 * math.pi,
                  child: Icon(
                    PhosphorIcons.airplane(),
                    size: 48,
                    color: Theme.of(context).primaryColor.withOpacity(value),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading your adventures...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (state.status == MyTripsStatus.failure) {
      return Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  PhosphorIcons.warning(),
                  size: 48,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  state.errorMessage ?? 'Unknown error occurred',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<MyTripsBloc>().add(const LoadTrips());
                },
                icon: Icon(PhosphorIcons.arrowClockwise()),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.trips.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildTripsList(context, state);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.2),
                    Theme.of(context).primaryColor.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                PhosphorIcons.airplaneTilt(),
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Ready for Adventure?',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Start planning your next trip\nand track expenses on the go',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showAddTripBottomSheet(context),
                icon: Icon(PhosphorIcons.plus(), size: 22),
                label: const Text(
                  'Create Your First Trip',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsList(BuildContext context, MyTripsState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.airplane(),
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${state.trips.length} Trip${state.trips.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: state.trips.length,
            itemBuilder: (context, index) {
              final trip = state.trips[index];
              return AnimatedTripCard(
                trip: trip,
                index: index,
                onTap: () => _navigateToTripDetail(context, trip.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class AnimatedTripCard extends StatefulWidget {
  final dynamic trip;
  final int index;
  final VoidCallback onTap;

  const AnimatedTripCard({
    super.key,
    required this.trip,
    required this.index,
    required this.onTap,
  });

  @override
  State<AnimatedTripCard> createState() => _AnimatedTripCardState();
}

class _AnimatedTripCardState extends State<AnimatedTripCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Staggered animation based on index
    Future.delayed(Duration(milliseconds: 100 * widget.index), () {
      if (mounted) _controller.forward();
    });

    // Load expenses for this trip
    context.read<ExpenseBloc>().add(LoadExpenses(widget.trip.id));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> gradientColors = widget.trip.isStarted
        ? [const Color(0xFF4CAF50), const Color(0xFF81C784)]
        : [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(scale: _scaleAnimation, child: child),
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 16),
          transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isPressed ? 0.15 : 0.08),
                blurRadius: _isPressed ? 15 : 20,
                offset: Offset(0, _isPressed ? 5 : 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                // Gradient Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.trip.isStarted
                              ? PhosphorIcons.play()
                              : PhosphorIcons.airplane(),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.trip.tripName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  PhosphorIcons.mapPin(),
                                  size: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.trip.destination,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (widget.trip.isStarted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Active',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Card Body
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Date Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              PhosphorIcons.calendar(),
                              size: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_formatDate(widget.trip.startDate)} → ${_formatDate(widget.trip.endDate)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Budget Progress Section
                      BlocBuilder<ExpenseBloc, ExpenseState>(
                        builder: (context, expenseState) {
                          final tripExpenses = expenseState.expenses
                              .where(
                                (expense) => expense.tripId == widget.trip.id,
                              )
                              .toList();

                          final totalSpent = tripExpenses.fold(
                            0.0,
                            (sum, expense) => sum + expense.amount,
                          );

                          final budget = widget.trip.budget;
                          final progress = budget > 0
                              ? (totalSpent / budget).clamp(0.0, 1.0)
                              : 0.0;
                          final isOverBudget = totalSpent > budget;

                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStatItem(
                                    icon: PhosphorIcons.wallet(),
                                    label: 'Budget',
                                    value:
                                        '${widget.trip.currency} ${widget.trip.budget.toStringAsFixed(0)}',
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  _buildStatItem(
                                    icon: PhosphorIcons.receipt(),
                                    label: 'Spent',
                                    value:
                                        '${widget.trip.currency} ${totalSpent.toStringAsFixed(0)}',
                                    color: isOverBudget
                                        ? Colors.red
                                        : Colors.green,
                                    alignment: CrossAxisAlignment.end,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Progress Bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.0, end: progress),
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, value, child) {
                                    return Stack(
                                      children: [
                                        Container(
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                        FractionallySizedBox(
                                          widthFactor: value,
                                          child: Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: isOverBudget
                                                    ? [
                                                        Colors.red[400]!,
                                                        Colors.red[600]!,
                                                      ]
                                                    : [
                                                        Colors.green[400]!,
                                                        Colors.green[600]!,
                                                      ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Footer
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        PhosphorIcons.receipt(),
                                        size: 16,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${tripExpenses.length} expense${tripExpenses.length != 1 ? 's' : ''}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'View Details',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        PhosphorIcons.arrowRight(),
                                        size: 16,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class TripCard extends StatefulWidget {
  final dynamic trip;
  final VoidCallback onTap;

  const TripCard({super.key, required this.trip, required this.onTap});

  @override
  State<TripCard> createState() => _TripCardState();
}

class _TripCardState extends State<TripCard> {
  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(LoadExpenses(widget.trip.id));
  }

  @override
  Widget build(BuildContext context) {
    // This widget is kept for backward compatibility but AnimatedTripCard is preferred
    return Container();
  }
}

class AddTripBottomSheet extends StatefulWidget {
  const AddTripBottomSheet({super.key});

  @override
  State<AddTripBottomSheet> createState() => _AddTripBottomSheetState();
}

class _AddTripBottomSheetState extends State<AddTripBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _tripNameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _currency = 'INR';

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tripNameController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    _budgetController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _saveTrip() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a start date'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
      if (_endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select an end date'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      final budget = double.tryParse(_budgetController.text) ?? 0.0;

      context.read<MyTripsBloc>().add(
        AddTrip(
          tripName: _tripNameController.text.trim(),
          destination: _destinationController.text.trim(),
          startDate: _startDate!,
          endDate: _endDate!,
          budget: budget,
          currency: _currency,
          notes: _notesController.text.trim(),
        ),
      );

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MyTripsBloc, MyTripsState>(
      listener: (context, state) {
        if (state.status == MyTripsStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to add trip'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else if (state.status == MyTripsStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Trip added successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _slideAnimation.value)),
            child: Opacity(opacity: _slideAnimation.value, child: child),
          );
        },
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                  const SizedBox(height: 24),
                  // Title with gradient icon background
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          PhosphorIcons.airplaneTakeoff(),
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'New Adventure',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Plan your next trip',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _tripNameController,
                          label: 'Trip Name',
                          icon: PhosphorIcons.tag(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a trip name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _destinationController,
                          label: 'Destination',
                          icon: PhosphorIcons.mapPin(),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a destination';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateSelector(
                                label: 'Start Date',
                                date: _startDate,
                                onTap: () => _selectDate(context, true),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDateSelector(
                                label: 'End Date',
                                date: _endDate,
                                onTap: () => _selectDate(context, false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _budgetController,
                                label: 'Budget',
                                icon: PhosphorIcons.currencyDollar(),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value != null && value.isNotEmpty) {
                                    if (double.tryParse(value) == null) {
                                      return 'Invalid number';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _currency,
                                  decoration: InputDecoration(
                                    labelText: 'Currency',
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'INR',
                                      child: Text('₹'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'USD',
                                      child: Text('\$'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'EUR',
                                      child: Text('€'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'GBP',
                                      child: Text('£'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _currency = value ?? 'INR';
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _notesController,
                          label: 'Notes (Optional)',
                          icon: PhosphorIcons.note(),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Action Buttons
                  BlocBuilder<MyTripsBloc, MyTripsState>(
                    builder: (context, state) {
                      final isLoading = state.status == MyTripsStatus.loading;
                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.8),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _saveTrip,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            PhosphorIcons.airplane(),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Create Trip',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[50],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(PhosphorIcons.calendar(), color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Select',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: date != null ? Colors.black87 : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, this.photo});

  final String? photo;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 40,
      backgroundImage: photo != null ? NetworkImage(photo!) : null,
      child: photo == null ? Icon(PhosphorIcons.user(), size: 48) : null,
    );
  }
}