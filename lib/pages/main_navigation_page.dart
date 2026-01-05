import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'my_trips_page.dart';
import 'expenses_page.dart';
import 'history_page.dart';
import 'for_you_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const MyTripsPage(),
    const ExpensesPage(),
    const HistoryPage(),
    const ForYouPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.airplane()),
            activeIcon: Icon(PhosphorIcons.airplane(PhosphorIconsStyle.fill)),
            label: 'My Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.wallet()),
            activeIcon: Icon(PhosphorIcons.wallet(PhosphorIconsStyle.fill)),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.clockCounterClockwise()),
            activeIcon: Icon(PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.fill)),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(PhosphorIcons.sparkle()),
            activeIcon: Icon(PhosphorIcons.sparkle(PhosphorIconsStyle.fill)),
            label: 'For You',
          ),
        ],
      ),
    );
  }
}