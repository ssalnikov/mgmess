import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/l10n.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _enabled = true;
  String _filter = 'all';
  bool _loading = true;

  static const _prefKeyEnabled = 'notification_enabled';
  static const _prefKeyFilter = 'notification_filter';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enabled = prefs.getBool(_prefKeyEnabled) ?? true;
      _filter = prefs.getString(_prefKeyFilter) ?? 'all';
      _loading = false;
    });
  }

  Future<void> _setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyEnabled, value);
    setState(() => _enabled = value);
  }

  Future<void> _setFilter(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyFilter, value);
    setState(() => _filter = value);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.notifications)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.notifications)),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(context.l10n.pushNotifications),
            subtitle: Text(context.l10n.receiveNotificationsSubtitle),
            value: _enabled,
            onChanged: _setEnabled,
          ),
          const Divider(),
          if (_enabled) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                context.l10n.notifyMeAbout,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            RadioGroup<String>(
              groupValue: _filter,
              onChanged: (v) {
                if (v != null) _setFilter(v);
              },
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Text(context.l10n.allNewMessages),
                    value: 'all',
                  ),
                  RadioListTile<String>(
                    title: Text(context.l10n.mentionsAndDM),
                    value: 'mentions_dm',
                  ),
                  RadioListTile<String>(
                    title: Text(context.l10n.dmOnly),
                    value: 'dm_only',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
