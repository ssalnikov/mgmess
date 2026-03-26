import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/url_utils.dart';
import '../../domain/entities/server_account.dart';
import '../blocs/server/server_list_cubit.dart';

class ServerDrawer extends StatelessWidget {
  final VoidCallback? onAddServer;

  const ServerDrawer({super.key, this.onAddServer});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: BlocBuilder<ServerListCubit, ServerListState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    context.l10n.servers,
                    style: AppTextStyles.heading2,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.accounts.length,
                    itemBuilder: (context, index) {
                      final account = state.accounts[index];
                      final isActive =
                          account.id == state.activeAccountId;
                      return _ServerTile(
                        account: account,
                        isActive: isActive,
                        onTap: () {
                          if (!isActive) {
                            HapticFeedback.selectionClick();
                            context
                                .read<ServerListCubit>()
                                .switchServer(account.id);
                            Navigator.of(context).pop();
                          }
                        },
                        onLongPress: () =>
                            _showRemoveDialog(context, account, state),
                      );
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                  title: Text(context.l10n.addServer),
                  onTap: () {
                    Navigator.of(context).pop();
                    onAddServer?.call();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showRemoveDialog(
    BuildContext context,
    ServerAccount account,
    ServerListState state,
  ) {
    if (state.accounts.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cannotRemoveLastServer)),
      );
      return;
    }
    HapticFeedback.selectionClick();
    final serverName = account.displayName.isNotEmpty
        ? account.displayName
        : _extractHost(account.serverUrl);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.removeServer),
        content: Text(context.l10n.removeServerConfirm(serverName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<ServerListCubit>().removeServer(account.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.serverRemoved)),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(context.l10n.remove),
          ),
        ],
      ),
    );
  }

  static String _extractHost(String url) => UrlUtils.extractHost(url);
}

class _ServerTile extends StatelessWidget {
  final ServerAccount account;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ServerTile({
    required this.account,
    required this.isActive,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final host = _extractHost(account.serverUrl);
    final displayName = account.displayName.isNotEmpty
        ? account.displayName
        : host;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isActive ? AppColors.accent : AppColors.primary.withValues(alpha: 0.1),
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        displayName,
        style: AppTextStyles.body.copyWith(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        host,
        style: AppTextStyles.caption,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isActive
          ? const Icon(Icons.check_circle, color: AppColors.accent, size: 20)
          : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  static String _extractHost(String url) => UrlUtils.extractHost(url);
}
