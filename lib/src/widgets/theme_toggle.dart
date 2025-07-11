import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return IconButton(
          onPressed: () => themeService.toggleTheme(),
          icon: Icon(
            _getThemeIcon(themeService.themeMode),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          tooltip: _getThemeTooltip(themeService.themeMode),
        );
      },
    );
  }

  IconData _getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.settings_brightness;
    }
  }

  String _getThemeTooltip(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light mode (click for dark)';
      case AppThemeMode.dark:
        return 'Dark mode (click for system)';
      case AppThemeMode.system:
        return 'System mode (click for light)';
    }
  }
}