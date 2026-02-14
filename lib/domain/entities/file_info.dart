import 'package:equatable/equatable.dart';

class FileInfo extends Equatable {
  final String id;
  final String postId;
  final String userId;
  final String name;
  final String extension_;
  final int size;
  final String mimeType;
  final int width;
  final int height;
  final bool hasPreviewImage;

  const FileInfo({
    required this.id,
    this.postId = '',
    this.userId = '',
    this.name = '',
    this.extension_ = '',
    this.size = 0,
    this.mimeType = '',
    this.width = 0,
    this.height = 0,
    this.hasPreviewImage = false,
  });

  bool get isImage =>
      mimeType.startsWith('image/') ||
      ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp']
          .contains(extension_.toLowerCase());

  bool get isVideo => mimeType.startsWith('video/');

  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  List<Object?> get props => [id];
}
