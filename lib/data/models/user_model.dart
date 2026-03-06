import 'dart:convert';

import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    super.email,
    super.firstName,
    super.lastName,
    super.nickname,
    super.position,
    super.locale,
    super.createAt,
    super.updateAt,
    super.deleteAt,
    super.status,
    super.customStatusEmoji,
    super.customStatusText,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String customEmoji = '';
    String customText = '';

    final props = json['props'] as Map<String, dynamic>? ?? {};
    final rawCustomStatus = props['customStatus'];
    if (rawCustomStatus != null) {
      Map<String, dynamic>? csMap;
      if (rawCustomStatus is Map<String, dynamic>) {
        csMap = rawCustomStatus;
      } else if (rawCustomStatus is String && rawCustomStatus.isNotEmpty) {
        try {
          csMap = jsonDecode(rawCustomStatus) as Map<String, dynamic>?;
        } catch (_) {}
      }
      if (csMap != null) {
        customEmoji = csMap['emoji'] as String? ?? '';
        customText = csMap['text'] as String? ?? '';
      }
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      position: json['position'] as String? ?? '',
      locale: json['locale'] as String? ?? 'en',
      createAt: json['create_at'] as int? ?? 0,
      updateAt: json['update_at'] as int? ?? 0,
      deleteAt: json['delete_at'] as int? ?? 0,
      customStatusEmoji: customEmoji,
      customStatusText: customText,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'nickname': nickname,
        'position': position,
        'locale': locale,
      };
}
