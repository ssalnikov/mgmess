import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/repositories/post_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/user_avatar.dart';
import 'search_bloc.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final SearchBloc _searchBloc;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchBloc = SearchBloc(postRepository: sl<PostRepository>());
  }

  String get _teamId {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.teamId;
    return '';
  }

  @override
  void dispose() {
    _searchBloc.close();
    _controller.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: _searchBloc,
        child: _FilterSheet(
          teamId: _teamId,
          onApply: () => _searchBloc.add(SearchSubmitted(teamId: _teamId)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _searchBloc,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: context.l10n.searchMessages,
              border: InputBorder.none,
            ),
            onChanged: (query) {
              _searchBloc.add(SearchQueryChanged(
                query: query,
                teamId: _teamId,
              ));
            },
            onSubmitted: (_) =>
                _searchBloc.add(SearchSubmitted(teamId: _teamId)),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: context.l10n.filters,
              onPressed: _showFilterSheet,
            ),
            if (_controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  _searchBloc.add(const SearchCleared());
                  setState(() {});
                },
              ),
          ],
        ),
        body: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            return Column(
              children: [
                // Active filter chips
                if (state.hasActiveFilters)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: state.activeFilterChips.map((entry) {
                        return Chip(
                          label: Text(entry.value,
                              style: const TextStyle(fontSize: 12)),
                          onDeleted: () => _searchBloc
                              .add(SearchFilterRemoved(entry.key)),
                          deleteIconColor: AppColors.textSecondary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ),
                Expanded(child: _buildBody(state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(SearchState state) {
    if (state.query.isEmpty && !state.hasActiveFilters) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.searchMessagesHint,
              style: AppTextStyles.caption.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.useFiltersHint,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      );
    }
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(child: Text(state.error!));
    }
    if (state.results.isEmpty) {
      return Center(child: Text(context.l10n.noResultsFound));
    }
    return ListView.builder(
      itemCount: state.results.length,
      itemBuilder: (context, index) {
        final post = state.results[index];
        return _SearchResultTile(
          post: post,
          highlightQuery: state.query,
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final dynamic post;
  final String highlightQuery;

  const _SearchResultTile({required this.post, this.highlightQuery = ''});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(userId: post.userId, radius: 20),
      title: highlightQuery.isNotEmpty
          ? _HighlightedText(
              text: post.message,
              highlight: highlightQuery,
              maxLines: 2,
            )
          : Text(
              post.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.channelName,
            ),
      subtitle: Text(
        DateFormatter.formatChannelTime(post.createAt),
        style: AppTextStyles.caption,
      ),
      onTap: () {
        context.push(
          RouteNames.chatPath(post.channelId),
          extra: <String, dynamic>{
            'scrollToPostId': post.id,
          },
        );
      },
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String highlight;
  final int maxLines;

  const _HighlightedText({
    required this.text,
    required this.highlight,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty) {
      return Text(text, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }

    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerHighlight, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + highlight.length),
        style: TextStyle(
          backgroundColor: AppColors.accent.withValues(alpha: 0.3),
          fontWeight: FontWeight.w600,
        ),
      ));
      start = idx + highlight.length;
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: AppTextStyles.channelName,
        children: spans,
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String teamId;
  final VoidCallback onApply;

  const _FilterSheet({required this.teamId, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  final _fromController = TextEditingController();
  final _inChannelController = TextEditingController();
  bool _hasFile = false;
  bool _hasImage = false;
  bool _hasLink = false;
  String? _beforeDate;
  String? _afterDate;
  String? _onDate;

  @override
  void initState() {
    super.initState();
    final state = context.read<SearchBloc>().state;
    _fromController.text = state.fromUser ?? '';
    _inChannelController.text = state.inChannel ?? '';
    _hasFile = state.hasFile;
    _hasImage = state.hasImage;
    _hasLink = state.hasLink;
    _beforeDate = state.beforeDate;
    _afterDate = state.afterDate;
    _onDate = state.onDate;
  }

  @override
  void dispose() {
    _fromController.dispose();
    _inChannelController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(String label, String? current, ValueChanged<String?> onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current != null ? DateTime.tryParse(current) ?? now : now,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      onPicked(formatted);
    }
  }

  void _apply() {
    final bloc = context.read<SearchBloc>();
    bloc.add(SearchFilterChanged(
      fromUser: _fromController.text.isNotEmpty ? _fromController.text : null,
      inChannel:
          _inChannelController.text.isNotEmpty ? _inChannelController.text : null,
      beforeDate: _beforeDate,
      afterDate: _afterDate,
      onDate: _onDate,
      hasFile: _hasFile,
      hasImage: _hasImage,
      hasLink: _hasLink,
    ));
    Navigator.pop(context);
    widget.onApply();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
              Text(context.l10n.searchFilters,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextField(
                controller: _fromController,
                decoration: InputDecoration(
                  labelText: context.l10n.fromUser,
                  hintText: 'username',
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _inChannelController,
                decoration: InputDecoration(
                  labelText: context.l10n.inChannel,
                  hintText: 'channel-name',
                  prefixIcon: const Icon(Icons.tag),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilterChip(
                    label: Text(context.l10n.files),
                    selected: _hasFile,
                    onSelected: (v) => setState(() => _hasFile = v),
                  ),
                  FilterChip(
                    label: Text(context.l10n.images),
                    selected: _hasImage,
                    onSelected: (v) => setState(() => _hasImage = v),
                  ),
                  FilterChip(
                    label: Text(context.l10n.links),
                    selected: _hasLink,
                    onSelected: (v) => setState(() => _hasLink = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Date filters
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_afterDate ?? context.l10n.after),
                      onPressed: () => _pickDate(
                        'After',
                        _afterDate,
                        (v) => setState(() => _afterDate = v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(_beforeDate ?? context.l10n.before),
                      onPressed: () => _pickDate(
                        'Before',
                        _beforeDate,
                        (v) => setState(() => _beforeDate = v),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.today, size: 16),
                label: Text(_onDate ?? context.l10n.onDate),
                onPressed: () => _pickDate(
                  'On',
                  _onDate,
                  (v) => setState(() => _onDate = v),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  child: Text(context.l10n.applyFilters),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
