import 'package:equatable/equatable.dart';

class UserSeen extends Equatable {
  final String odataType;
  final String odataId;
  final String firstName;
  final String lastName;
  final String userName;
  final int seenAt;

  const UserSeen({
    this.odataType = '',
    this.odataId = '',
    this.firstName = '',
    this.lastName = '',
    this.userName = '',
    this.seenAt = 0,
  });

  String get displayName {
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    return userName;
  }

  @override
  List<Object?> get props => [odataId, seenAt];
}

class SeenList extends Equatable {
  final String channelId;
  final String postId;
  final List<UserSeen> users;

  const SeenList({
    this.channelId = '',
    this.postId = '',
    this.users = const [],
  });

  @override
  List<Object?> get props => [channelId, postId, users];
}
