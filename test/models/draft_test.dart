import 'package:flutter_test/flutter_test.dart';
import 'package:mgmess/domain/entities/draft.dart';

void main() {
  group('Draft', () {
    final now = DateTime(2024, 6, 15, 12, 30);
    final draft = Draft(
      channelId: 'ch1',
      channelName: 'general',
      message: 'hello world',
      updatedAt: now,
    );

    test('toJson/fromJson round-trip', () {
      final json = draft.toJson();
      final restored = Draft.fromJson(json);
      expect(restored.channelId, draft.channelId);
      expect(restored.channelName, draft.channelName);
      expect(restored.message, draft.message);
      expect(restored.updatedAt, draft.updatedAt);
    });

    test('fromJson handles missing fields', () {
      final d = Draft.fromJson({});
      expect(d.channelId, '');
      expect(d.channelName, '');
      expect(d.message, '');
      expect(d.updatedAt, isA<DateTime>());
    });

    test('equatable compares all fields', () {
      final d1 = Draft(
        channelId: 'ch1',
        channelName: 'general',
        message: 'hello',
        updatedAt: now,
      );
      final d2 = Draft(
        channelId: 'ch1',
        channelName: 'general',
        message: 'hello',
        updatedAt: now,
      );
      expect(d1, equals(d2));
    });

    test('equatable detects different message', () {
      final d1 = Draft(
        channelId: 'ch1',
        channelName: 'general',
        message: 'hello',
        updatedAt: now,
      );
      final d2 = Draft(
        channelId: 'ch1',
        channelName: 'general',
        message: 'world',
        updatedAt: now,
      );
      expect(d1, isNot(equals(d2)));
    });

    test('toJson contains all fields', () {
      final json = draft.toJson();
      expect(json['channelId'], 'ch1');
      expect(json['channelName'], 'general');
      expect(json['message'], 'hello world');
      expect(json['updatedAt'], now.millisecondsSinceEpoch);
    });
  });
}
