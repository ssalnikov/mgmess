import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _searchBloc,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search messages...',
              border: InputBorder.none,
            ),
            onChanged: (query) {
              _searchBloc.add(SearchQueryChanged(
                query: query,
                teamId: _teamId,
              ));
            },
          ),
          actions: [
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
            if (state.query.isEmpty) {
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
                      'Search messages',
                      style: AppTextStyles.caption.copyWith(fontSize: 16),
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
              return const Center(
                child: Text(
                  'No results found',
                ),
              );
            }
            return ListView.builder(
              itemCount: state.results.length,
              itemBuilder: (context, index) {
                final post = state.results[index];
                return _SearchResultTile(post: post);
              },
            );
          },
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final dynamic post;

  const _SearchResultTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(userId: post.userId, radius: 20),
      title: Text(
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
        context.push(RouteNames.chatPath(post.channelId));
      },
    );
  }
}
