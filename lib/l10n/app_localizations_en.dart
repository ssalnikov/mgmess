// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'MGMess';

  @override
  String get mattermostForMyGames => 'Mattermost for MyGames';

  @override
  String get mattermostClient => 'Mattermost Client';

  @override
  String get or => 'or';

  @override
  String get signInWithGitLab => 'Sign in with GitLab';

  @override
  String get emailOrUsername => 'Email or Username';

  @override
  String get email => 'Email';

  @override
  String get username => 'Username';

  @override
  String pleaseEnterField(String field) {
    return 'Please enter your $field';
  }

  @override
  String get password => 'Password';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get signIn => 'Sign In';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get serverUrlHint => 'https://mattermost.example.com';

  @override
  String get connect => 'Connect';

  @override
  String get enterServerUrl => 'Enter server URL';

  @override
  String get connectionTimedOut =>
      'Connection timed out. Check the URL and try again.';

  @override
  String get cannotConnectToServer =>
      'Cannot connect to server. Check the URL.';

  @override
  String serverError(String statusCode) {
    return 'Server error: $statusCode';
  }

  @override
  String connectionFailed(String message) {
    return 'Connection failed: $message';
  }

  @override
  String unexpectedError(String error) {
    return 'Unexpected error: $error';
  }

  @override
  String serverReturnedStatus(int statusCode) {
    return 'Server returned status $statusCode';
  }

  @override
  String get channels => 'Channels';

  @override
  String get newChannel => 'New Channel';

  @override
  String get createChannelSubtitle => 'Create a public or private channel';

  @override
  String get newMessage => 'New Message';

  @override
  String get startDirectOrGroupMessage => 'Start a direct or group message';

  @override
  String get threads => 'Threads';

  @override
  String get drafts => 'Drafts';

  @override
  String get searchChannels => 'Search channels...';

  @override
  String get otherChannels => 'Other channels';

  @override
  String get users => 'Users';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get publicType => 'Public';

  @override
  String get privateType => 'Private';

  @override
  String get create => 'Create';

  @override
  String get publicChannelsDescription =>
      'Public channels can be found and joined by anyone';

  @override
  String get privateChannelsDescription =>
      'Private channels are only visible to invited members';

  @override
  String get channelName => 'Channel name';

  @override
  String get channelNameHint => 'e.g. Project Updates';

  @override
  String get required_ => 'Required';

  @override
  String get urlLabel => 'URL';

  @override
  String get urlHint => 'e.g. project-updates';

  @override
  String get urlValidation => 'Only lowercase letters, numbers, - and _';

  @override
  String get purposeOptional => 'Purpose (optional)';

  @override
  String get purposeHint => 'Describe the channel purpose';

  @override
  String get headerOptional => 'Header (optional)';

  @override
  String get headerHint => 'Markdown-supported header text';

  @override
  String get go => 'Go';

  @override
  String get searchForPeople => 'Search for people...';

  @override
  String membersCount(int count) {
    return '$count members';
  }

  @override
  String get pinnedMessages => 'Pinned messages';

  @override
  String get newMessagesLabel => 'New messages';

  @override
  String get deleteMessageTitle => 'Delete message';

  @override
  String get deleteMessageConfirm =>
      'Are you sure you want to delete this message?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String typingIndicator(int count) {
    return '$count typing...';
  }

  @override
  String get standard => 'Standard';

  @override
  String get important => 'Important';

  @override
  String get urgent => 'Urgent';

  @override
  String get editingMessage => 'Editing message';

  @override
  String get writeAMessage => 'Write a message...';

  @override
  String get photoFromGallery => 'Photo from Gallery';

  @override
  String get file => 'File';

  @override
  String uploadFailed(String message) {
    return 'Upload failed: $message';
  }

  @override
  String get copy => 'Copy';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get quote => 'Quote';

  @override
  String get forward => 'Forward';

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get edit => 'Edit';

  @override
  String get profile => 'Profile';

  @override
  String get notAuthenticated => 'Not authenticated';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get nickname => 'Nickname';

  @override
  String get setAStatus => 'Set a status';

  @override
  String get status => 'Status';

  @override
  String get inAMeeting => 'In a meeting';

  @override
  String get commuting => 'Commuting';

  @override
  String get outSick => 'Out sick';

  @override
  String get workingFromHome => 'Working from home';

  @override
  String get onVacation => 'On vacation';

  @override
  String get customStatus => 'Custom Status';

  @override
  String get whatsYourStatus => 'What\'s your status?';

  @override
  String get quickSelect => 'Quick select';

  @override
  String get clear => 'Clear';

  @override
  String get save => 'Save';

  @override
  String get chooseEmoji => 'Choose Emoji';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get notificationSettings => 'Notification Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get server => 'Server';

  @override
  String get changeServer => 'Change Server';

  @override
  String get signOut => 'Sign Out';

  @override
  String get changeServerMessage =>
      'You will be signed out and redirected to the server selection screen.';

  @override
  String get change => 'Change';

  @override
  String get online => 'Online';

  @override
  String get away => 'Away';

  @override
  String get doNotDisturb => 'Do Not Disturb';

  @override
  String get offline => 'Offline';

  @override
  String get youAppearAsActive => 'You appear as active';

  @override
  String get youAppearAsAway => 'You appear as away';

  @override
  String get notificationsDisabled => 'Notifications are disabled';

  @override
  String get youAppearAsOffline => 'You appear as offline';

  @override
  String get biometricLock => 'Biometric Lock';

  @override
  String get notifications => 'Notifications';

  @override
  String get pushNotifications => 'Push Notifications';

  @override
  String get receiveNotificationsSubtitle =>
      'Receive notifications for new messages';

  @override
  String get notifyMeAbout => 'Notify me about...';

  @override
  String get allNewMessages => 'All new messages';

  @override
  String get mentionsAndDM => 'Mentions & direct messages';

  @override
  String get dmOnly => 'Direct messages only';

  @override
  String get header => 'Header';

  @override
  String get purpose => 'Purpose';

  @override
  String get leaveChannel => 'Leave Channel';

  @override
  String get directMessage => 'Direct Message';

  @override
  String get groupMessage => 'Group Message';

  @override
  String get privateChannel => 'Private Channel';

  @override
  String get publicChannel => 'Public Channel';

  @override
  String membersWithCount(int count) {
    return 'Members ($count)';
  }

  @override
  String get notificationPreferences => 'Notification Preferences';

  @override
  String leaveChannelConfirm(String channelName) {
    return 'Are you sure you want to leave \"$channelName\"?';
  }

  @override
  String get leave => 'Leave';

  @override
  String get editChannel => 'Edit Channel';

  @override
  String get name => 'Name';

  @override
  String get channelNameHintEdit => 'Channel name';

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String get channelHeader => 'Channel header';

  @override
  String get channelHeaderDescription =>
      'Text displayed at the top of the channel. Often used for links and quick reference info.';

  @override
  String get channelPurpose => 'Channel purpose';

  @override
  String get channelPurposeDescription =>
      'Describe the purpose of this channel. Helps other users understand what it is for.';

  @override
  String get failedToUpdateChannel => 'Failed to update channel';

  @override
  String get members => 'Members';

  @override
  String get admins => 'Admins';

  @override
  String get removeAdmin => 'Remove Admin';

  @override
  String get makeAdmin => 'Make Admin';

  @override
  String get removeFromChannel => 'Remove from Channel';

  @override
  String get remove => 'Remove';

  @override
  String removeFromChannelConfirm(String userName) {
    return 'Remove $userName from channel?';
  }

  @override
  String get searchUsers => 'Search users...';

  @override
  String userAdded(String userName) {
    return '$userName added';
  }

  @override
  String get recentMentions => 'Recent Mentions';

  @override
  String get noRecentMentions => 'No recent mentions';

  @override
  String get savedMessages => 'Saved Messages';

  @override
  String get noSavedMessages => 'No saved messages';

  @override
  String get noThreads => 'No threads';

  @override
  String repliesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count replies',
      one: '1 reply',
    );
    return '$_temp0';
  }

  @override
  String get noDrafts => 'No drafts';

  @override
  String get unknownChannel => 'Unknown channel';

  @override
  String get thread => 'Thread';

  @override
  String get userProfile => 'User Profile';

  @override
  String get sendMessage => 'Send Message';

  @override
  String get userNotFound => 'User not found';

  @override
  String get position => 'Position';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get avatarUpdated => 'Avatar updated';

  @override
  String get authenticationRequired => 'Authentication required';

  @override
  String get unlock => 'Unlock';

  @override
  String get skip => 'Skip';

  @override
  String get realtimeMessaging => 'Real-time Messaging';

  @override
  String get realtimeMessagingDesc =>
      'Send messages, share files, and react with emoji. All synced in real-time with your Mattermost server.';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get quickActionsDesc =>
      'Long-press a message for actions like reply, forward, pin, and edit. Swipe right to reply quickly.';

  @override
  String get stayOrganized => 'Stay Organized';

  @override
  String get stayOrganizedDesc =>
      'Use channels, threads, and search to keep conversations organized. Pin important messages and save them for later.';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get Started';

  @override
  String get saved => 'Saved';

  @override
  String get mentions => 'Mentions';

  @override
  String get retry => 'Retry';

  @override
  String get pinned => 'Pinned';

  @override
  String get edited => '(edited)';

  @override
  String get forwarded => 'Forwarded';

  @override
  String forwardedFrom(String channelName) {
    return 'Forwarded from #$channelName';
  }

  @override
  String newMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new messages',
      one: '1 new message',
    );
    return '$_temp0';
  }

  @override
  String get noPinnedMessages => 'No pinned messages';

  @override
  String get searchEmoji => 'Search emoji...';

  @override
  String get nothingFound => 'Nothing found';

  @override
  String get noEmojisYet => 'No emojis yet';

  @override
  String get searchMessages => 'Search messages...';

  @override
  String get filters => 'Filters';

  @override
  String get searchMessagesHint => 'Search messages';

  @override
  String get useFiltersHint => 'Use filters for more precise results';

  @override
  String get searchFilters => 'Search Filters';

  @override
  String get fromUser => 'From user';

  @override
  String get inChannel => 'In channel';

  @override
  String get files => 'Files';

  @override
  String get images => 'Images';

  @override
  String get links => 'Links';

  @override
  String get after => 'After';

  @override
  String get before => 'Before';

  @override
  String get onDate => 'On date';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get defaultNotif => 'Default';

  @override
  String get useGlobalSetting => 'Use global notification setting';

  @override
  String get allMessages => 'All messages';

  @override
  String get notifyEveryMessage => 'Notify for every new message';

  @override
  String get mentionsOnly => 'Mentions only';

  @override
  String get onlyWhenMentioned => 'Only when you are mentioned';

  @override
  String get nothing => 'Nothing';

  @override
  String get neverNotify => 'Never notify for this channel';

  @override
  String notificationsChannelTitle(String channelName) {
    return 'Notifications — $channelName';
  }

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System';

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get team => 'Team';

  @override
  String get switchTeam => 'Switch Team';

  @override
  String lastSeenAt(String time) {
    return 'Last seen $time';
  }

  @override
  String get lastSeenJustNow => 'Last seen just now';

  @override
  String get commonChannels => 'Common channels';

  @override
  String get noCommonChannels => 'No common channels';

  @override
  String get jumpToDate => 'Jump to date';

  @override
  String get noMessagesOnDate => 'No messages on this date';

  @override
  String get clearImageCache => 'Clear Image Cache';

  @override
  String get imageCacheCleared => 'Image cache cleared';

  @override
  String get imageCache => 'Image Cache';
}
