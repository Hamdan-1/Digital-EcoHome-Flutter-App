import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class DarkModeToggle extends StatelessWidget {
  final String? title;
  final String? subtitle;
    const DarkModeToggle({
    super.key, 
    this.title = 'Dark Mode',
    this.subtitle = 'Switch between light and dark theme',
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return SwitchListTile(
          title: Text(title ?? 'Dark Mode'),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          secondary: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: Theme.of(context).iconTheme.color,
          ),
          value: themeProvider.isDarkMode,
          activeColor: Theme.of(context).colorScheme.primary,
          onChanged: (_) {
            themeProvider.toggleTheme();
          },
        );
      },
    );
  }
}
