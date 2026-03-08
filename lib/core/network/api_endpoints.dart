class ApiEndpoints {
  // Auth
  static const String usersMe = '/users/me';
  static const String usersLogin = '/users/login';
  static const String usersLogout = '/users/logout';

  // Users
  static String user(String id) => '/users/$id';
  static String userImage(String id) => '/users/$id/image';
  static String usersByIds = '/users/ids';
  static String userPatch(String id) => '/users/$id/patch';

  // Teams
  static const String teams = '/users/me/teams';
  static String teamMembers(String teamId) => '/teams/$teamId/members';

  // Channels
  static String channelsForUser(String userId, String teamId) =>
      '/users/$userId/teams/$teamId/channels';
  static String channel(String id) => '/channels/$id';
  static String channelMembers(String id) => '/channels/$id/members';
  static String channelMember(String channelId, String userId) =>
      '/channels/$channelId/members/$userId';
  static String channelMembersForUser(String userId, String teamId) =>
      '/users/$userId/teams/$teamId/channels/members';
  static String channelViewForUser(String userId) =>
      '/channels/members/$userId/view';
  static String directChannel = '/channels/direct';
  static String channelMemberNotifyProps(String channelId, String userId) =>
      '/channels/$channelId/members/$userId/notify_props';
  static String channelMemberSchemeRoles(String channelId, String userId) =>
      '/channels/$channelId/members/$userId/schemeRoles';
  static String channelPatch(String id) => '/channels/$id/patch';
  static String channelStats(String id) => '/channels/$id/stats';
  static const String channelsAutocomplete = '/channels/autocomplete';
  static String channelCategories(String userId, String teamId) =>
      '/users/$userId/teams/$teamId/channels/categories';
  static String channelCategory(
          String userId, String teamId, String categoryId) =>
      '/users/$userId/teams/$teamId/channels/categories/$categoryId';

  // Posts
  static String channelPosts(String channelId) =>
      '/channels/$channelId/posts';
  static String channelPinnedPosts(String channelId) =>
      '/channels/$channelId/pinned';
  static String post(String id) => '/posts/$id';
  static String postThread(String id) => '/posts/$id/thread';
  static String flaggedPosts(String userId) => '/users/$userId/posts/flagged';
  static String userThreads(String userId, String teamId) =>
      '/users/$userId/teams/$teamId/threads';
  static String teamPostsSearch(String teamId) =>
      '/teams/$teamId/posts/search';
  static String postPatch(String id) => '/posts/$id/patch';
  static String pinPost(String id) => '/posts/$id/pin';
  static String unpinPost(String id) => '/posts/$id/unpin';

  // Reactions
  static const String reactions = '/reactions';
  static String postReactions(String postId) => '/posts/$postId/reactions';

  // Preferences (for flagged / saved)
  static String preferences(String userId) => '/users/$userId/preferences';
  static String preferencesDelete(String userId) =>
      '/users/$userId/preferences/delete';

  // Files
  static const String files = '/files';
  static String file(String id) => '/files/$id';
  static String fileThumbnail(String id) => '/files/$id/thumbnail';
  static String filePreview(String id) => '/files/$id/preview';
  static String filePublicLink(String id) => '/files/$id/link';

  // Seens (MyGames custom)
  static String channelSeens(String channelId) =>
      '/channels/$channelId/seens';
  static String postSeens(String postId) => '/posts/$postId/seens';

  // Users autocomplete
  static const String usersAutocomplete = '/users/autocomplete';

  // Status
  static const String usersStatus = '/users/status/ids';
  static String userStatus(String userId) => '/users/$userId/status';
  static String userCustomStatus(String userId) =>
      '/users/$userId/status/custom';

  // Device
  static const String deviceId = '/users/sessions/device_id';

  // Emoji
  static const String customEmojis = '/emoji';
  static String customEmojiImage(String emojiId) => '/emoji/$emojiId/image';

  // Config
  static const String clientConfig = '/config/client';
}
