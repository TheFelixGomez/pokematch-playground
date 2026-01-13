import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'main.dart'; // To access themeModeProvider

class SettingsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
          ),
          ExpansionTile(
            title: Text('Theme'),
            leading: Icon(Icons.palette),
            children: [
              RadioListTile<ThemeMode>(
                title: Text('System'),
                value: ThemeMode.system,
                groupValue: themeMode,
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value!);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text('Light'),
                value: ThemeMode.light,
                groupValue: themeMode,
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value!);
                },
              ),
              RadioListTile<ThemeMode>(
                title: Text('Dark'),
                value: ThemeMode.dark,
                groupValue: themeMode,
                onChanged: (value) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value!);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
