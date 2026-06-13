import 'package:digital_khata/screens/content/cashbook/cashbook_screen.dart';
import 'package:digital_khata/screens/content/home/main_home_screen.dart';
import 'package:digital_khata/screens/content/people/add_people_screen.dart';
import 'package:digital_khata/screens/content/people/list_people_screen.dart';
import 'package:digital_khata/screens/content/reports/reports_screen.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  Future<void> _refreshData() async => setState(() {});

  final List<Widget> _screens = const [
    MainHomeScreen(),
    ListPeopleScreen(),
    CashbookScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final tertiary = Theme.of(context).colorScheme.tertiary;

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Scaffold(
        bottomNavigationBar: ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (v) => setState(() => _index = v),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: primary,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Customers',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book),
                label: 'Cashbook',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Reports',
              ),
            ],
          ),
        ),
        floatingActionButtonLocation:
            FloatingActionButtonLocation.centerDocked,
        floatingActionButton: _index == 0 || _index == 1
            ? FloatingActionButton(
                shape: const CircleBorder(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AddPeopleScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: LinearGradient(
                      colors: [tertiary, secondary, primary],
                      transform: GradientRotation(pi / 4),
                    ),
                  ),
                  child: const Icon(Icons.person_add, color: Colors.white),
                ),
              )
            : null,
        body: _screens[_index],
      ),
    );
  }
}
