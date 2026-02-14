import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/di/injection.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';

class UserAvatar extends StatefulWidget {
  final String userId;
  final double radius;
  final String? status;
  final int? cacheBuster;

  const UserAvatar({
    super.key,
    required this.userId,
    this.radius = 20,
    this.status,
    this.cacheBuster,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  late Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = sl<SecureStorage>().getToken();
  }

  String get _imageUrl {
    final base =
        '${AppConfig.baseUrl}${ApiEndpoints.userImage(widget.userId)}';
    if (widget.cacheBuster != null) {
      return '$base?_=${widget.cacheBuster}';
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FutureBuilder<String?>(
          future: _tokenFuture,
          builder: (context, snapshot) {
            final token = snapshot.data;
            return CircleAvatar(
              radius: widget.radius,
              backgroundColor: AppColors.divider,
              child: ClipOval(
                child: token != null
                    ? CachedNetworkImage(
                        imageUrl: _imageUrl,
                        httpHeaders: {'Authorization': 'Bearer $token'},
                        width: widget.radius * 2,
                        height: widget.radius * 2,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Icon(
                          Icons.person,
                          size: widget.radius,
                          color: AppColors.textSecondary,
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.person,
                          size: widget.radius,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: widget.radius,
                        color: AppColors.textSecondary,
                      ),
              ),
            );
          },
        ),
        if (widget.status != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: widget.radius * 0.6,
              height: widget.radius * 0.6,
              decoration: BoxDecoration(
                color: _statusColor(widget.status!),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'online':
        return AppColors.online;
      case 'away':
        return AppColors.away;
      case 'dnd':
        return AppColors.dnd;
      default:
        return AppColors.offline;
    }
  }
}
