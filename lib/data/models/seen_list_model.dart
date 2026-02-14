import '../../domain/entities/seen_list.dart';

class UserSeenModel extends UserSeen {
  const UserSeenModel({
    super.odataType,
    super.odataId,
    super.firstName,
    super.lastName,
    super.userName,
    super.seenAt,
  });

  factory UserSeenModel.fromJson(Map<String, dynamic> json) {
    return UserSeenModel(
      odataType: json['@odata.type'] as String? ?? '',
      odataId: json['@odata.id'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      userName: json['user_name'] as String? ?? '',
      seenAt: json['seen_at'] as int? ?? 0,
    );
  }
}

class SeenListModel extends SeenList {
  const SeenListModel({
    super.channelId,
    super.postId,
    super.users,
  });

  factory SeenListModel.fromJson(
    Map<String, dynamic> json, {
    String channelId = '',
    String postId = '',
  }) {
    final usersList = json['users'] as List<dynamic>? ?? [];
    return SeenListModel(
      channelId: channelId,
      postId: postId,
      users: usersList
          .map((u) => UserSeenModel.fromJson(u as Map<String, dynamic>))
          .toList(),
    );
  }
}
