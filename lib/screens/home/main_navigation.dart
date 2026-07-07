import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import '../schedule/schedule_screen.dart';
import '../donations/donations_screen.dart';
import '../expenses/expenses_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final UserModel user;
  const MainNavigation({super.key, required this.user});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late UserModel _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  @override
  void didUpdateWidget(MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final o = oldWidget.user;
    final n = widget.user;
    // Firestore role/name updates (e.g. admin in console) must reach tabs; initState won't run again.
    if (o.uid != n.uid ||
        o.role != n.role ||
        o.name != n.name ||
        o.mobile != n.mobile) {
      setState(() => _user = n);
    }
  }

  void _onUserUpdated(UserModel user) {
    setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        user: _user,
        onOpenExpensesTab: () => setState(() => _currentIndex = 3),
      ),
      ScheduleScreen(user: _user),
      DonationsScreen(user: _user),
      ExpensesScreen(user: _user),
      ProfileScreen(user: _user, onUserUpdated: _onUserUpdated),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textSecondary,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'मुख्यपृष्ठ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'कार्यक्रम',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism_outlined),
              activeIcon: Icon(Icons.volunteer_activism),
              label: 'देणगी',
            ),
            BottomNavigationBarItem(
              icon: _user.isAdmin
                  ? badges.Badge(
                      badgeAnimation: const badges.BadgeAnimation.scale(),
                      child: const Icon(Icons.receipt_long_outlined),
                    )
                  : const Icon(Icons.receipt_long_outlined),
              activeIcon: const Icon(Icons.receipt_long),
              label: 'खर्च',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'प्रोफाइल',
            ),
          ],
        ),
      ),
    );
  }
}
