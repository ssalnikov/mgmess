import 'package:flutter/material.dart';

import '../../../widgets/skeleton_loader.dart';

class MessageSkeleton extends StatelessWidget {
  final bool isOwn;

  const MessageSkeleton({super.key, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isOwn ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwn) ...[
            const SkeletonBox(width: 32, height: 32, borderRadius: 16),
            const SizedBox(width: 8),
          ],
          SkeletonBox(
            width: isOwn ? 180 : 200,
            height: isOwn ? 40 : 52,
            borderRadius: 16,
          ),
          if (isOwn) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class MessageSkeletonList extends StatelessWidget {
  const MessageSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        itemBuilder: (context, index) {
          return MessageSkeleton(isOwn: index % 3 == 0);
        },
      ),
    );
  }
}
