import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../blocs/itinerary/itinerary_bloc.dart';
import '../blocs/itinerary/itinerary_event.dart';
import '../blocs/itinerary/itinerary_state.dart';
import '../models/itinerary.dart';
import '../models/trip.dart';

class ItineraryPage extends StatefulWidget {
  final Trip trip;

  const ItineraryPage({super.key, required this.trip});

  @override
  State<ItineraryPage> createState() => _ItineraryPageState();
}

class _ItineraryPageState extends State<ItineraryPage> {
  int _selectedDay = 1;

  int get _totalDays =>
      widget.trip.endDate.difference(widget.trip.startDate).inDays + 1;

  DateTime _getDateForDay(int day) {
    return widget.trip.startDate.add(Duration(days: day - 1));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItineraryBloc, ItineraryState>(
      builder: (context, state) {
        return Column(
          children: [
            // Day selector
            _buildDaySelector(),
            // Content
            Expanded(child: _buildContent(state)),
          ],
        );
      },
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _totalDays,
        itemBuilder: (context, index) {
          final day = index + 1;
          final date = _getDateForDay(day);
          final isSelected = _selectedDay == day;
          final isToday = DateUtils.isSameDay(date, DateTime.now());

          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      )
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Day $day',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey[600],
                    ),
                  ),
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(ItineraryState state) {
    if (state.status == ItineraryStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == ItineraryStatus.failure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.warning(), size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              state.errorMessage ?? 'Failed to load itinerary',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                context
                    .read<ItineraryBloc>()
                    .add(LoadItineraries(widget.trip.id));
              },
              icon: Icon(PhosphorIcons.arrowClockwise()),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final dayItineraries = state.itinerariesByDay[_selectedDay] ?? [];

    if (dayItineraries.isEmpty) {
      return _buildEmptyDayState();
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: dayItineraries.length,
          itemBuilder: (context, index) {
            final item = dayItineraries[index];
            return _buildItineraryCard(item, index, dayItineraries.length);
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'add_itinerary',
            onPressed: () => _showAddItinerarySheet(context),
            icon: Icon(PhosphorIcons.plus()),
            label: const Text('Add Activity'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDayState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIcons.mapTrifold(),
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No activities planned',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first activity for Day $_selectedDay',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddItinerarySheet(context),
            icon: Icon(PhosphorIcons.plus()),
            label: const Text('Add Activity'),
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

  Widget _buildItineraryCard(Itinerary item, int index, int total) {
    final activityIcon = _getActivityIcon(item.activityType);
    final timeFormat = DateFormat('h:mm a');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline
        SizedBox(
          width: 60,
          child: Column(
            children: [
              Text(
                timeFormat.format(item.time),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: activityIcon.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: activityIcon.color.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              if (index < total - 1)
                Container(
                  width: 2,
                  height: 80,
                  color: Colors.grey[300],
                ),
            ],
          ),
        ),
        // Card
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
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
                onTap: () => _showItineraryDetailsSheet(context, item),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  activityIcon.color.withOpacity(0.2),
                                  activityIcon.color.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              activityIcon.icon,
                              color: activityIcon.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: activityIcon.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.activityType,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: activityIcon.color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              PhosphorIcons.dotsThree(),
                              color: Colors.grey[400],
                            ),
                            onPressed: () =>
                                _showItineraryOptionsSheet(context, item),
                          ),
                        ],
                      ),
                      if (item.location != null && item.location!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              PhosphorIcons.mapPin(),
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.location!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.notes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  ActivityIcon _getActivityIcon(String activityType) {
    switch (activityType) {
      case 'Sightseeing':
        return ActivityIcon(PhosphorIcons.binoculars(), Colors.blue);
      case 'Adventure':
        return ActivityIcon(PhosphorIcons.mountains(), Colors.orange);
      case 'Relaxation':
        return ActivityIcon(PhosphorIcons.sun(), Colors.teal);
      case 'Food & Dining':
        return ActivityIcon(PhosphorIcons.forkKnife(), Colors.red);
      case 'Shopping':
        return ActivityIcon(PhosphorIcons.shoppingBag(), Colors.pink);
      case 'Transportation':
        return ActivityIcon(PhosphorIcons.car(), Colors.indigo);
      case 'Cultural':
        return ActivityIcon(PhosphorIcons.bank(), Colors.purple);
      case 'Entertainment':
        return ActivityIcon(PhosphorIcons.confetti(), Colors.amber);
      case 'Nature':
        return ActivityIcon(PhosphorIcons.tree(), Colors.green);
      case 'Photography':
        return ActivityIcon(PhosphorIcons.camera(), Colors.cyan);
      default:
        return ActivityIcon(PhosphorIcons.mapPin(), Colors.grey);
    }
  }

  void _showAddItinerarySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<ItineraryBloc>(),
        child: AddItineraryBottomSheet(
          tripId: widget.trip.id,
          day: _selectedDay,
          tripStartDate: widget.trip.startDate,
        ),
      ),
    );
  }

