import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../domain/entities/post.dart';
import '../../../../domain/repositories/post_repository.dart';
import '../../../widgets/user_avatar.dart';
import 'pinned_messages_bloc.dart';

class PinnedMessagesSheet extends StatefulWidget {
  final String channelId;
  final void Function(Post post)? onPostTap;

  const PinnedMessagesSheet({
    super.key,
    required this.channelId,
    this.onPostTap,
  });

  @override
  State<PinnedMessagesSheet> createState() => _PinnedMessagesSheetState();
}

class _PinnedMessagesSheetState extends State<PinnedMessagesSheet> {
  late final PinnedMessagesBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = PinnedMessagesBloc(
      postRepository: sl<PostRepository>(),
    );
    _bloc.add(LoadPinnedMessages(channelId: widget.channelId));
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
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Pinned messages',
                  style: AppTextStyles.heading2,
                ),
              ),
              Expanded(
                child: BlocBuilder<PinnedMessagesBloc, PinnedMessagesState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.error != null) {
                      return Center(
                        child: Text(
                          state.error!,
                          style: AppTextStyles.bodySmall,
                        ),
                      );
                    }
                    if (state.posts.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.push_pin_outlined,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No pinned messages',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }

                    final grouped = state.groupedByDate;
                    final dateKeys = grouped.keys.toList();

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: dateKeys.length,
                      itemBuilder: (context, dateIndex) {
                        final dateKey = dateKeys[dateIndex];
                        final posts = grouped[dateKey]!;
                        final dateMs = posts.first.createAt;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Text(
                                DateFormatter.formatDateSeparator(dateMs),
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...posts.map((post) => ListTile(
                                  onTap: () => widget.onPostTap?.call(post),
                                  leading:
                                      UserAvatar(userId: post.userId, radius: 18),
                                  title: MarkdownBody(
                                    data: post.message,
                                    styleSheet: MarkdownStyleSheet(
                                      p: AppTextStyles.body,
                                    ),
                                  ),
                                  subtitle: Text(
                                    DateFormatter.formatMessageTime(
                                        post.createAt),
                                    style: AppTextStyles.timestamp,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.push_pin,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                    tooltip: 'Unpin',
                                    onPressed: () {
                                      _bloc.add(
                                          UnpinMessage(postId: post.id));
                                    },
                                  ),
                                )),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
