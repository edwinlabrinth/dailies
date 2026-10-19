import 'dart:async';

import 'package:flutter/material.dart';

import '../data/demo_habits.dart';
import '../data/guild_controller.dart';
import '../data/habit_store.dart';
import '../models/habit.dart';
import '../models/level.dart';
import '../models/online.dart';
import '../widgets/add_habit_dialog.dart';
import '../widgets/habit_tile.dart';
import '../widgets/level_card.dart';
import '../widgets/world_boss_card.dart';
import 'guild_screen.dart';

/// Main screen: level header, momentum stats, habit list.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.store,
    this.clock,
    this.demoMode = false,
    this.guild,
  });

  /// Injectable for tests.
  final HabitStore? store;

  /// Injectable "now" for tests.
  final DateTime Function()? clock;

  /// Seeds sample habits when storage is empty and skips all writes.
  final bool demoMode;

  /// Injectable online controller for tests. When null the screen creates one.
  final GuildController? guild;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HabitStore _store;
  late final GuildController _guild;
  late final bool _ownsGuild;
  Timer? _pushTimer;
  List<Habit> _habits = const [];
  WorldState? _demoWorld;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? HabitStore();
    _ownsGuild = widget.guild == null;
    _guild = widget.guild ?? GuildController();
    _boot();
  }

  DateTime _today() => (widget.clock ?? DateTime.now)();

  Future<void> _boot() async {
    final isDemo = widget.demoMode;
    final habits = isDemo ? demoHabits(today: _today()) : await _store.load();
    if (!mounted) return;
    setState(() {
      _habits = habits;
      _demoWorld = isDemo ? demoWorld(today: _today()) : null;
      _loading = false;
    });
    if (isDemo) return;

    await _guild.restore();
    if (!mounted || !_guild.isOnline) return;

    if (_habits.isEmpty) {
      // A fresh device: pull the cloud save back in.
      final restored = await _guild.pull();
      if (restored != null && restored.isNotEmpty && mounted) {
        setState(() => _habits = restored);
        await _store.save(_habits);
      }
    } else {
      _schedulePush();
    }
  }

  /// Demo sessions are throwaway — they never touch storage.
  void _persist() {
    if (widget.demoMode) return;
    _store.save(_habits);
    _schedulePush();
  }

  /// While online, changes are pushed to the cloud after a short pause so a
  /// burst of taps costs exactly one request.
  void _schedulePush() {
    if (!_guild.isOnline) return;
    _pushTimer?.cancel();
    _pushTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) _guild.sync(_habits);
    });
  }

  Future<void> _openGuild() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GuildScreen(
          controller: _guild,
          currentHabits: () => _habits,
          onRestore: (habits) {
            if (!mounted) return;
            setState(() => _habits = habits);
            _store.save(_habits);
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pushTimer?.cancel();
    if (_ownsGuild) _guild.dispose();
    super.dispose();
  }

  void _toggle(Habit habit) {
    final today = _today();
    final levelBefore = levelForXp(totalXp(_habits));

    setState(() {
      _habits = [
        for (final h in _habits)
          h.id == habit.id
              ? (h.isDoneOn(today) ? h.markUndone(today) : h.markDone(today))
              : h,
      ];
    });
    _persist();

    final xp = totalXp(_habits);
    final levelAfter = levelForXp(xp);
    if (levelAfter > levelBefore) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Level $levelAfter! $xp XP and counting'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _addHabit() async {
    final habit = await AddHabitDialog.show(context);
    if (habit == null) return;
    setState(() => _habits = [..._habits, habit]);
    _persist();
  }

  Future<void> _delete(Habit habit) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete "${habit.name}"?'),
        content: const Text('Its streak and XP history will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            key: const Key('confirm-delete'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final index = _habits.indexWhere((h) => h.id == habit.id);
    setState(() => _habits = _habits.where((h) => h.id != habit.id).toList());
    _persist();

    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${habit.name}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _habits = [..._habits]
                ..insert(index.clamp(0, _habits.length), habit);
            });
            _persist();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _guild,
      builder: (context, _) {
        final today = _today();
        final xp = totalXp(_habits);
        final doneToday = _habits.where((h) => h.isDoneOn(today)).length;
        final bestStreak = _habits.isEmpty
            ? 0
            : _habits
                .map((h) => h.streakOn(today))
                .reduce((a, b) => a > b ? a : b);
        final world = _guild.world ?? _demoWorld;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'DAILIES',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'level up daily',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                        letterSpacing: 1.5,
                      ),
                ),
              ],
            ),
            actions: [
              IconButton(
                key: const Key('guild-button'),
                tooltip: 'Guild hall',
                onPressed: _openGuild,
                icon: Icon(
                  _guild.isOnline ? Icons.groups_2 : Icons.groups_2_outlined,
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            key: const Key('add_habit_fab'),
            onPressed: _addHabit,
            icon: const Icon(Icons.add),
            label: const Text('New habit'),
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    LevelCard(xp: xp),
                    if (world != null) ...[
                      const SizedBox(height: 12),
                      WorldBossCard(
                        world: world,
                        compact: true,
                        onTap: widget.demoMode ? null : _openGuild,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _MomentumStat(
                          key: const Key('today-stat'),
                          icon: Icons.check_circle_outline,
                          label: 'Today',
                          value: '$doneToday/${_habits.length}',
                        ),
                        const SizedBox(width: 10),
                        _MomentumStat(
                          icon: Icons.local_fire_department,
                          label: 'Best streak',
                          value: bestStreak > 0 ? '$bestStreak d' : '—',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'HABITS',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                          Text(
                            '${_habits.length}',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_habits.isEmpty)
                      const _EmptyState()
                    else
                      for (final habit in _habits) ...[
                        HabitTile(
                          habit: habit,
                          today: today,
                          onToggle: () => _toggle(habit),
                          onDelete: () => _delete(habit),
                        ),
                        const SizedBox(height: 10),
                      ],
                  ],
                ),
        );
      },
    );
  }
}

class _MomentumStat extends StatelessWidget {
  const _MomentumStat({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1B26),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: style.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(label, style: style.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.trending_up_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No habits yet',
            style: style.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "New habit" to start your streak.\nEvery check-off earns XP.',
            textAlign: TextAlign.center,
            style: style.bodyMedium?.copyWith(
              color: style.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
