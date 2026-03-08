class RouteNames {
  static const String auth = '/auth';
  static const String channels = '/channels';
  static const String chat = '/chat/:channelId';
  static const String savedMessages = '/saved';
  static const String mentions = '/mentions';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String notificationSettings = '/profile/notifications';
  static const String userProfile = '/user/:userId';
  static const String threads = '/threads';
  static const String drafts = '/drafts';
  static const String search = '/search';
  static const String thread = '/thread/:postId';
  static const String channelInfo = '/channel/:channelId/info';
  static const String channelMembers = '/channel/:channelId/members';
  static const String channelEdit = '/channel/:channelId/edit';

  static String chatPath(String channelId) => '/chat/$channelId';
  static String userProfilePath(String userId) => '/user/$userId';
  static String threadPath(String postId) => '/thread/$postId';
  static String channelInfoPath(String channelId) =>
      '/channel/$channelId/info';
  static String channelMembersPath(String channelId) =>
      '/channel/$channelId/members';
  static String channelEditPath(String channelId) =>
      '/channel/$channelId/edit';

  static const String createChannel = '/create-channel';
  static const String createGroupDm = '/create-group-dm';
}
