import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mgmess/domain/entities/channel.dart';
import 'package:mgmess/domain/entities/channel_category.dart';
import 'package:mgmess/presentation/screens/channels/widgets/category_header.dart';

import '../fixtures/ws_event_factory.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';

/// Генерирует N прочитанных каналов с убывающим lastPostAt.
List<Channel> _generateChannels(int count, {int startAt = 1700000000000}) {
  return List.generate(
    count,
    (i) => Channel(
      id: 'ch-$i',
      teamId: 'team-001',
      name: 'channel-$i',
      displayName: 'Channel $i',
      type: ChannelType.open,
      totalMsgCount: 100,
      msgCount: 100,
      lastPostAt: startAt - (i * 1000),
    ),
  );
}

const _unreadChannel = Channel(
  id: 'ch-unread',
  teamId: 'team-001',
  name: 'bugs',
  displayName: 'Bugs',
  type: ChannelType.open,
  totalMsgCount: 20,
  msgCount: 15,
  mentionCount: 2,
  lastPostAt: 1700000010000,
);

void main() {
  group('Channel Grouping', () {
    testWidgets('каналы группируются с заголовком UNREADS & RECENTS',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);

      const readChannel = Channel(
        id: 'ch-read',
        teamId: 'team-001',
        name: 'general',
        displayName: 'General',
        type: ChannelType.open,
        totalMsgCount: 100,
        msgCount: 100,
        lastPostAt: 1700000009000,
      );

      when(() =>
              result.mocks.channelRepository.getChannelsForUser(any(), any()))
          .thenAnswer((_) async => const Right([_unreadChannel, readChannel]));
      when(() =>
              result.mocks.channelRepository.getChannelCategories(any(), any()))
          .thenAnswer((_) async => const Right([
                ChannelCategory(
                  id: 'cat-channels',
                  type: ChannelCategoryType.channels,
                  channelIds: ['ch-unread', 'ch-read'],
                ),
              ]));
      when(() => result.mocks.channelRepository.viewChannel(any(), any()))
          .thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();
      await tester.waitForText('Bugs');

      expect(find.text('Bugs'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('UNREADS & RECENTS'), findsOneWidget);
    });

    testWidgets('непрочитанный канал попадает в секцию UNREADS',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);

      when(() =>
              result.mocks.channelRepository.getChannelsForUser(any(), any()))
          .thenAnswer((_) async => const Right([_unreadChannel]));
      when(() =>
              result.mocks.channelRepository.getChannelCategories(any(), any()))
          .thenAnswer((_) async => const Right([
                ChannelCategory(
                  id: 'cat-channels',
                  type: ChannelCategoryType.channels,
                  channelIds: ['ch-unread'],
                ),
              ]));
      when(() => result.mocks.channelRepository.viewChannel(any(), any()))
          .thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();
      await tester.waitForText('Bugs');

      expect(find.text('UNREADS & RECENTS'), findsOneWidget);
      expect(find.text('Bugs'), findsOneWidget);
    });

    testWidgets(
        'overflow-каналы появляются в категориях при скролле, collapse работает',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);

      // 62 канала: 60 → recents, 2 → overflow в FAVORITES
      final allChannels = _generateChannels(62);
      final favChannelIds = ['ch-60', 'ch-61'];

      when(() =>
              result.mocks.channelRepository.getChannelsForUser(any(), any()))
          .thenAnswer((_) async => Right(allChannels));
      when(() =>
              result.mocks.channelRepository.getChannelCategories(any(), any()))
          .thenAnswer((_) async => Right([
                ChannelCategory(
                  id: 'cat-favorites',
                  type: ChannelCategoryType.favorites,
                  channelIds: favChannelIds,
                  collapsed: false,
                  sortOrder: 0,
                ),
                ChannelCategory(
                  id: 'cat-channels',
                  type: ChannelCategoryType.channels,
                  channelIds: allChannels.map((c) => c.id).toList(),
                  sortOrder: 1,
                ),
              ]));
      when(() => result.mocks.channelRepository.viewChannel(any(), any()))
          .thenAnswer((_) async => const Right(null));
      when(() => result.mocks.channelRepository
              .updateChannelCategory(any(), any(), any(), any()))
          .thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();
      await tester.waitForText('Channel 0');

      // Скроллим вниз до FAVORITES
      await tester.dragUntilVisible(
        find.text('FAVORITES'),
        find.byType(CustomScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      expect(find.text('FAVORITES'), findsOneWidget);

      // Тапаем на FAVORITES для сворачивания
      final favHeader = find.widgetWithText(CategoryHeader, 'FAVORITES');
      await tester.tap(favHeader);
      await tester.pumpAndSettle();

      verify(() => result.mocks.channelRepository.updateChannelCategory(
          any(), any(), 'cat-favorites', any())).called(1);
    });

    testWidgets('WS sidebar_category_updated перезагружает каналы',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);

      const readChannel = Channel(
        id: 'ch-read',
        teamId: 'team-001',
        name: 'general',
        displayName: 'General',
        type: ChannelType.open,
        totalMsgCount: 100,
        msgCount: 100,
        lastPostAt: 1700000009000,
      );

      when(() =>
              result.mocks.channelRepository.getChannelsForUser(any(), any()))
          .thenAnswer((_) async => const Right([readChannel]));
      when(() =>
              result.mocks.channelRepository.getChannelCategories(any(), any()))
          .thenAnswer((_) async => const Right([
                ChannelCategory(
                  id: 'cat-channels',
                  type: ChannelCategoryType.channels,
                  channelIds: ['ch-read'],
                ),
              ]));
      when(() => result.mocks.channelRepository.viewChannel(any(), any()))
          .thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();
      await tester.waitForText('General');

      verify(() => result.mocks.channelRepository
          .getChannelsForUser(any(), any())).called(1);

      // WS sidebar_category_updated → перезагрузка каналов
      result.mocks.webSocketClient.simulateEvent(
        createSidebarCategoryUpdatedEvent(),
      );
      await tester.pumpN(20);

      verify(() => result.mocks.channelRepository
          .getChannelsForUser(any(), any())).called(1);
    });

    testWidgets('fallback DIRECT MESSAGES при overflow без категорий',
        (tester) async {
      final result = await createTestApp();
      setupAuthenticatedState(result.mocks);

      // 61 public + 1 старый DM (не попадёт в recents limit=60)
      final publicChannels = _generateChannels(61);
      const dmChannel = Channel(
        id: 'dm-old',
        teamId: 'team-001',
        name: 'user-001__user-002',
        displayName: 'Other User',
        type: ChannelType.direct,
        totalMsgCount: 10,
        msgCount: 10,
        lastPostAt: 1699999000000,
      );
      final allChannels = [...publicChannels, dmChannel];

      when(() =>
              result.mocks.channelRepository.getChannelsForUser(any(), any()))
          .thenAnswer((_) async => Right(allChannels));
      when(() =>
              result.mocks.channelRepository.getChannelCategories(any(), any()))
          .thenAnswer((_) async => const Right(<ChannelCategory>[]));
      when(() => result.mocks.channelRepository.viewChannel(any(), any()))
          .thenAnswer((_) async => const Right(null));

      await tester.pumpWidget(result.app);
      await tester.pumpAndSettle();
      await tester.waitForText('Channel 0');

      // Скроллим вниз до DIRECT MESSAGES (fallback категория)
      await tester.dragUntilVisible(
        find.text('DIRECT MESSAGES'),
        find.byType(CustomScrollView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      expect(find.text('DIRECT MESSAGES'), findsOneWidget);
      expect(find.text('Other User'), findsOneWidget);
    });
  });
}
