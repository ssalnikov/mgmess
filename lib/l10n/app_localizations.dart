import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'MGMess'**
  String get appName;

  /// No description provided for @mattermostForMyGames.
  ///
  /// In en, this message translates to:
  /// **'Mattermost for MyGames'**
  String get mattermostForMyGames;

  /// No description provided for @mattermostClient.
  ///
  /// In en, this message translates to:
  /// **'Mattermost Client'**
  String get mattermostClient;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @signInWithGitLab.
  ///
  /// In en, this message translates to:
  /// **'Sign in with GitLab'**
  String get signInWithGitLab;

  /// No description provided for @emailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or Username'**
  String get emailOrUsername;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @pleaseEnterField.
  ///
  /// In en, this message translates to:
  /// **'Please enter your {field}'**
  String pleaseEnterField(String field);

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @serverUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://mattermost.example.com'**
  String get serverUrlHint;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @enterServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter server URL'**
  String get enterServerUrl;

  /// No description provided for @connectionTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Check the URL and try again.'**
  String get connectionTimedOut;

  /// No description provided for @cannotConnectToServer.
  ///
  /// In en, this message translates to:
  /// **'Cannot connect to server. Check the URL.'**
  String get cannotConnectToServer;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error: {statusCode}'**
  String serverError(String statusCode);

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {message}'**
  String connectionFailed(String message);

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error: {error}'**
  String unexpectedError(String error);

  /// No description provided for @serverReturnedStatus.
  ///
  /// In en, this message translates to:
  /// **'Server returned status {statusCode}'**
  String serverReturnedStatus(int statusCode);

  /// No description provided for @channels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get channels;

  /// No description provided for @newChannel.
  ///
  /// In en, this message translates to:
  /// **'New Channel'**
  String get newChannel;

  /// No description provided for @createChannelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a public or private channel'**
  String get createChannelSubtitle;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get newMessage;

  /// No description provided for @startDirectOrGroupMessage.
  ///
  /// In en, this message translates to:
  /// **'Start a direct or group message'**
  String get startDirectOrGroupMessage;

  /// No description provided for @threads.
  ///
  /// In en, this message translates to:
  /// **'Threads'**
  String get threads;

  /// No description provided for @drafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get drafts;

  /// No description provided for @searchChannels.
  ///
  /// In en, this message translates to:
  /// **'Search channels...'**
  String get searchChannels;

  /// No description provided for @otherChannels.
  ///
  /// In en, this message translates to:
  /// **'Other channels'**
  String get otherChannels;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @publicType.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get publicType;

  /// No description provided for @privateType.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get privateType;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @publicChannelsDescription.
  ///
  /// In en, this message translates to:
  /// **'Public channels can be found and joined by anyone'**
  String get publicChannelsDescription;

  /// No description provided for @privateChannelsDescription.
  ///
  /// In en, this message translates to:
  /// **'Private channels are only visible to invited members'**
  String get privateChannelsDescription;

  /// No description provided for @channelName.
  ///
  /// In en, this message translates to:
  /// **'Channel name'**
  String get channelName;

  /// No description provided for @channelNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Project Updates'**
  String get channelNameHint;

  /// No description provided for @required_.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required_;

  /// No description provided for @urlLabel.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get urlLabel;

  /// No description provided for @urlHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. project-updates'**
  String get urlHint;

  /// No description provided for @urlValidation.
  ///
  /// In en, this message translates to:
  /// **'Only lowercase letters, numbers, - and _'**
  String get urlValidation;

  /// No description provided for @purposeOptional.
  ///
  /// In en, this message translates to:
  /// **'Purpose (optional)'**
  String get purposeOptional;

  /// No description provided for @purposeHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the channel purpose'**
  String get purposeHint;

  /// No description provided for @headerOptional.
  ///
  /// In en, this message translates to:
  /// **'Header (optional)'**
  String get headerOptional;

  /// No description provided for @headerHint.
  ///
  /// In en, this message translates to:
  /// **'Markdown-supported header text'**
  String get headerHint;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @searchForPeople.
  ///
  /// In en, this message translates to:
  /// **'Search for people...'**
  String get searchForPeople;

  /// No description provided for @membersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String membersCount(int count);

  /// No description provided for @pinnedMessages.
  ///
  /// In en, this message translates to:
  /// **'Pinned messages'**
  String get pinnedMessages;

  /// No description provided for @newMessagesLabel.
  ///
  /// In en, this message translates to:
  /// **'New messages'**
  String get newMessagesLabel;

  /// No description provided for @deleteMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get deleteMessageTitle;

  /// No description provided for @deleteMessageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get deleteMessageConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @typingIndicator.
  ///
  /// In en, this message translates to:
  /// **'{count} typing...'**
  String typingIndicator(int count);

  /// No description provided for @standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standard;

  /// No description provided for @important.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get important;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @editingMessage.
  ///
  /// In en, this message translates to:
  /// **'Editing message'**
  String get editingMessage;

  /// No description provided for @writeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Write a message...'**
  String get writeAMessage;

  /// No description provided for @photoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Photo from Gallery'**
  String get photoFromGallery;

  /// No description provided for @file.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get file;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {message}'**
  String uploadFailed(String message);

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @quote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get quote;

  /// No description provided for @forward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get forward;

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @notAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get notAuthenticated;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @setAStatus.
  ///
  /// In en, this message translates to:
  /// **'Set a status'**
  String get setAStatus;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @inAMeeting.
  ///
  /// In en, this message translates to:
  /// **'In a meeting'**
  String get inAMeeting;

  /// No description provided for @commuting.
  ///
  /// In en, this message translates to:
  /// **'Commuting'**
  String get commuting;

  /// No description provided for @outSick.
  ///
  /// In en, this message translates to:
  /// **'Out sick'**
  String get outSick;

  /// No description provided for @workingFromHome.
  ///
  /// In en, this message translates to:
  /// **'Working from home'**
  String get workingFromHome;

  /// No description provided for @onVacation.
  ///
  /// In en, this message translates to:
  /// **'On vacation'**
  String get onVacation;

  /// No description provided for @customStatus.
  ///
  /// In en, this message translates to:
  /// **'Custom Status'**
  String get customStatus;

  /// No description provided for @whatsYourStatus.
  ///
  /// In en, this message translates to:
  /// **'What\'s your status?'**
  String get whatsYourStatus;

  /// No description provided for @quickSelect.
  ///
  /// In en, this message translates to:
  /// **'Quick select'**
  String get quickSelect;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @chooseEmoji.
  ///
  /// In en, this message translates to:
  /// **'Choose Emoji'**
  String get chooseEmoji;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @notificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @server.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// No description provided for @changeServer.
  ///
  /// In en, this message translates to:
  /// **'Change Server'**
  String get changeServer;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @changeServerMessage.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out and redirected to the server selection screen.'**
  String get changeServerMessage;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @away.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get away;

  /// No description provided for @doNotDisturb.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb'**
  String get doNotDisturb;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @youAppearAsActive.
  ///
  /// In en, this message translates to:
  /// **'You appear as active'**
  String get youAppearAsActive;

  /// No description provided for @youAppearAsAway.
  ///
  /// In en, this message translates to:
  /// **'You appear as away'**
  String get youAppearAsAway;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled'**
  String get notificationsDisabled;

  /// No description provided for @youAppearAsOffline.
  ///
  /// In en, this message translates to:
  /// **'You appear as offline'**
  String get youAppearAsOffline;

  /// No description provided for @biometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get biometricLock;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @receiveNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications for new messages'**
  String get receiveNotificationsSubtitle;

  /// No description provided for @notifyMeAbout.
  ///
  /// In en, this message translates to:
  /// **'Notify me about...'**
  String get notifyMeAbout;

  /// No description provided for @allNewMessages.
  ///
  /// In en, this message translates to:
  /// **'All new messages'**
  String get allNewMessages;

  /// No description provided for @mentionsAndDM.
  ///
  /// In en, this message translates to:
  /// **'Mentions & direct messages'**
  String get mentionsAndDM;

  /// No description provided for @dmOnly.
  ///
  /// In en, this message translates to:
  /// **'Direct messages only'**
  String get dmOnly;

  /// No description provided for @header.
  ///
  /// In en, this message translates to:
  /// **'Header'**
  String get header;

  /// No description provided for @purpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get purpose;

  /// No description provided for @leaveChannel.
  ///
  /// In en, this message translates to:
  /// **'Leave Channel'**
  String get leaveChannel;

  /// No description provided for @directMessage.
  ///
  /// In en, this message translates to:
  /// **'Direct Message'**
  String get directMessage;

  /// No description provided for @groupMessage.
  ///
  /// In en, this message translates to:
  /// **'Group Message'**
  String get groupMessage;

  /// No description provided for @privateChannel.
  ///
  /// In en, this message translates to:
  /// **'Private Channel'**
  String get privateChannel;

  /// No description provided for @publicChannel.
  ///
  /// In en, this message translates to:
  /// **'Public Channel'**
  String get publicChannel;

  /// No description provided for @membersWithCount.
  ///
  /// In en, this message translates to:
  /// **'Members ({count})'**
  String membersWithCount(int count);

  /// No description provided for @notificationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Notification Preferences'**
  String get notificationPreferences;

  /// No description provided for @leaveChannelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to leave \"{channelName}\"?'**
  String leaveChannelConfirm(String channelName);

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @editChannel.
  ///
  /// In en, this message translates to:
  /// **'Edit Channel'**
  String get editChannel;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @channelNameHintEdit.
  ///
  /// In en, this message translates to:
  /// **'Channel name'**
  String get channelNameHintEdit;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @channelHeader.
  ///
  /// In en, this message translates to:
  /// **'Channel header'**
  String get channelHeader;

  /// No description provided for @channelHeaderDescription.
  ///
  /// In en, this message translates to:
  /// **'Text displayed at the top of the channel. Often used for links and quick reference info.'**
  String get channelHeaderDescription;

  /// No description provided for @channelPurpose.
  ///
  /// In en, this message translates to:
  /// **'Channel purpose'**
  String get channelPurpose;

  /// No description provided for @channelPurposeDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe the purpose of this channel. Helps other users understand what it is for.'**
  String get channelPurposeDescription;

  /// No description provided for @failedToUpdateChannel.
  ///
  /// In en, this message translates to:
  /// **'Failed to update channel'**
  String get failedToUpdateChannel;

  /// No description provided for @members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// No description provided for @admins.
  ///
  /// In en, this message translates to:
  /// **'Admins'**
  String get admins;

  /// No description provided for @removeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove Admin'**
  String get removeAdmin;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make Admin'**
  String get makeAdmin;

  /// No description provided for @removeFromChannel.
  ///
  /// In en, this message translates to:
  /// **'Remove from Channel'**
  String get removeFromChannel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeFromChannelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {userName} from channel?'**
  String removeFromChannelConfirm(String userName);

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get searchUsers;

  /// No description provided for @userAdded.
  ///
  /// In en, this message translates to:
  /// **'{userName} added'**
  String userAdded(String userName);

  /// No description provided for @recentMentions.
  ///
  /// In en, this message translates to:
  /// **'Recent Mentions'**
  String get recentMentions;

  /// No description provided for @noRecentMentions.
  ///
  /// In en, this message translates to:
  /// **'No recent mentions'**
  String get noRecentMentions;

  /// No description provided for @savedMessages.
  ///
  /// In en, this message translates to:
  /// **'Saved Messages'**
  String get savedMessages;

  /// No description provided for @noSavedMessages.
  ///
  /// In en, this message translates to:
  /// **'No saved messages'**
  String get noSavedMessages;

  /// No description provided for @noThreads.
  ///
  /// In en, this message translates to:
  /// **'No threads'**
  String get noThreads;

  /// No description provided for @repliesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 reply} other{{count} replies}}'**
  String repliesCount(int count);

  /// No description provided for @noDrafts.
  ///
  /// In en, this message translates to:
  /// **'No drafts'**
  String get noDrafts;

  /// No description provided for @unknownChannel.
  ///
  /// In en, this message translates to:
  /// **'Unknown channel'**
  String get unknownChannel;

  /// No description provided for @thread.
  ///
  /// In en, this message translates to:
  /// **'Thread'**
  String get thread;

  /// No description provided for @userProfile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfile;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @position.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get position;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated'**
  String get avatarUpdated;

  /// No description provided for @authenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication required'**
  String get authenticationRequired;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @realtimeMessaging.
  ///
  /// In en, this message translates to:
  /// **'Real-time Messaging'**
  String get realtimeMessaging;

  /// No description provided for @realtimeMessagingDesc.
  ///
  /// In en, this message translates to:
  /// **'Send messages, share files, and react with emoji. All synced in real-time with your Mattermost server.'**
  String get realtimeMessagingDesc;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @quickActionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Long-press a message for actions like reply, forward, pin, and edit. Swipe right to reply quickly.'**
  String get quickActionsDesc;

  /// No description provided for @stayOrganized.
  ///
  /// In en, this message translates to:
  /// **'Stay Organized'**
  String get stayOrganized;

  /// No description provided for @stayOrganizedDesc.
  ///
  /// In en, this message translates to:
  /// **'Use channels, threads, and search to keep conversations organized. Pin important messages and save them for later.'**
  String get stayOrganizedDesc;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @mentions.
  ///
  /// In en, this message translates to:
  /// **'Mentions'**
  String get mentions;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @pinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get pinned;

  /// No description provided for @edited.
  ///
  /// In en, this message translates to:
  /// **'(edited)'**
  String get edited;

  /// No description provided for @forwarded.
  ///
  /// In en, this message translates to:
  /// **'Forwarded'**
  String get forwarded;

  /// No description provided for @forwardedFrom.
  ///
  /// In en, this message translates to:
  /// **'Forwarded from #{channelName}'**
  String forwardedFrom(String channelName);

  /// No description provided for @newMessagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 new message} other{{count} new messages}}'**
  String newMessagesCount(int count);

  /// No description provided for @noPinnedMessages.
  ///
  /// In en, this message translates to:
  /// **'No pinned messages'**
  String get noPinnedMessages;

  /// No description provided for @searchEmoji.
  ///
  /// In en, this message translates to:
  /// **'Search emoji...'**
  String get searchEmoji;

  /// No description provided for @nothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get nothingFound;

  /// No description provided for @noEmojisYet.
  ///
  /// In en, this message translates to:
  /// **'No emojis yet'**
  String get noEmojisYet;

  /// No description provided for @searchMessages.
  ///
  /// In en, this message translates to:
  /// **'Search messages...'**
  String get searchMessages;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @searchMessagesHint.
  ///
  /// In en, this message translates to:
  /// **'Search messages'**
  String get searchMessagesHint;

  /// No description provided for @useFiltersHint.
  ///
  /// In en, this message translates to:
  /// **'Use filters for more precise results'**
  String get useFiltersHint;

  /// No description provided for @searchFilters.
  ///
  /// In en, this message translates to:
  /// **'Search Filters'**
  String get searchFilters;

  /// No description provided for @fromUser.
  ///
  /// In en, this message translates to:
  /// **'From user'**
  String get fromUser;

  /// No description provided for @inChannel.
  ///
  /// In en, this message translates to:
  /// **'In channel'**
  String get inChannel;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @links.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get links;

  /// No description provided for @after.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get after;

  /// No description provided for @before.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get before;

  /// No description provided for @onDate.
  ///
  /// In en, this message translates to:
  /// **'On date'**
  String get onDate;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @defaultNotif.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultNotif;

  /// No description provided for @useGlobalSetting.
  ///
  /// In en, this message translates to:
  /// **'Use global notification setting'**
  String get useGlobalSetting;

  /// No description provided for @allMessages.
  ///
  /// In en, this message translates to:
  /// **'All messages'**
  String get allMessages;

  /// No description provided for @notifyEveryMessage.
  ///
  /// In en, this message translates to:
  /// **'Notify for every new message'**
  String get notifyEveryMessage;

  /// No description provided for @mentionsOnly.
  ///
  /// In en, this message translates to:
  /// **'Mentions only'**
  String get mentionsOnly;

  /// No description provided for @onlyWhenMentioned.
  ///
  /// In en, this message translates to:
  /// **'Only when you are mentioned'**
  String get onlyWhenMentioned;

  /// No description provided for @nothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get nothing;

  /// No description provided for @neverNotify.
  ///
  /// In en, this message translates to:
  /// **'Never notify for this channel'**
  String get neverNotify;

  /// No description provided for @notificationsChannelTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications — {channelName}'**
  String notificationsChannelTitle(String channelName);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @switchTeam.
  ///
  /// In en, this message translates to:
  /// **'Switch Team'**
  String get switchTeam;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
