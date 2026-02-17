import 'package:equatable/equatable.dart';

class Draft extends Equatable {
  final String channelId;
  final String channelName;
  final String message;
  final DateTime updatedAt;

  const Draft({
    required this.channelId,
    required this.channelName,
    required this.message,
    required this.updatedAt,
  });

  factory Draft.fromJson(Map<String, dynamic> json) {
    return Draft(
      channelId: json['channelId'] as String? ?? '',
      channelName: json['channelName'] as String? ?? '',
      message: json['message'] as String? ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'channelName': channelName,
      'message': message,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props => [channelId, channelName, message, updatedAt];
}
