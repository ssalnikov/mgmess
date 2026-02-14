import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/di/injection.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';
import '../../core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final String userId;
  final double radius;
  final String? status;

  const UserAvatar({
    super.key,
    required this.userId,
    this.radius = 20,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    final url =
        '${AppConfig.baseUrl}${ApiEndpoints.userImage(userId)}';

    return Stack(
      children: [
        FutureBuilder<String?>(
          future: sl<SecureStorage>().getToken(),
          builder: (context, snapshot) {
            final token = snapshot.data;
            return CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.divider,
              child: ClipOval(
                child: token != null
                    ? CachedNetworkImage(
                        imageUrl: url,
                        httpHeaders: {'Authorization': 'Bearer $token'},
                        width: radius * 2,
                        height: radius * 2,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Icon(
                          Icons.person,
                          size: radius,
                          color: AppColors.textSecondary,
                        ),
                        errorWidget: (_, __, ___) => Icon(
                          Icons.person,
                          size: radius,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : Icon(
                        Icons.person,
                        size: radius,
                        color: AppColors.textSecondary,
                      ),
              ),
            );
          },
        ),
        if (status != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: radius * 0.6,
              height: radius * 0.6,
              decoration: BoxDecoration(
                color: _statusColor(status!),
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
