import 'package:flutter_test/flutter_test.dart';
import 'package:mgmess/data/models/file_info_model.dart';

void main() {
  group('FileInfoModel', () {
    const json = {
      'id': 'file123',
      'post_id': 'post1',
      'user_id': 'user1',
      'name': 'photo.jpg',
      'extension': 'jpg',
      'size': 1048576,
      'mime_type': 'image/jpeg',
      'width': 1920,
      'height': 1080,
      'has_preview_image': true,
    };

    test('fromJson creates correct model', () {
      final file = FileInfoModel.fromJson(json);
      expect(file.id, 'file123');
      expect(file.name, 'photo.jpg');
      expect(file.extension_, 'jpg');
      expect(file.size, 1048576);
      expect(file.mimeType, 'image/jpeg');
      expect(file.width, 1920);
      expect(file.height, 1080);
    });

    test('isImage returns true for image mimeType', () {
      final file = FileInfoModel.fromJson(json);
      expect(file.isImage, true);
    });

    test('isImage returns true for image extension', () {
      final file = FileInfoModel.fromJson({
        ...json,
        'mime_type': 'application/octet-stream',
        'extension': 'png',
      });
      expect(file.isImage, true);
    });

    test('isImage returns false for non-image', () {
      final file = FileInfoModel.fromJson({
        ...json,
        'mime_type': 'application/pdf',
        'extension': 'pdf',
      });
      expect(file.isImage, false);
    });

    test('isVideo returns true for video mimeType', () {
      final file = FileInfoModel.fromJson({
        ...json,
        'mime_type': 'video/mp4',
      });
      expect(file.isVideo, true);
    });

    test('sizeFormatted returns bytes', () {
      final file = FileInfoModel.fromJson({...json, 'size': 500});
      expect(file.sizeFormatted, '500 B');
    });

    test('sizeFormatted returns KB', () {
      final file = FileInfoModel.fromJson({...json, 'size': 2048});
      expect(file.sizeFormatted, '2.0 KB');
    });

    test('sizeFormatted returns MB', () {
      final file = FileInfoModel.fromJson(json);
      expect(file.sizeFormatted, '1.0 MB');
    });

    test('toJson returns correct map', () {
      final file = FileInfoModel.fromJson(json);
      final result = file.toJson();
      expect(result['id'], 'file123');
      expect(result['extension'], 'jpg');
      expect(result['mime_type'], 'image/jpeg');
    });
  });
}
