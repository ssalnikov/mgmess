import '../../domain/entities/file_info.dart';

class FileInfoModel extends FileInfo {
  const FileInfoModel({
    required super.id,
    super.postId,
    super.userId,
    super.name,
    super.extension_,
    super.size,
    super.mimeType,
    super.width,
    super.height,
    super.hasPreviewImage,
  });

  factory FileInfoModel.fromJson(Map<String, dynamic> json) {
    return FileInfoModel(
      id: json['id'] as String? ?? '',
      postId: json['post_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      extension_: json['extension'] as String? ?? '',
      size: json['size'] as int? ?? 0,
      mimeType: json['mime_type'] as String? ?? '',
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
      hasPreviewImage: json['has_preview_image'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'post_id': postId,
        'user_id': userId,
        'name': name,
        'extension': extension_,
        'size': size,
        'mime_type': mimeType,
        'width': width,
        'height': height,
        'has_preview_image': hasPreviewImage,
      };
}
