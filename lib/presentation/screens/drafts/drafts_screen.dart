import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/route_names.dart';
import '../../../core/storage/draft_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/draft.dart';

class DraftsScreen extends StatefulWidget {
  const DraftsScreen({super.key});

  @override
  State<DraftsScreen> createState() => _DraftsScreenState();
}

class _DraftsScreenState extends State<DraftsScreen> {
  final _draftStorage = sl<DraftStorage>();
  List<Draft> _drafts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    setState(() => _isLoading = true);
    final drafts = await _draftStorage.getAllDrafts();
    if (mounted) {
      setState(() {
        _drafts = drafts;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteDraft(String channelId) async {
    await _draftStorage.deleteDraft(channelId);
    await _loadDrafts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drafts'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty
              ? const Center(child: Text('No drafts'))
              : ListView.separated(
                  itemCount: _drafts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final draft = _drafts[index];
                    return _DraftTile(
                      draft: draft,
                      onTap: () {
                        context.push(
                          RouteNames.chatPath(draft.channelId),
                          extra: <String, dynamic>{
                            'channelName': draft.channelName,
                            'draftMessage': draft.message,
                          },
                        );
                      },
                      onDelete: () => _deleteDraft(draft.channelId),
                    );
                  },
                ),
    );
  }
}

class _DraftTile extends StatelessWidget {
  final Draft draft;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DraftTile({
    required this.draft,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: const Icon(Icons.edit_note, color: AppColors.primary, size: 20),
      ),
      title: Text(
        draft.channelName.isNotEmpty ? draft.channelName : 'Unknown channel',
        style: AppTextStyles.channelName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        draft.message,
        style: AppTextStyles.caption,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormatter.formatChannelTime(
                draft.updatedAt.millisecondsSinceEpoch),
            style: AppTextStyles.caption,
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
