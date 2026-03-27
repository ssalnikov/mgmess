import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/di/injection.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/theme/app_colors.dart';
import '../blocs/user_status/user_status_cubit.dart';

class UserAvatar extends StatefulWidget {
  final String userId;
  final double radius;
  final String? status;
  final int? cacheBuster;
  final String? heroTag;

  const UserAvatar({
    super.key,
    required this.userId,
    this.radius = 20,
    this.status,
    this.cacheBuster,
    this.heroTag,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _token;

  @override
  void initState() {
    super.initState();
    _token = currentSession.cachedAuthToken;
    if (_token == null) {
      currentSession.getAuthToken().then((t) {
        if (mounted && t != null) setState(() => _token = t);
      });
    }
  }

  String get _imageUrl {
    final base =
        '${currentSession.baseUrl}${ApiEndpoints.userImage(widget.userId)}';
    if (widget.cacheBuster != null) {
      return '$base?_=${widget.cacheBuster}';
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = widget.status ??
        context.select<UserStatusCubit, String?>((cubit) {
          final s = cubit.state.statuses[widget.userId];
          if (s == null) {
            cubit.requestStatus(widget.userId);
          }
          return s;
        });

    final showIndicator = effectiveStatus != null;

    final avatar = Stack(
      children: [
        CircleAvatar(
          radius: widget.radius,
          backgroundColor: AppColors.divider,
          child: ClipOval(
            child: _token != null
                ? CachedNetworkImage(
                    imageUrl: _imageUrl,
                    httpHeaders: {'Authorization': 'Bearer $_token'},
                    width: widget.radius * 2,
                    height: widget.radius * 2,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Icon(
                      Icons.person,
                      size: widget.radius,
                      color: AppColors.textSecondary,
                    ),
                    errorWidget: (_, _, _) => Icon(
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
        ),
        if (showIndicator)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: widget.radius * 0.6,
              height: widget.radius * 0.6,
              decoration: BoxDecoration(
                color: _statusColor(effectiveStatus),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag!, child: avatar);
    }
    return avatar;
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
