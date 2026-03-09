import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class EmojiAutocompleteItem {
  final String name;
  final String? unicode;
  final String? imageUrl;

  const EmojiAutocompleteItem({
    required this.name,
    this.unicode,
    this.imageUrl,
  });
}

class EmojiAutocomplete extends StatelessWidget {
  final List<EmojiAutocompleteItem> items;
  final void Function(EmojiAutocompleteItem item) onSelect;
  final Map<String, String>? authHeaders;

  const EmojiAutocomplete({
    super.key,
    required this.items,
    required this.onSelect,
    this.authHeaders,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: AppColors.divider),
          itemBuilder: (context, index) {
            final item = items[index];
            return InkWell(
              onTap: () => onSelect(item),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Center(
                        child: item.imageUrl != null
                            ? Image.network(
                                item.imageUrl!,
                                width: 24,
                                height: 24,
                                headers: authHeaders,
                                errorBuilder: (_, _, _) => const Text('?'),
                              )
                            : Text(
                                item.unicode ?? '?',
                                style: const TextStyle(fontSize: 24),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ':${item.name}:',
                        style: AppTextStyles.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
