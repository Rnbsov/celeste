import 'package:flutter/material.dart';
import 'package:myapp/screens/analytics_screen.dart';

import 'today_screen.dart';
import 'chatbot_screen.dart';
import 'learn_screen.dart';
import 'profile_screen.dart';
import 'add_plant_screen.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  final String email;

  final String displayName;

  const HomeScreen({super.key, required this.email, required this.displayName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String get username {
    return widget.email.split('@')[0];
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      TodayScreen(username: widget.displayName),
      ChatbotScreen(),
      AnalyticsScreen(),
      ProfileScreen(email: widget.email, displayName: widget.displayName),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      floatingActionButton:
          _selectedIndex ==
                  0 // Only show on Today screen
              ? FloatingActionButton(
                heroTag:
                    'homeScreenFAB', // Add this line to fix hero animation conflict
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPlantScreen(),
                    ),
                  ).then((value) {
                    // Refresh Today screen when returning from add plant
                    if (value == true) {
                      // Cast to TodayScreen to access its refresh method
                      final todayScreen = screens[0] as TodayScreen;
                      todayScreen.refreshPlants();
                    }
                  });
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white, // White icon
                child: const Icon(Icons.add),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          showUnselectedLabels: true,
          items: [
            _buildNavItem(context, Icons.today, 'Today', 0),
            _buildNavItem(context, Icons.chat, 'Chatbot', 1),
            _buildNavItem(context, Icons.school, 'Analytics', 2),
            _buildNavItem(context, Icons.person, 'Profile', 3),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = _selectedIndex == index;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(10.0),
        margin: const EdgeInsets.only(bottom: 4.0, top: 8.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isSelected ? primaryColor.withOpacity(0.15) : Colors.transparent,
        ),
        child: Icon(
          icon,
          color:
              isSelected
                  ? primaryColor
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      label: label,
    );
  }
}
