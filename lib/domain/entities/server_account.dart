import 'package:equatable/equatable.dart';

class ServerAccount extends Equatable {
  final String id;
  final String serverUrl;
  final String displayName;
  final String userId;
  final String username;
  final DateTime addedAt;
  final DateTime lastActiveAt;

  const ServerAccount({
    required this.id,
    required this.serverUrl,
    this.displayName = '',
    this.userId = '',
    this.username = '',
    required this.addedAt,
    required this.lastActiveAt,
  });

  ServerAccount copyWith({
    String? displayName,
    String? userId,
    String? username,
    DateTime? lastActiveAt,
  }) {
    return ServerAccount(
      id: id,
      serverUrl: serverUrl,
      displayName: displayName ?? this.displayName,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      addedAt: addedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'serverUrl': serverUrl,
        'displayName': displayName,
        'userId': userId,
        'username': username,
        'addedAt': addedAt.toIso8601String(),
        'lastActiveAt': lastActiveAt.toIso8601String(),
      };

  factory ServerAccount.fromJson(Map<String, dynamic> json) => ServerAccount(
        id: json['id'] as String,
        serverUrl: json['serverUrl'] as String,
        displayName: json['displayName'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        username: json['username'] as String? ?? '',
        addedAt: DateTime.parse(json['addedAt'] as String),
        lastActiveAt: DateTime.parse(json['lastActiveAt'] as String),
      );

  @override
  List<Object?> get props => [id];
}
