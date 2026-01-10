import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../blocs/expense/expense_bloc.dart';
import '../blocs/expense/expense_event.dart';
import '../blocs/itinerary/itinerary_bloc.dart';
import '../blocs/itinerary/itinerary_event.dart';
import '../blocs/stay/stay_bloc.dart';
import '../blocs/stay/stay_event.dart';
import '../models/trip.dart';
import 'itinerary_page.dart';
import 'trip_expenses_page.dart';
import 'stays_page.dart';

class TripDetailPage extends StatefulWidget {
  final Trip trip;

  const TripDetailPage({super.key, required this.trip});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load all data for this trip
      context.read<ItineraryBloc>().add(LoadItineraries(widget.trip.id));
      context.read<ExpenseBloc>().add(LoadExpenses(widget.trip.id));
      context.read<StayBloc>().add(LoadStays(widget.trip.id));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tripDays = widget.trip.endDate.difference(widget.trip.startDate).inDays + 1;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              floating: false,
              backgroundColor: Theme.of(context).primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  widget.trip.tripName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                        Colors.deepPurple.withOpacity(0.5),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 80,
                        left: 16,
                        right: 16,
                        child: Row(
                          children: [
                            _buildInfoChip(
                              icon: PhosphorIcons.mapPin(),
                              label: widget.trip.destination,
                            ),
                            const SizedBox(width: 12),
                            _buildInfoChip(
                              icon: PhosphorIcons.calendar(),
                              label: '$tripDays days',
                            ),
                            const SizedBox(width: 12),
                            _buildInfoChip(
                              icon: PhosphorIcons.wallet(),
                              label: '${widget.trip.currency} ${widget.trip.budget.toStringAsFixed(0)}',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(PhosphorIcons.arrowLeft(), color: Colors.white),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).primaryColor,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(
                        icon: Icon(PhosphorIcons.mapTrifold()),
                        text: 'Itinerary',
                      ),
                      Tab(
                        icon: Icon(PhosphorIcons.receipt()),
                        text: 'Expenses',
                      ),
                      Tab(
                        icon: Icon(PhosphorIcons.bed()),
                        text: 'Stays',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            ItineraryPage(trip: widget.trip),
            TripExpensesPage(trip: widget.trip),
            StaysPage(trip: widget.trip),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
