import 'package:flutter/material.dart';

/// Navigation controller for bottom navigation state
class NavigationController extends ChangeNotifier {
  int _currentIndex = 0;
  double _homeScrollOffset = 0.0;

  int get currentIndex => _currentIndex;
  double get homeScrollOffset => _homeScrollOffset;

  /// Update home scroll offset
  void setHomeScrollOffset(double offset) {
    if (_homeScrollOffset != offset) {
      _homeScrollOffset = offset;
      notifyListeners();
    }
  }

  /// Navigation items configuration
  static const List<NavigationItem> items = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    NavigationItem(
      icon: Icons.local_fire_department_outlined,
      activeIcon: Icons.local_fire_department,
      label: 'Popular',
    ),
    NavigationItem(
      icon: Icons.category_outlined, 
      activeIcon: Icons.category,
      label: 'Genres',
    ),
    NavigationItem(
      icon: Icons.update_outlined,
      activeIcon: Icons.update,
      label: 'Latest',
    ),
    NavigationItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: 'History',
    ),
    NavigationItem(
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite,
      label: 'Favorites',
    ),
  ];

  /// Change current navigation index
  void setIndex(int index) {
    if (index != _currentIndex && index >= 0 && index < items.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Navigate to home
  void goToHome() => setIndex(0);

  /// Navigate to popular
  void goToPopular() => setIndex(1);

  /// Navigate to genres
  void goToGenres() => setIndex(2);

  /// Navigate to latest
  void goToLatest() => setIndex(3);

  /// Navigate to history
  void goToHistory() => setIndex(4);

  /// Navigate to favorites
  void goToFavorites() => setIndex(5);
}

/// Navigation item configuration
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
