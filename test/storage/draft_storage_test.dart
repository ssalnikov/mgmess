import 'package:flutter_test/flutter_test.dart';
import 'package:mgmess/core/storage/draft_storage.dart';
import 'package:mgmess/domain/entities/draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DraftStorage storage;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = DraftStorage();
  });

  group('DraftStorage', () {
    test('saveDraft and getDraft round-trip', () async {
      final draft = Draft(
        channelId: 'ch1',
        channelName: 'general',
        message: 'hello',
        updatedAt: DateTime(2024, 6, 15),
      );
      await storage.saveDraft(draft);
      final result = await storage.getDraft('ch1');
      expect(result, isNotNull);
      expect(result!.channelId, 'ch1');
      expect(result.channelName, 'general');
      expect(result.message, 'hello');
    });

    test('getDraft returns null for unknown channel', () async {
      final result = await storage.getDraft('unknown');
      expect(result, isNull);
    });

    test('saveDraft with empty message deletes draft', () async {
      final draft = Draft(
        channelId: 'ch1',
        channelName: 'general',
        message: 'hello',
        updatedAt: DateTime(2024, 6, 15),
      );
      await storage.saveDraft(draft);
      expect(await storage.getDraft('ch1'), isNotNull);

      final emptyDraft = Draft(
        channelId: 'ch1',
        channelName: 'general',
        message: '',
        updatedAt: DateTime(2024, 6, 15),
      );
      await storage.saveDraft(emptyDraft);
      expect(await storage.getDraft('ch1'), isNull);
    });

    test('saveDraft with whitespace-only message deletes draft', () async {
      final draft = Draft(
        channelId: 'ch1',
        channelName: 'general',
        message: 'hello',
        updatedAt: DateTime(2024, 6, 15),
      );
      await storage.saveDraft(draft);

      final spaceDraft = Draft(
        channelId: 'ch1',
        channelName: 'general',
        message: '   ',
        updatedAt: DateTime(2024, 6, 15),
      );
      await storage.saveDraft(spaceDraft);
      expect(await storage.getDraft('ch1'), isNull);
    });

    test('getAllDrafts returns sorted by updatedAt desc', () async {
      final old = Draft(
        channelId: 'ch1',
        channelName: 'old',
        message: 'old msg',
        updatedAt: DateTime(2024, 1, 1),
      );
      final mid = Draft(
        channelId: 'ch2',
        channelName: 'mid',
        message: 'mid msg',
        updatedAt: DateTime(2024, 6, 1),
      );
      final recent = Draft(
        channelId: 'ch3',
        channelName: 'recent',
        message: 'recent msg',
        updatedAt: DateTime(2024, 12, 1),
      );

      await storage.saveDraft(old);
      await storage.saveDraft(recent);
      await storage.saveDraft(mid);

      final all = await storage.getAllDrafts();
      expect(all.length, 3);
      expect(all[0].channelId, 'ch3');
      expect(all[1].channelId, 'ch2');
      expect(all[2].channelId, 'ch1');
    });

    test('getAllDrafts returns empty list when no drafts', () async {
      final all = await storage.getAllDrafts();
      expect(all, isEmpty);
    });

    test('deleteDraft removes the draft', () async {
      final draft = Draft(
        channelId: 'ch1',
        channelName: 'general',
        message: 'hello',
        updatedAt: DateTime(2024, 6, 15),
      );
      await storage.saveDraft(draft);
      await storage.deleteDraft('ch1');
      expect(await storage.getDraft('ch1'), isNull);
    });

    test('getDraftCount returns correct count', () async {
      expect(await storage.getDraftCount(), 0);

      await storage.saveDraft(Draft(
        channelId: 'ch1',
        channelName: 'a',
        message: 'msg1',
        updatedAt: DateTime.now(),
      ));
      await storage.saveDraft(Draft(
        channelId: 'ch2',
        channelName: 'b',
        message: 'msg2',
        updatedAt: DateTime.now(),
      ));
      expect(await storage.getDraftCount(), 2);

      await storage.deleteDraft('ch1');
      expect(await storage.getDraftCount(), 1);
    });
  });
}
