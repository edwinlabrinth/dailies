import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/guild_controller.dart';
import '../models/habit.dart';
import '../models/online.dart';
import '../utils/format.dart';
import '../widgets/world_boss_card.dart';

/// The social, online side of Dailies.
///
/// Optional by design: you can track habits forever without ever opening this
/// screen. Joining gives you a cloud backup, a weekly leaderboard and a world
/// boss that the whole guild fights together.
class GuildScreen extends StatefulWidget {
  const GuildScreen({
    super.key,
    required this.controller,
    this.currentHabits,
    this.onRestore,
  });

  final GuildController controller;

  /// Supplies the habits to push when the user asks for a sync.
  final List<Habit> Function()? currentHabits;

  /// Called after claiming an account, with the habits from the cloud.
  final ValueChanged<List<Habit>>? onRestore;

  @override
  State<GuildScreen> createState() => _GuildScreenState();
}

class _GuildScreenState extends State<GuildScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _working = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      _say('Names need at least 2 characters.');
      return;
    }
    setState(() => _working = true);
    final ok = await widget.controller.register(name);
    if (!mounted) return;
    setState(() => _working = false);
    if (!ok) {
      _say(widget.controller.error ?? 'Could not join the guild.');
      return;
    }
    _say('Welcome to the guild, ${widget.controller.session?.name}!');
    final habits = widget.currentHabits?.call() ?? const <Habit>[];
    if (habits.isNotEmpty) await widget.controller.sync(habits);
  }

  Future<void> _claim() async {
    final code = _codeController.text.trim();
    if (code.length < 8) {
      _say('That code looks too short.');
      return;
    }
    setState(() => _working = true);
    final habits = await widget.controller.claim(code);
    if (!mounted) return;
    setState(() => _working = false);
    if (habits == null) {
      _say(widget.controller.error ?? 'That code did not work.');
      return;
    }
    if (habits.isNotEmpty) widget.onRestore?.call(habits);
    _say('Welcome back, ${widget.controller.session?.name}!');
  }

  Future<void> _sync() async {
    final habits = widget.currentHabits?.call();
    if (habits == null) return;
    setState(() => _working = true);
    final ok = await widget.controller.sync(habits);
    if (!mounted) return;
    setState(() => _working = false);
    _say(ok
        ? 'Cloud save updated — ${habits.length} habits.'
        : widget.controller.error ?? 'Sync failed.');
  }

  Future<void> _rotateCode() async {
    setState(() => _working = true);
    final code = await widget.controller.rotateSyncCode();
    if (!mounted) return;
    setState(() => _working = false);
    _say(code == null
        ? 'Could not create a new sync code.'
        : 'New sync code: $code');
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign out of the guild?'),
        content: const Text(
          'Your dailies stay on this device. The cloud copy keeps its own '
          'progress until you sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.controller.signOut();
    if (mounted) _say('Signed out. Your dailies are still here.');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final online = widget.controller.isOnline;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'GUILD HALL',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.4),
            ),
            actions: [
              if (online)
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _working ? null : widget.controller.refresh,
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          body: online ? _onlineBody(context) : _setupBody(context),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Not online yet

  Widget _setupBody(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        const Center(child: Text('🏰', style: TextStyle(fontSize: 56))),
        const SizedBox(height: 12),
        Text(
          'Join the guild hall',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'An optional cloud save, a weekly leaderboard, and a world boss '
          'that every check-off in the guild chips away at.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'CREATE YOUR IDENTITY',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('guild-name-field'),
                  controller: _nameController,
                  maxLength: 24,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Guild name',
                    hintText: 'e.g. Night Owl',
                    counterText: '',
                  ),
                  onSubmitted: (_) => _register(),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('guild-register'),
                  onPressed: _working ? null : _register,
                  child: _working
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enter the guild'),
                ),
                const SizedBox(height: 10),
                Text(
                  'No email, no password. You get a sync code to carry your '
                  'progress to other devices.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ALREADY IN THE GUILD?',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('guild-code-field'),
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Sync code',
                    hintText: 'ABCD-EFGH-JKLM',
                  ),
                  onSubmitted: (_) => _claim(),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  key: const Key('guild-claim'),
                  onPressed: _working ? null : _claim,
                  child: const Text('Restore my progress'),
                ),
              ],
            ),
          ),
        ),
        if (widget.controller.error != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.controller.error!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Online

  Widget _onlineBody(BuildContext context) {
    final controller = widget.controller;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stats = controller.stats;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: scheme.primary.withValues(alpha: 0.18),
                      child: Text(
                        controller.session!.name.characters.first.toUpperCase(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.session!.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'GUILD MEMBER',
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.6,
                              color:
                                  scheme.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.busy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (stats != null) ...[
                  Row(
                    children: [
                      _StatPill(
                        label: 'THIS WEEK',
                        value: '${formatXp(stats.weeklyXp)} XP',
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        label: 'TOTAL',
                        value: '${formatXp(stats.totalXp)} XP',
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        label: 'BEST STREAK',
                        value: '${stats.streak} d',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                if (controller.session!.syncCode != null)
                  _SyncCodeBox(
                    code: controller.session!.syncCode!,
                    onCopy: () async {
                      await Clipboard.setData(
                        ClipboardData(text: controller.session!.syncCode!),
                      );
                      _say('Sync code copied.');
                    },
                  ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('guild-sync'),
                  onPressed: _working ? null : _sync,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Sync now'),
                ),
              ],
            ),
          ),
        ),
        if (controller.world != null) ...[
          const SizedBox(height: 12),
          WorldBossCard(world: controller.world!),
        ],
        const SizedBox(height: 22),
        _Leaderboard(
          leaders: controller.leaders,
          me: controller.session?.name,
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            TextButton.icon(
              key: const Key('guild-new-code'),
              onPressed: _working ? null : _rotateCode,
              icon: const Icon(Icons.vpn_key_outlined, size: 18),
              label: const Text('New sync code'),
            ),
            TextButton.icon(
              onPressed: _working ? null : _signOut,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign out'),
            ),
          ],
        ),
        if (controller.lastSync != null)
          Text(
            'Last synced ${_timeAgo(controller.lastSync!)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        if (controller.error != null) ...[
          const SizedBox(height: 10),
          Text(
            controller.error!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }

  static String _timeAgo(DateTime time) {
    final seconds = DateTime.now().difference(time).inSeconds;
    if (seconds < 10) return 'just now';
    if (seconds < 60) return '${seconds}s ago';
    final minutes = seconds ~/ 60;
    if (minutes < 60) return '${minutes}m ago';
    return '${minutes ~/ 60}h ago';
  }
}

class _SyncCodeBox extends StatelessWidget {
  const _SyncCodeBox({required this.code, required this.onCopy});

  final String code;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onCopy,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.vpn_key_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                code,
                style: theme.textTheme.bodyMedium?.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.copy,
              size: 16,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.leaders, this.me});

  final List<LeaderEntry> leaders;
  final String? me;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                'GUILD LEADERBOARD',
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              Text(
                'this week',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Card(
          child: leaders.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No one has logged XP this week yet. Be the first.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < leaders.length; i++)
                      _LeaderRow(
                        entry: leaders[i],
                        rank: i,
                        isMe: me != null && leaders[i].name == me,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({
    required this.entry,
    required this.rank,
    required this.isMe,
  });

  final LeaderEntry entry;
  final int rank;
  final bool isMe;

  static const List<String> _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isMe ? scheme.primary.withValues(alpha: 0.10) : null,
        border: rank == 0
            ? null
            : Border(
                top: BorderSide(
                  color: scheme.onSurface.withValues(alpha: 0.06),
                ),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              rank < _medals.length ? _medals[rank] : '#${rank + 1}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isMe ? '${entry.name}  (you)' : entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isMe ? FontWeight.w800 : FontWeight.w500,
                color: isMe ? scheme.primary : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.weeklyXp} XP',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