  void _showItineraryDetailsSheet(BuildContext context, Itinerary item) {
    final activityIcon = _getActivityIcon(item.activityType);
    final timeFormat = DateFormat('h:mm a');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                        activityIcon.color.withOpacity(0.2),
                        activityIcon.color.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    activityIcon.icon,
                    color: activityIcon.color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.activityType} • ${timeFormat.format(item.time)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (item.location != null && item.location!.isNotEmpty)
              _buildDetailRow(
                PhosphorIcons.mapPin(),
                'Location',
                item.location!,
              ),
            if (item.notes != null && item.notes!.isNotEmpty)
              _buildDetailRow(
                PhosphorIcons.note(),
                'Notes',
                item.notes!,
              ),
            const SizedBox(height: 24),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showItineraryOptionsSheet(BuildContext context, Itinerary item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(PhosphorIcons.trash(), color: Colors.red),
              ),
              title: const Text('Delete Activity'),
              subtitle: const Text('Remove this activity from your itinerary'),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteItinerary(context, item);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteItinerary(BuildContext context, Itinerary item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text('Are you sure you want to delete "${item.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ItineraryBloc>().add(DeleteItinerary(item.id));
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

class ActivityIcon {
  final IconData icon;
  final Color color;

  ActivityIcon(this.icon, this.color);
}

class AddItineraryBottomSheet extends StatefulWidget {
  final String tripId;
  final int day;
  final DateTime tripStartDate;

  const AddItineraryBottomSheet({
    super.key,
    required this.tripId,
    required this.day,
    required this.tripStartDate,
  });

  @override
  State<AddItineraryBottomSheet> createState() =>
      _AddItineraryBottomSheetState();
}

class _AddItineraryBottomSheetState extends State<AddItineraryBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedActivityType = 'Sightseeing';

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ItineraryBloc, ItineraryState>(
      listener: (context, state) {
        if (state.status == ItineraryStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to add activity'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state.status == ItineraryStatus.success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Activity added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Container(
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
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      PhosphorIcons.mapTrifold(),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Activity',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Day ${widget.day}',
                        style: TextStyle(color: Colors.grey[600]),
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
                        labelText: 'Activity Title',
                        prefixIcon: Icon(PhosphorIcons.tag()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter activity title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedActivityType,
                            decoration: InputDecoration(
                              labelText: 'Activity Type',
                              prefixIcon: Icon(PhosphorIcons.tag()),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: Itinerary.activityTypes
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedActivityType = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                              );
                              if (time != null) {
                                setState(() => _selectedTime = time);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Time',
                                prefixIcon: Icon(PhosphorIcons.clock()),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(_selectedTime.format(context)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location (Optional)',
                        prefixIcon: Icon(PhosphorIcons.mapPin()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
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
              BlocBuilder<ItineraryBloc, ItineraryState>(
                builder: (context, state) {
                  final isLoading = state.status == ItineraryStatus.loading;
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
                          onPressed: isLoading ? null : _submitItinerary,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).primaryColor,
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
                              : const Text('Add Activity'),
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

  void _submitItinerary() {
    if (_formKey.currentState!.validate()) {
      final activityDate = widget.tripStartDate.add(
        Duration(days: widget.day - 1),
      );
      final time = DateTime(
        activityDate.year,
        activityDate.month,
        activityDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      context.read<ItineraryBloc>().add(
            AddItinerary(
              tripId: widget.tripId,
              day: widget.day,
              time: time,
              title: _titleController.text.trim(),
              location: _locationController.text.trim().isEmpty
                  ? null
                  : _locationController.text.trim(),
              activityType: _selectedActivityType,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          );
    }
  }
}
