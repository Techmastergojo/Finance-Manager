import 'package:digital_khata/screens/content/home/main_home_screen.dart';
import 'package:digital_khata/screens/content/people/add_people_screen.dart';
import 'package:digital_khata/screens/content/payments/payments_screen.dart';
import 'package:digital_khata/screens/content/khata/khata_list_screen.dart';
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
    PaymentsScreen(),
    KhataListScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;
    final tertiary = Theme.of(context).colorScheme.tertiary;

    return Scaffold(
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (v) => setState(() => _index = v),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primary,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payments_outlined),
              activeIcon: Icon(Icons.payments),
              label: 'Payments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Khata',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _index == 0
          ? FloatingActionButton(
              shape: const CircleBorder(),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const AddPeopleScreen(type: 'due'),
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
    );
  }
}
