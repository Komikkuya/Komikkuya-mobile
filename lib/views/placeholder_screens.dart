import 'package:flutter/material.dart';
import '../config/app_theme.dart';

// Note: HistoryScreen has been moved to history_screen.dart

/// Generic placeholder screen widget
class _PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlaceholderScreen({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppTheme.accentPurple.withOpacity(0.5)),
          const SizedBox(height: AppTheme.spacingL),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
