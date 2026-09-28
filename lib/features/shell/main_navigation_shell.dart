import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../crops/crop_catalog_screen.dart';
import '../tools/tools_conversion_screen.dart';
import '../innovation/innovation_hub_screen.dart';
import '../profile/profile_feedback_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final VoidCallback? onThemeToggle;
  const MainNavigationShell({super.key, this.onThemeToggle});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = [
      DashboardScreen(onNavigateTab: _onTabSelected),
      const CropCatalogScreen(),
      const ToolsConversionScreen(),
      const InnovationHubScreen(),
      ProfileFeedbackScreen(onThemeToggle: widget.onThemeToggle),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        backgroundColor: isDark ? const Color(0xFF1E2621) : Colors.white,
        indicatorColor: AppTheme.primaryGreen.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.primaryGreen),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            selectedIcon: Icon(Icons.grass_rounded, color: AppTheme.primaryGreen),
            label: 'Crops',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_circle_outlined),
            selectedIcon: Icon(Icons.build_circle_rounded, color: AppTheme.primaryGreen),
            label: 'Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.hub_outlined),
            selectedIcon: Icon(Icons.hub_rounded, color: AppTheme.primaryGreen),
            label: 'Innovation',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppTheme.primaryGreen),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
