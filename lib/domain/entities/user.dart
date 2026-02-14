import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String nickname;
  final String position;
  final String locale;
  final int createAt;
  final int updateAt;
  final int deleteAt;
  final String status;

  const User({
    required this.id,
    required this.username,
    this.email = '',
    this.firstName = '',
    this.lastName = '',
    this.nickname = '',
    this.position = '',
    this.locale = 'en',
    this.createAt = 0,
    this.updateAt = 0,
    this.deleteAt = 0,
    this.status = 'offline',
  });

  String get displayName {
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    if (nickname.isNotEmpty) return nickname;
    return username;
  }

  bool get isDeleted => deleteAt > 0;

  @override
  List<Object?> get props => [id];
}
