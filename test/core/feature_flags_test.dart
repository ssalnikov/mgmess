import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mgmess/core/feature_flags/feature_flags.dart';

void main() {
  group('FeatureFlag enum', () {
    test('each flag has a default value', () {
      for (final flag in FeatureFlag.values) {
        expect(flag.defaultValue, isA<bool>());
      }
    });

    test('linkPreview defaults to true', () {
      expect(FeatureFlag.linkPreview.defaultValue, isTrue);
    });

    test('voiceMessages defaults to false', () {
      expect(FeatureFlag.voiceMessages.defaultValue, isFalse);
    });
  });

  group('FeatureFlagService', () {
    late FeatureFlagService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = FeatureFlagService();
      await service.init();
    });

    test('returns default value when no override', () {
      expect(service.isEnabled(FeatureFlag.linkPreview), isTrue);
      expect(service.isEnabled(FeatureFlag.voiceMessages), isFalse);
    });

    test('operator [] works like isEnabled', () {
      expect(service[FeatureFlag.linkPreview], isTrue);
      expect(service[FeatureFlag.voiceMessages], isFalse);
    });

    test('local override takes effect', () async {
      expect(service.isEnabled(FeatureFlag.voiceMessages), isFalse);

      await service.setOverride(FeatureFlag.voiceMessages, true);

      expect(service.isEnabled(FeatureFlag.voiceMessages), isTrue);
    });

    test('clearOverride falls back to default', () async {
      await service.setOverride(FeatureFlag.linkPreview, false);
      expect(service.isEnabled(FeatureFlag.linkPreview), isFalse);

      await service.clearOverride(FeatureFlag.linkPreview);
      expect(service.isEnabled(FeatureFlag.linkPreview), isTrue);
    });

    test('remote config is applied', () async {
      await service.applyRemoteConfig({
        'voiceMessages': true,
        'aiSummarization': true,
      });

      expect(service.isEnabled(FeatureFlag.voiceMessages), isTrue);
      expect(service.isEnabled(FeatureFlag.aiSummarization), isTrue);
    });

    test('local override beats remote config', () async {
      await service.setOverride(FeatureFlag.voiceMessages, false);
      await service.applyRemoteConfig({'voiceMessages': true});

      expect(service.isEnabled(FeatureFlag.voiceMessages), isFalse);
    });

    test('clearOverride falls back to remote config', () async {
      await service.applyRemoteConfig({'voiceMessages': true});
      await service.setOverride(FeatureFlag.voiceMessages, false);
      expect(service.isEnabled(FeatureFlag.voiceMessages), isFalse);

      await service.clearOverride(FeatureFlag.voiceMessages);
      expect(service.isEnabled(FeatureFlag.voiceMessages), isTrue);
    });

    test('getAllFlags returns all flags with current values', () {
      final flags = service.getAllFlags();

      expect(flags.length, FeatureFlag.values.length);
      for (final flag in FeatureFlag.values) {
        expect(flags.containsKey(flag.name), isTrue);
      }
    });

    test('hasOverride returns true only when set', () async {
      expect(await service.hasOverride(FeatureFlag.voiceMessages), isFalse);

      await service.setOverride(FeatureFlag.voiceMessages, true);
      expect(await service.hasOverride(FeatureFlag.voiceMessages), isTrue);

      await service.clearOverride(FeatureFlag.voiceMessages);
      expect(await service.hasOverride(FeatureFlag.voiceMessages), isFalse);
    });

    test('resetAll clears everything', () async {
      await service.setOverride(FeatureFlag.voiceMessages, true);
      await service.applyRemoteConfig({'linkPreview': false});

      await service.resetAll();

      // Should fall back to defaults
      expect(
        service.isEnabled(FeatureFlag.voiceMessages),
        FeatureFlag.voiceMessages.defaultValue,
      );
      expect(
        service.isEnabled(FeatureFlag.linkPreview),
        FeatureFlag.linkPreview.defaultValue,
      );
    });

    test('persists across reloads', () async {
      await service.setOverride(FeatureFlag.voiceMessages, true);

      // Create a new service instance
      final service2 = FeatureFlagService();
      await service2.init();

      expect(service2.isEnabled(FeatureFlag.voiceMessages), isTrue);
    });
  });
}
