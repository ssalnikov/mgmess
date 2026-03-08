import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/services.dart';

import '../../../core/auth/biometric_service.dart';
import '../../../core/config/app_config.dart';
import '../../../core/di/injection.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/emoji_map.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../../blocs/user_status/user_status_cubit.dart';
import '../../widgets/restart_widget.dart';
import '../../widgets/user_avatar.dart';
import '../../widgets/user_display_name.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! AuthAuthenticated) {
            return const Center(child: Text('Not authenticated'));
          }
          final user = state.user;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: UserAvatar(userId: user.id, radius: 50),
              ),
              const SizedBox(height: 16),
              Center(
                child: UserDisplayName(
                  userId: user.id,
                  displayName: user.displayName,
                  style: AppTextStyles.heading1,
                  fallbackEmoji: user.customStatusEmoji,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  '@${user.username}',
                  style: AppTextStyles.bodySmall,
                ),
              ),
              if (user.position.isNotEmpty) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    user.position,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _CustomStatusButton(userId: user.id),
              const SizedBox(height: 12),
              _StatusSelector(userId: user.id),
              const SizedBox(height: 24),
              _ProfileItem(
                icon: Icons.email,
                label: 'Email',
                value: user.email,
              ),
              _ProfileItem(
                icon: Icons.person,
                label: 'First Name',
                value: user.firstName,
              ),
              _ProfileItem(
                icon: Icons.person,
                label: 'Last Name',
                value: user.lastName,
              ),
              if (user.nickname.isNotEmpty)
                _ProfileItem(
                  icon: Icons.badge,
                  label: 'Nickname',
                  value: user.nickname,
                ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.push(RouteNames.editProfile),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () =>
                    context.push(RouteNames.notificationSettings),
                icon: const Icon(Icons.notifications_outlined),
                label: const Text('Notification Settings'),
              ),
              const SizedBox(height: 12),
              _ThemeSelector(),
              const SizedBox(height: 12),
              const _BiometricToggle(),
              const SizedBox(height: 12),
              _ProfileItem(
                icon: Icons.dns,
                label: 'Server',
                value: AppConfig.serverUrl,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showChangeServerDialog(context),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Change Server'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showChangeServerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Server'),
        content: const Text(
          'You will be signed out and redirected to the server selection screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              await AppConfig.clearServerUrl();
              await GetIt.instance.reset();
              if (context.mounted) {
                RestartWidget.restartApp(context);
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}

class _CustomStatusButton extends StatelessWidget {
  final String userId;

  const _CustomStatusButton({required this.userId});

  static const _presets = [
    _CustomStatusPreset('calendar', 'In a meeting'),
    _CustomStatusPreset('car', 'Commuting'),
    _CustomStatusPreset('sick', 'Out sick'),
    _CustomStatusPreset('house', 'Working from home'),
    _CustomStatusPreset('palm_tree', 'On vacation'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserStatusCubit, UserStatusState>(
      builder: (context, state) {
        final cs = state.customStatuses[userId];
        final hasStatus = cs != null && cs.isNotEmpty;

        String label = 'Set a status';
        String? emojiChar;
        if (hasStatus) {
          final shortcode = cs.emoji.replaceAll(':', '');
          emojiChar = emojiMap[shortcode] ?? cs.emoji;
          label = cs.text.isNotEmpty ? cs.text : 'Status';
        }

        return Center(
          child: InkWell(
            onTap: () => _showCustomStatusSheet(context, cs),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emojiChar != null) ...[
                    Text(emojiChar, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                  ] else ...[
                    const Icon(Icons.emoji_emotions_outlined,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: hasStatus
                          ? AppTextStyles.body
                          : AppTextStyles.body
                              .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCustomStatusSheet(BuildContext context, CustomStatus? current) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return _CustomStatusSheet(
          userId: userId,
          current: current,
          presets: _presets,
          parentContext: context,
        );
      },
    );
  }
}

class _CustomStatusPreset {
  final String emoji;
  final String text;

  const _CustomStatusPreset(this.emoji, this.text);
}

class _CustomStatusSheet extends StatefulWidget {
  final String userId;
  final CustomStatus? current;
  final List<_CustomStatusPreset> presets;
  final BuildContext parentContext;

  const _CustomStatusSheet({
    required this.userId,
    required this.current,
    required this.presets,
    required this.parentContext,
  });

  @override
  State<_CustomStatusSheet> createState() => _CustomStatusSheetState();
}

class _CustomStatusSheetState extends State<_CustomStatusSheet> {
  late TextEditingController _textController;
  late String _selectedEmoji;

  @override
  void initState() {
    super.initState();
    _textController =
        TextEditingController(text: widget.current?.text ?? '');
    _selectedEmoji = widget.current?.emoji ?? '';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text('Custom Status',
                    style: AppTextStyles.heading2),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showEmojiPicker,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: _selectedEmoji.isNotEmpty
                            ? Text(
                                _emojiChar(_selectedEmoji),
                                style: const TextStyle(fontSize: 24),
                              )
                            : const Icon(Icons.emoji_emotions_outlined,
                                color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: "What's your status?",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLength: 100,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Quick select',
                    style: AppTextStyles.caption),
              ),
              const SizedBox(height: 4),
              for (final preset in widget.presets)
                ListTile(
                  leading: Text(
                    _emojiChar(preset.emoji),
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(preset.text),
                  dense: true,
                  onTap: () {
                    setState(() {
                      _selectedEmoji = preset.emoji;
                      _textController.text = preset.text;
                    });
                  },
                ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (widget.current != null &&
                        widget.current!.isNotEmpty)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearStatus,
                          child: const Text('Clear'),
                        ),
                      ),
                    if (widget.current != null &&
                        widget.current!.isNotEmpty)
                      const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveStatus,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _emojiChar(String code) {
    final shortcode = code.replaceAll(':', '');
    return emojiMap[shortcode] ?? code;
  }

  void _showEmojiPicker() {
    final commonEmojis = [
      'smile', 'grinning', 'heart_eyes', 'thumbsup', 'thumbsdown',
      'wave', 'clap', 'fire', 'rocket', 'star',
      'coffee', 'beer', 'pizza', 'hamburger', 'tada',
      'calendar', 'car', 'house', 'palm_tree', 'sick',
      'computer', 'phone', 'books', 'bulb', 'muscle',
      'eyes', 'brain', 'sleeping', 'thinking', 'sunglasses',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Choose Emoji', style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: commonEmojis.map((code) {
                    final char = emojiMap[code] ?? ':$code:';
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _selectedEmoji = code);
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selectedEmoji == code
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(char,
                            style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveStatus() {
    final emoji = _selectedEmoji.isNotEmpty
        ? _selectedEmoji
        : 'speech_balloon';
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedEmoji.isEmpty) return;

    HapticFeedback.selectionClick();
    widget.parentContext.read<UserStatusCubit>().updateCustomStatus(
          widget.userId,
          emoji: emoji,
          text: text,
        );
    Navigator.pop(context);
  }

  void _clearStatus() {
    HapticFeedback.selectionClick();
    widget.parentContext.read<UserStatusCubit>().clearCustomStatus(widget.userId);
    Navigator.pop(context);
  }
}

class _StatusSelector extends StatelessWidget {
  final String userId;

  const _StatusSelector({required this.userId});

  static const _statusOptions = [
    _StatusOption('online', 'Online', 'You appear as active', AppColors.online),
    _StatusOption('away', 'Away', 'You appear as away', AppColors.away),
    _StatusOption('dnd', 'Do Not Disturb', 'Notifications are disabled', AppColors.dnd),
    _StatusOption('offline', 'Offline', 'You appear as offline', AppColors.offline),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserStatusCubit, UserStatusState>(
      builder: (context, state) {
        final currentStatus = state.statuses[userId] ?? 'offline';
        final option = _statusOptions.firstWhere(
          (o) => o.key == currentStatus,
          orElse: () => _statusOptions.last,
        );
        return InkWell(
          onTap: () => _showStatusSheet(context, currentStatus),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: option.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(option.label, style: AppTextStyles.body),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStatusSheet(BuildContext context, String currentStatus) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Status', style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              for (final option in _statusOptions)
                ListTile(
                  leading: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: option.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(option.label),
                  subtitle: Text(option.description, style: AppTextStyles.caption),
                  trailing: currentStatus == option.key
                      ? const Icon(Icons.check, color: AppColors.accent)
                      : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    if (currentStatus != option.key) {
                      HapticFeedback.selectionClick();
                      context.read<UserStatusCubit>().updateStatus(
                            userId,
                            option.key,
                          );
                    }
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _StatusOption {
  final String key;
  final String label;
  final String description;
  final Color color;

  const _StatusOption(this.key, this.label, this.description, this.color);
}

class _ThemeSelector extends StatelessWidget {
  static const _options = [
    (mode: ThemeMode.system, label: 'System', icon: Icons.settings_brightness),
    (mode: ThemeMode.light, label: 'Light', icon: Icons.light_mode),
    (mode: ThemeMode.dark, label: 'Dark', icon: Icons.dark_mode),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.palette, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text('Appearance', style: AppTextStyles.body),
                ],
              ),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: _options
                    .map((o) => ButtonSegment<ThemeMode>(
                          value: o.mode,
                          label: Text(o.label, style: const TextStyle(fontSize: 12)),
                          icon: Icon(o.icon, size: 16),
                        ))
                    .toList(),
                selected: {state.themeMode},
                onSelectionChanged: (selected) {
                  context.read<ThemeCubit>().setThemeMode(selected.first);
                },
                showSelectedIcon: false,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BiometricToggle extends StatefulWidget {
  const _BiometricToggle();

  @override
  State<_BiometricToggle> createState() => _BiometricToggleState();
}

class _BiometricToggleState extends State<_BiometricToggle> {
  final _bio = sl<BiometricService>();
  bool _available = false;
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await _bio.isAvailable();
    final enabled = await _bio.isEnabled();
    if (mounted) {
      setState(() {
        _available = available;
        _enabled = enabled;
        _loading = false;
      });
    }
  }

  Future<void> _onChanged(bool value) async {
    if (value) {
      // Verify biometric before enabling
      final success = await _bio.authenticate();
      if (!success) return;
    }
    await _bio.setEnabled(value);
    setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || !_available) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.fingerprint, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Biometric Lock', style: AppTextStyles.body),
          ),
          Switch(
            value: _enabled,
            onChanged: _onChanged,
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              Text(value, style: AppTextStyles.body),
            ],
          ),
        ],
      ),
    );
  }
}
