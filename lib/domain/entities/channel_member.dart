import 'package:equatable/equatable.dart';

import 'user.dart';

class ChannelMember extends Equatable {
  final User user;
  final String roles;

  const ChannelMember({
    required this.user,
    this.roles = '',
  });

  bool get isChannelAdmin => roles.contains('channel_admin');

  @override
  List<Object?> get props => [user.id, roles];
}
