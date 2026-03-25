import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/file_info.dart';
import '../../../domain/repositories/file_repository.dart';
import '../../widgets/file_icon.dart';
import '../chat/widgets/file_attachment_widget.dart';
import 'channel_files_cubit.dart';

class ChannelFilesScreen extends StatefulWidget {
  final String channelId;
  final String channelName;

  const ChannelFilesScreen({
    super.key,
    required this.channelId,
    this.channelName = '',
  });

  @override
  State<ChannelFilesScreen> createState() => _ChannelFilesScreenState();
}

class _ChannelFilesScreenState extends State<ChannelFilesScreen> {
  late final ChannelFilesCubit _cubit;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cubit = ChannelFilesCubit(
      fileRepository: sl<FileRepository>(),
      channelId: widget.channelId,
    );
    _cubit.loadFiles();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cubit.loadMore();
    }
  }

  @override
  void dispose() {
    _cubit.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.channelFiles),
        ),
        body: Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: BlocBuilder<ChannelFilesCubit, ChannelFilesState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.error != null && state.files.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(state.error!),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _cubit.loadFiles,
                            child: Text(context.l10n.retry),
                          ),
                        ],
                      ),
                    );
                  }

                  final filtered = state.filteredFiles;

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.folder_open_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.l10n.noFiles,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final item = filtered[index];
                      return _FileListItem(
                        fileInfo: item.file,
                        createAt: item.createAt,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return BlocBuilder<ChannelFilesCubit, ChannelFilesState>(
      buildWhen: (prev, curr) => prev.filter != curr.filter,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _FilterChip(
                label: context.l10n.allFiles,
                selected: state.filter == ChannelFilesFilter.all,
                onSelected: () => _cubit.setFilter(ChannelFilesFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: context.l10n.images,
                selected: state.filter == ChannelFilesFilter.images,
                onSelected: () => _cubit.setFilter(ChannelFilesFilter.images),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: context.l10n.documents,
                selected: state.filter == ChannelFilesFilter.documents,
                onSelected: () => _cubit.setFilter(ChannelFilesFilter.documents),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        fontSize: 13,
        color: selected ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: AppColors.accent,
      backgroundColor: AppColors.backgroundLight,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _FileListItem extends StatelessWidget {
  final FileInfo fileInfo;
  final int createAt;

  const _FileListItem({
    required this.fileInfo,
    required this.createAt,
  });

  @override
  Widget build(BuildContext context) {
    if (fileInfo.isImage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: FileAttachmentWidget(
          fileInfo: fileInfo,
          allMediaFiles: [fileInfo],
        ),
      );
    }

    final dateStr = DateFormatter.formatShortDate(createAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: FileIcon(extension_: fileInfo.extension_),
        title: Text(
          fileInfo.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body,
        ),
        subtitle: Text(
          '${fileInfo.sizeFormatted} · $dateStr',
          style: AppTextStyles.caption,
        ),
        // TODO: download/preview for non-image files
        onTap: () {},
      ),
    );
  }
}
