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
  static String channelViewForUser(String userId) =>
      '/channels/members/$userId/view';
  static String directChannel = '/channels/direct';

  // Posts
  static String channelPosts(String channelId) =>
      '/channels/$channelId/posts';
  static String post(String id) => '/posts/$id';
  static String postThread(String id) => '/posts/$id/thread';
  static String flaggedPosts(String userId) => '/users/$userId/posts/flagged';
  static String userThreads(String userId, String teamId) =>
      '/users/$userId/teams/$teamId/threads';
  static String teamPostsSearch(String teamId) =>
      '/teams/$teamId/posts/search';
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

  // Status
  static const String usersStatus = '/users/status/ids';

  // Device
  static const String deviceId = '/users/sessions/device_id';

  // Config
  static const String clientConfig = '/config/client';
}
