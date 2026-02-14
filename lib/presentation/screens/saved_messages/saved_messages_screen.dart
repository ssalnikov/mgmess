import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/repositories/post_repository.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/user_avatar.dart';
import 'saved_messages_bloc.dart';

class SavedMessagesScreen extends StatefulWidget {
  const SavedMessagesScreen({super.key});

  @override
  State<SavedMessagesScreen> createState() => _SavedMessagesScreenState();
}

class _SavedMessagesScreenState extends State<SavedMessagesScreen> {
  late final SavedMessagesBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = SavedMessagesBloc(postRepository: sl<PostRepository>());
    _load();
  }

  void _load() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _bloc.add(LoadSavedMessages(userId: authState.user.id));
    }
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Saved Messages')),
        body: BlocBuilder<SavedMessagesBloc, SavedMessagesState>(
          builder: (context, state) {
            if (state.isLoading && state.posts.isEmpty) {
              return const LoadingIndicator();
            }
            if (state.error != null && state.posts.isEmpty) {
              return ErrorDisplay(
                message: state.error!,
                onRetry: _load,
              );
            }
            if (state.posts.isEmpty) {
              return const Center(
                child: Text('No saved messages'),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _load(),
              child: ListView.separated(
                itemCount: state.posts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return _SavedPostTile(post: state.posts[index]);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SavedPostTile extends StatelessWidget {
  final Post post;

  const _SavedPostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UserAvatar(userId: post.userId, radius: 20),
      title: MarkdownBody(
        data: post.message,
        styleSheet: MarkdownStyleSheet(
          p: AppTextStyles.body,
        ),
      ),
      subtitle: Text(
        DateFormatter.formatMessageTime(post.createAt),
        style: AppTextStyles.caption,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.bookmark_remove),
        onPressed: () {
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            context.read<SavedMessagesBloc>().add(
                  UnflagMessage(
                    userId: authState.user.id,
                    postId: post.id,
                  ),
                );
          }
        },
      ),
    );
  }
}
