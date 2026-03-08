import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/repositories/channel_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

class CreateChannelScreen extends StatefulWidget {
  const CreateChannelScreen({super.key});

  @override
  State<CreateChannelScreen> createState() => _CreateChannelScreenState();
}

class _CreateChannelScreenState extends State<CreateChannelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _nameController = TextEditingController();
  final _purposeController = TextEditingController();
  final _headerController = TextEditingController();
  ChannelType _channelType = ChannelType.open;
  bool _isLoading = false;
  bool _nameManuallyEdited = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _nameController.dispose();
    _purposeController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  String _generateSlug(String displayName) {
    return displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\-_]'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : _generateSlug(_displayNameController.text.trim());

    final result = await sl<ChannelRepository>().createChannel(
      teamId: authState.teamId,
      name: name,
      displayName: _displayNameController.text.trim(),
      type: _channelType,
      purpose: _purposeController.text.trim(),
      header: _headerController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (channel) {
        HapticFeedback.lightImpact();
        // Navigate to the new channel
        context.go(
          RouteNames.chatPath(channel.id),
          extra: <String, dynamic>{
            'channelName': channel.displayName,
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Channel'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _create,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Channel type selector
            SegmentedButton<ChannelType>(
              segments: const [
                ButtonSegment(
                  value: ChannelType.open,
                  label: Text('Public'),
                  icon: Icon(Icons.tag),
                ),
                ButtonSegment(
                  value: ChannelType.private_,
                  label: Text('Private'),
                  icon: Icon(Icons.lock),
                ),
              ],
              selected: {_channelType},
              onSelectionChanged: (v) =>
                  setState(() => _channelType = v.first),
            ),
            const SizedBox(height: 16),
            Text(
              _channelType == ChannelType.open
                  ? 'Public channels can be found and joined by anyone'
                  : 'Private channels are only visible to invited members',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _displayNameController,
              decoration: const InputDecoration(
                labelText: 'Channel name',
                hintText: 'e.g. Project Updates',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
              onChanged: (v) {
                if (!_nameManuallyEdited) {
                  _nameController.text = _generateSlug(v);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'e.g. project-updates',
                border: OutlineInputBorder(),
                prefixText: '~',
              ),
              onChanged: (_) => _nameManuallyEdited = true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (RegExp(r'[^a-z0-9\-_]').hasMatch(v.trim())) {
                  return 'Only lowercase letters, numbers, - and _';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _purposeController,
              decoration: const InputDecoration(
                labelText: 'Purpose (optional)',
                hintText: 'Describe the channel purpose',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _headerController,
              decoration: const InputDecoration(
                labelText: 'Header (optional)',
                hintText: 'Markdown-supported header text',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
