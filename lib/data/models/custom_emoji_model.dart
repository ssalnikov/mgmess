class CustomEmojiModel {
  final String id;
  final String name;
  final String creatorId;

  const CustomEmojiModel({
    required this.id,
    required this.name,
    required this.creatorId,
  });

  factory CustomEmojiModel.fromJson(Map<String, dynamic> json) {
    return CustomEmojiModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
    );
  }
}
