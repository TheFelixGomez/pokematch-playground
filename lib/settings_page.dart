import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'providers/notification_provider.dart';
import 'services/notification_service.dart';
import 'main.dart'; // To access themeModeProvider

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

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
            title: const Text('Theme'),
            leading: const Icon(Icons.palette),
            children: [
              RadioGroup<ThemeMode>(
                groupValue: themeMode,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(themeModeProvider.notifier).setThemeMode(value);
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('System'),
                      value: ThemeMode.system,
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),
            ],
          ),
          _RemindersSection(),
        ],
      ),
    );
  }
}

class _RemindersSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_RemindersSection> createState() => _RemindersSectionState();
}

class _RemindersSectionState extends ConsumerState<_RemindersSection> {
  final TextEditingController _controller = TextEditingController();
  bool _isExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final interval = ref.watch(notificationIntervalProvider);
    final isEnabled = interval != null;

    if (interval != null && _controller.text.isEmpty) {
        _controller.text = interval.toString();
    }

    return ExpansionTile(
      title: const Text('Reminders'),
      leading: const Icon(Icons.alarm),
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (expanded) => setState(() => _isExpanded = expanded),
      children: [
        SwitchListTile(
          title: const Text('Enable Reminders'),
          subtitle: const Text('Remind me to open the app'),
          value: isEnabled,
          onChanged: (value) {
            if (value) {
               ref.read(notificationIntervalProvider.notifier).setInterval(60);
               _controller.text = "60";
            } else {
               ref.read(notificationIntervalProvider.notifier).setInterval(null);
               _controller.clear();
            }
          },
        ),
        if (isEnabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    labelText: 'Interval (seconds)',
                    border: OutlineInputBorder(),
                    helperText: 'Seconds until next reminder',
                ),
                onChanged: (value) {
                    final seconds = int.tryParse(value);
                    if (seconds != null && seconds > 0) {
                        ref.read(notificationIntervalProvider.notifier).setInterval(seconds);
                    }
                },
            ),
          ),
        if (isEnabled)
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextButton(
                    onPressed: () {
                        NotificationService().showImmediateNotification();
                    },
                    child: const Text('Test Notification Now'),
                ),
            ),
      ],
    );
  }
}
