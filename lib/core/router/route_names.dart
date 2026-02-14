class RouteNames {
  static const String auth = '/auth';
  static const String channels = '/channels';
  static const String chat = '/chat/:channelId';
  static const String savedMessages = '/saved';
  static const String mentions = '/mentions';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String userProfile = '/user/:userId';

  static String chatPath(String channelId) => '/chat/$channelId';
  static String userProfilePath(String userId) => '/user/$userId';
}
