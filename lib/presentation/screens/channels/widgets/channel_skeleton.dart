import 'package:flutter/material.dart';

import '../../../widgets/skeleton_loader.dart';

class ChannelSkeleton extends StatelessWidget {
  const ChannelSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SkeletonBox(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(
                  width: 120 + (hashCode % 80).toDouble(),
                  height: 14,
                ),
                const SizedBox(height: 6),
                const SkeletonBox(width: 60, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChannelSkeletonList extends StatelessWidget {
  const ChannelSkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 10,
        itemBuilder: (context, index) {
          return const ChannelSkeleton();
        },
      ),
    );
  }
}
