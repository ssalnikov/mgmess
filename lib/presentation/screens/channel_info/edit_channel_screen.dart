import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/channel.dart';
import '../../../domain/repositories/channel_repository.dart';
import 'channel_info_cubit.dart';

class EditChannelScreen extends StatefulWidget {
  final String channelId;

  const EditChannelScreen({super.key, required this.channelId});

  @override
  State<EditChannelScreen> createState() => _EditChannelScreenState();
}

class _EditChannelScreenState extends State<EditChannelScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ChannelInfoCubit _cubit;
  late final TextEditingController _displayNameController;
  late final TextEditingController _headerController;
  late final TextEditingController _purposeController;
  bool _isSaving = false;
  bool _isLoading = true;
  Channel? _channel;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController();
    _headerController = TextEditingController();
    _purposeController = TextEditingController();
    _cubit = ChannelInfoCubit(channelRepository: sl<ChannelRepository>());
    _loadChannel();
  }

  Future<void> _loadChannel() async {
    final repo = sl<ChannelRepository>();
    final result = await repo.getChannel(widget.channelId);
    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
          context.pop();
        }
      },
      (channel) {
        if (mounted) {
          setState(() {
            _channel = channel;
            _displayNameController.text = channel.displayName;
            _headerController.text = channel.header;
            _purposeController.text = channel.purpose;
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _headerController.dispose();
    _purposeController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_channel == null) return;

    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    final data = <String, dynamic>{
      'id': widget.channelId,
      'display_name': _displayNameController.text.trim(),
      'header': _headerController.text.trim(),
      'purpose': _purposeController.text.trim(),
    };

    final success = await _cubit.updateChannel(widget.channelId, data);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      context.pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось обновить канал')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать канал'),
        actions: [
          TextButton(
            onPressed: _isSaving || _isLoading ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Сохранить',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      hintText: 'Название канала',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Название не может быть пустым';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _headerController,
                    decoration: const InputDecoration(
                      labelText: 'Header',
                      hintText: 'Заголовок канала',
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Текст, который отображается в заголовке канала. Часто используется для ссылок и краткой информации.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _purposeController,
                    decoration: const InputDecoration(
                      labelText: 'Purpose',
                      hintText: 'Назначение канала',
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Описание назначения канала. Помогает другим пользователям понять, для чего предназначен канал.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
    );
  }
}
