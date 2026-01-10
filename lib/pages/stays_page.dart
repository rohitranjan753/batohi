import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:intl/intl.dart';
import '../blocs/stay/stay_bloc.dart';
import '../blocs/stay/stay_event.dart';
import '../blocs/stay/stay_state.dart';
import '../models/stay.dart';
import '../models/trip.dart';

class StaysPage extends StatefulWidget {
  final Trip trip;

  const StaysPage({super.key, required this.trip});

  @override
  State<StaysPage> createState() => _StaysPageState();
}

class _StaysPageState extends State<StaysPage> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StayBloc, StayState>(
      builder: (context, state) {
        if (state.status == StayStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == StayStatus.failure) {
          return _buildErrorState(state);
        }

        if (state.stays.isEmpty) {
          return _buildEmptyState();
        }

        return _buildStaysList(state);
      },
    );
  }

  Widget _buildErrorState(StayState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.warning(), size: 48, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            state.errorMessage ?? 'Failed to load stays',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<StayBloc>().add(LoadStays(widget.trip.id));
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
              PhosphorIcons.bed(),
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No accommodations yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your hotels, Airbnbs, or other stays',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddStaySheet(context),
            icon: Icon(PhosphorIcons.plus()),
            label: const Text('Add Stay'),
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

  Widget _buildStaysList(StayState state) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // Summary header
            SliverToBoxAdapter(
              child: _buildSummaryHeader(state),
            ),
            // Stays list
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final stay = state.stays[index];
                    return _buildStayCard(stay);
                  },
                  childCount: state.stays.length,
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'add_stay',
            onPressed: () => _showAddStaySheet(context),
            icon: Icon(PhosphorIcons.plus()),
            label: const Text('Add Stay'),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(StayState state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple,
            Colors.purple.withOpacity(0.8),
            Colors.deepPurple.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              icon: PhosphorIcons.bed(),
              label: 'Total Stays',
              value: '${state.stays.length}',
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildSummaryItem(
              icon: PhosphorIcons.moon(),
              label: 'Total Nights',
              value: '${state.totalNights}',
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withOpacity(0.3),
          ),
          Expanded(
            child: _buildSummaryItem(
              icon: PhosphorIcons.wallet(),
              label: 'Total Cost',
              value: '${widget.trip.currency} ${state.totalStayCost.toStringAsFixed(0)}',
            ),
          ),
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
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildStayCard(Stay stay) {
    final stayIcon = _getStayIcon(stay.stayType);
    final dateFormat = DateFormat('MMM d');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showStayDetailsSheet(context, stay),
          child: Column(
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      stayIcon.color,
                      stayIcon.color.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
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
                        stayIcon.icon,
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
                            stay.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              stay.stayType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.dotsThreeVertical(),
                        color: Colors.white,
                      ),
                      onPressed: () => _showStayOptionsSheet(context, stay),
                    ),
                  ],
                ),
              ),
              // Body
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Date row
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoRow(
                            icon: PhosphorIcons.signIn(),
                            label: 'Check-in',
                            value: dateFormat.format(stay.checkIn),
                            color: Colors.green,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            PhosphorIcons.arrowRight(),
                            color: Colors.grey[400],
                            size: 16,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoRow(
                            icon: PhosphorIcons.signOut(),
                            label: 'Check-out',
                            value: dateFormat.format(stay.checkOut),
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  PhosphorIcons.moon(),
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${stay.nights} night${stay.nights != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: stayIcon.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  PhosphorIcons.wallet(),
                                  size: 16,
                                  color: stayIcon.color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  stay.costPerNight != null
                                      ? '${stay.currency ?? widget.trip.currency} ${stay.totalCost.toStringAsFixed(0)}'
                                      : 'No cost',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: stayIcon.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (stay.address != null && stay.address!.isNotEmpty) ...[
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
                              stay.address!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  StayIcon _getStayIcon(String stayType) {
    switch (stayType) {
      case 'Hotel':
        return StayIcon(PhosphorIcons.buildings(), Colors.blue);
      case 'Hostel':
        return StayIcon(PhosphorIcons.bed(), Colors.orange);
      case 'Resort':
        return StayIcon(PhosphorIcons.swimmingPool(), Colors.cyan);
      case 'Airbnb':
        return StayIcon(PhosphorIcons.house(), Colors.pink);
      case 'Guesthouse':
        return StayIcon(PhosphorIcons.door(), Colors.green);
      case 'Villa':
        return StayIcon(PhosphorIcons.warehouse(), Colors.purple);
      case 'Apartment':
        return StayIcon(PhosphorIcons.buildingApartment(), Colors.indigo);
      case 'Camping':
        return StayIcon(PhosphorIcons.campfire(), Colors.amber);
      case 'Homestay':
        return StayIcon(PhosphorIcons.users(), Colors.teal);
      default:
        return StayIcon(PhosphorIcons.bed(), Colors.grey);
    }
  }

  void _showAddStaySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<StayBloc>(),
        child: AddStayBottomSheet(
          tripId: widget.trip.id,
          tripCurrency: widget.trip.currency,
          tripStartDate: widget.trip.startDate,
          tripEndDate: widget.trip.endDate,
        ),
      ),
    );
  }

  void _showStayDetailsSheet(BuildContext context, Stay stay) {
    final stayIcon = _getStayIcon(stay.stayType);
    final dateFormat = DateFormat('MMM d, yyyy');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
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
                          stayIcon.color,
                          stayIcon.color.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      stayIcon.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stay.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${stay.stayType} • ${stay.nights} nights',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(
                PhosphorIcons.signIn(),
                'Check-in',
                dateFormat.format(stay.checkIn),
              ),
              _buildDetailRow(
                PhosphorIcons.signOut(),
                'Check-out',
                dateFormat.format(stay.checkOut),
              ),
              if (stay.address != null && stay.address!.isNotEmpty)
                _buildDetailRow(
                  PhosphorIcons.mapPin(),
                  'Address',
                  stay.address!,
                ),
              if (stay.costPerNight != null)
                _buildDetailRow(
                  PhosphorIcons.wallet(),
                  'Cost',
                  '${stay.currency ?? widget.trip.currency} ${stay.costPerNight!.toStringAsFixed(0)}/night (Total: ${stay.currency ?? widget.trip.currency} ${stay.totalCost.toStringAsFixed(0)})',
                ),
              if (stay.confirmationNumber != null &&
                  stay.confirmationNumber!.isNotEmpty)
                _buildDetailRow(
                  PhosphorIcons.hashStraight(),
                  'Confirmation #',
                  stay.confirmationNumber!,
                ),
              if (stay.contactNumber != null && stay.contactNumber!.isNotEmpty)
                _buildDetailRow(
                  PhosphorIcons.phone(),
                  'Contact',
                  stay.contactNumber!,
                ),
              if (stay.notes != null && stay.notes!.isNotEmpty)
                _buildDetailRow(
                  PhosphorIcons.note(),
                  'Notes',
                  stay.notes!,
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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

  void _showStayOptionsSheet(BuildContext context, Stay stay) {
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
              title: const Text('Delete Stay'),
              subtitle: const Text('Remove this accommodation'),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteStay(context, stay);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteStay(BuildContext context, Stay stay) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Stay'),
        content: Text('Are you sure you want to delete "${stay.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<StayBloc>().add(DeleteStay(stay.id));
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

class StayIcon {
  final IconData icon;
  final Color color;

  StayIcon(this.icon, this.color);
}

class AddStayBottomSheet extends StatefulWidget {
  final String tripId;
  final String tripCurrency;
  final DateTime tripStartDate;
  final DateTime tripEndDate;

  const AddStayBottomSheet({
    super.key,
    required this.tripId,
    required this.tripCurrency,
    required this.tripStartDate,
    required this.tripEndDate,
  });

  @override
  State<AddStayBottomSheet> createState() => _AddStayBottomSheetState();
}

class _AddStayBottomSheetState extends State<AddStayBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _costController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _contactController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _checkIn;
  DateTime? _checkOut;
  String _selectedStayType = 'Hotel';
  late String _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.tripCurrency;
    _checkIn = widget.tripStartDate;
    _checkOut = widget.tripStartDate.add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _costController.dispose();
    _confirmationController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StayBloc, StayState>(
      listener: (context, state) {
        if (state.status == StayStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? 'Failed to add stay'),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state.status == StayStatus.success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stay added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                          Colors.purple,
                          Colors.purple.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(PhosphorIcons.bed(), color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Accommodation',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Where will you stay?',
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
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Property Name',
                        prefixIcon: Icon(PhosphorIcons.buildings()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter property name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStayType,
                      decoration: InputDecoration(
                        labelText: 'Stay Type',
                        prefixIcon: Icon(PhosphorIcons.tag()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: Stay.stayTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStayType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateField(
                            label: 'Check-in',
                            date: _checkIn,
                            onTap: () => _selectDate(true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateField(
                            label: 'Check-out',
                            date: _checkOut,
                            onTap: () => _selectDate(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address (Optional)',
                        prefixIcon: Icon(PhosphorIcons.mapPin()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _costController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Cost per Night',
                              prefixIcon: Icon(PhosphorIcons.wallet()),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
                            items: ['INR', 'USD', 'EUR', 'GBP']
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
                    TextFormField(
                      controller: _confirmationController,
                      decoration: InputDecoration(
                        labelText: 'Confirmation # (Optional)',
                        prefixIcon: Icon(PhosphorIcons.hashStraight()),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactController,
                      decoration: InputDecoration(
                        labelText: 'Contact Number (Optional)',
                        prefixIcon: Icon(PhosphorIcons.phone()),
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
              BlocBuilder<StayBloc, StayState>(
                builder: (context, state) {
                  final isLoading = state.status == StayStatus.loading;
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
                          onPressed: isLoading ? null : _submitStay,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.purple,
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
                              : const Text('Add Stay'),
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

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(PhosphorIcons.calendar()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          date != null
              ? DateFormat('MMM d, yyyy').format(date)
              : 'Select date',
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isCheckIn) async {
    final initialDate = isCheckIn
        ? (_checkIn ?? widget.tripStartDate)
        : (_checkOut ?? widget.tripStartDate.add(const Duration(days: 1)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: widget.tripStartDate,
      lastDate: widget.tripEndDate.add(const Duration(days: 1)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut != null && _checkOut!.isBefore(picked)) {
            _checkOut = picked.add(const Duration(days: 1));
          }
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  void _submitStay() {
    if (_formKey.currentState!.validate()) {
      if (_checkIn == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select check-in date')),
        );
        return;
      }
      if (_checkOut == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select check-out date')),
        );
        return;
      }

      final costPerNight = double.tryParse(_costController.text);

      context.read<StayBloc>().add(
            AddStay(
              tripId: widget.tripId,
              name: _nameController.text.trim(),
              address: _addressController.text.trim().isEmpty
                  ? null
                  : _addressController.text.trim(),
              stayType: _selectedStayType,
              checkIn: _checkIn!,
              checkOut: _checkOut!,
              costPerNight: costPerNight,
              currency: _selectedCurrency,
              confirmationNumber: _confirmationController.text.trim().isEmpty
                  ? null
                  : _confirmationController.text.trim(),
              contactNumber: _contactController.text.trim().isEmpty
                  ? null
                  : _contactController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          );
    }
  }
}
