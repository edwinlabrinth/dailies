import 'dart:math';

import 'package:flutter/material.dart';

import '../models/habit.dart';
import '../models/habit_icons.dart';
import '../theme.dart';

/// Dialog for creating a new habit: name + icon picker.
/// Returns the freshly built [Habit], or null if cancelled.
class AddHabitDialog extends StatefulWidget {
  const AddHabitDialog({super.key});

  static Future<Habit?> show(BuildContext context) =>
      showDialog<Habit>(context: context, builder: (_) => const AddHabitDialog());

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final TextEditingController _controller = TextEditingController();
  int _iconIndex = 0;
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(
      Habit(
        id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
        name: name,
        iconIndex: _iconIndex,
        colorIndex: Random().nextInt(kHabitColors.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text('New habit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('habit-name-field'),
              controller: _controller,
              autofocus: true,
              maxLength: 40,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'e.g. Read 20 pages',
                counterText: '',
                errorText: _showError ? 'Give your habit a name' : null,
              ),
              onChanged: (_) {
                if (_showError) setState(() => _showError = false);
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Text(
              'PICK AN ICON',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < kHabitIcons.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _iconIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: i == _iconIndex
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFF2C2A3A),
                      ),
                      child: Icon(
                        kHabitIcons[i],
                        size: 22,
                        color: i == _iconIndex
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('add-habit-confirm'),
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
