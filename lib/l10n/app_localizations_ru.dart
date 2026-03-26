// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'MGMess';

  @override
  String get mattermostForMyGames => 'Mattermost для MyGames';

  @override
  String get mattermostClient => 'Клиент Mattermost';

  @override
  String get or => 'или';

  @override
  String get signInWithGitLab => 'Войти через GitLab';

  @override
  String get emailOrUsername => 'Email или имя пользователя';

  @override
  String get email => 'Email';

  @override
  String get username => 'Имя пользователя';

  @override
  String pleaseEnterField(String field) {
    return 'Введите $field';
  }

  @override
  String get password => 'Пароль';

  @override
  String get pleaseEnterPassword => 'Введите пароль';

  @override
  String get signIn => 'Войти';

  @override
  String get serverUrl => 'URL сервера';

  @override
  String get serverUrlHint => 'https://mattermost.example.com';

  @override
  String get connect => 'Подключиться';

  @override
  String get enterServerUrl => 'Введите URL сервера';

  @override
  String get connectionTimedOut =>
      'Превышено время ожидания. Проверьте URL и попробуйте снова.';

  @override
  String get cannotConnectToServer =>
      'Не удаётся подключиться к серверу. Проверьте URL.';

  @override
  String serverError(String statusCode) {
    return 'Ошибка сервера: $statusCode';
  }

  @override
  String connectionFailed(String message) {
    return 'Ошибка подключения: $message';
  }

  @override
  String unexpectedError(String error) {
    return 'Непредвиденная ошибка: $error';
  }

  @override
  String serverReturnedStatus(int statusCode) {
    return 'Сервер вернул статус $statusCode';
  }

  @override
  String get channels => 'Каналы';

  @override
  String get newChannel => 'Новый канал';

  @override
  String get createChannelSubtitle => 'Создать публичный или приватный канал';

  @override
  String get newMessage => 'Новое сообщение';

  @override
  String get startDirectOrGroupMessage =>
      'Начать личное или групповое сообщение';

  @override
  String get threads => 'Треды';

  @override
  String get drafts => 'Черновики';

  @override
  String get searchChannels => 'Поиск каналов...';

  @override
  String get otherChannels => 'Другие каналы';

  @override
  String get users => 'Пользователи';

  @override
  String get noResultsFound => 'Ничего не найдено';

  @override
  String get mute => 'Заглушить';

  @override
  String get unmute => 'Включить звук';

  @override
  String get publicType => 'Публичный';

  @override
  String get privateType => 'Приватный';

  @override
  String get create => 'Создать';

  @override
  String get publicChannelsDescription =>
      'Публичные каналы могут быть найдены и доступны всем';

  @override
  String get privateChannelsDescription =>
      'Приватные каналы видны только приглашённым участникам';

  @override
  String get channelName => 'Название канала';

  @override
  String get channelNameHint => 'напр. Обновления проекта';

  @override
  String get required_ => 'Обязательно';

  @override
  String get urlLabel => 'URL';

  @override
  String get urlHint => 'напр. project-updates';

  @override
  String get urlValidation => 'Только строчные буквы, цифры, - и _';

  @override
  String get purposeOptional => 'Назначение (необязательно)';

  @override
  String get purposeHint => 'Опишите назначение канала';

  @override
  String get headerOptional => 'Заголовок (необязательно)';

  @override
  String get headerHint => 'Текст заголовка с поддержкой Markdown';

  @override
  String get go => 'Начать';

  @override
  String get searchForPeople => 'Поиск людей...';

  @override
  String membersCount(int count) {
    return '$count участн.';
  }

  @override
  String get pinnedMessages => 'Закреплённые сообщения';

  @override
  String get newMessagesLabel => 'Новые сообщения';

  @override
  String get deleteMessageTitle => 'Удалить сообщение';

  @override
  String get deleteMessageConfirm =>
      'Вы уверены, что хотите удалить это сообщение?';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String typingIndicator(int count) {
    return '$count печатает...';
  }

  @override
  String get standard => 'Обычный';

  @override
  String get important => 'Важный';

  @override
  String get urgent => 'Срочный';

  @override
  String get editingMessage => 'Редактирование сообщения';

  @override
  String get writeAMessage => 'Напишите сообщение...';

  @override
  String get photoFromGallery => 'Фото из галереи';

  @override
  String get file => 'Файл';

  @override
  String uploadFailed(String message) {
    return 'Ошибка загрузки: $message';
  }

  @override
  String get copy => 'Копировать';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get quote => 'Цитировать';

  @override
  String get forward => 'Переслать';

  @override
  String get pin => 'Закрепить';

  @override
  String get unpin => 'Открепить';

  @override
  String get edit => 'Редактировать';

  @override
  String get profile => 'Профиль';

  @override
  String get notAuthenticated => 'Не авторизован';

  @override
  String get firstName => 'Имя';

  @override
  String get lastName => 'Фамилия';

  @override
  String get nickname => 'Никнейм';

  @override
  String get setAStatus => 'Установить статус';

  @override
  String get status => 'Статус';

  @override
  String get inAMeeting => 'На совещании';

  @override
  String get commuting => 'В дороге';

  @override
  String get outSick => 'На больничном';

  @override
  String get workingFromHome => 'Работаю из дома';

  @override
  String get onVacation => 'В отпуске';

  @override
  String get customStatus => 'Пользовательский статус';

  @override
  String get whatsYourStatus => 'Какой у вас статус?';

  @override
  String get quickSelect => 'Быстрый выбор';

  @override
  String get clear => 'Очистить';

  @override
  String get save => 'Сохранить';

  @override
  String get chooseEmoji => 'Выбрать эмодзи';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get notificationSettings => 'Настройки уведомлений';

  @override
  String get appearance => 'Оформление';

  @override
  String get systemTheme => 'Системная';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get darkTheme => 'Тёмная';

  @override
  String get server => 'Сервер';

  @override
  String get changeServer => 'Сменить сервер';

  @override
  String get signOut => 'Выйти';

  @override
  String get changeServerMessage =>
      'Вы будете отключены и перенаправлены на экран выбора сервера.';

  @override
  String get change => 'Сменить';

  @override
  String get online => 'В сети';

  @override
  String get away => 'Отошёл';

  @override
  String get doNotDisturb => 'Не беспокоить';

  @override
  String get offline => 'Не в сети';

  @override
  String get youAppearAsActive => 'Вы отображаетесь как активный';

  @override
  String get youAppearAsAway => 'Вы отображаетесь как отошедший';

  @override
  String get notificationsDisabled => 'Уведомления отключены';

  @override
  String get youAppearAsOffline => 'Вы отображаетесь как не в сети';

  @override
  String get biometricLock => 'Биометрическая блокировка';

  @override
  String get notifications => 'Уведомления';

  @override
  String get pushNotifications => 'Push-уведомления';

  @override
  String get receiveNotificationsSubtitle =>
      'Получать уведомления о новых сообщениях';

  @override
  String get notifyMeAbout => 'Уведомлять о...';

  @override
  String get allNewMessages => 'Все новые сообщения';

  @override
  String get mentionsAndDM => 'Упоминания и личные сообщения';

  @override
  String get dmOnly => 'Только личные сообщения';

  @override
  String get header => 'Заголовок';

  @override
  String get purpose => 'Назначение';

  @override
  String get leaveChannel => 'Покинуть канал';

  @override
  String get directMessage => 'Личное сообщение';

  @override
  String get groupMessage => 'Групповое сообщение';

  @override
  String get privateChannel => 'Приватный канал';

  @override
  String get publicChannel => 'Публичный канал';

  @override
  String membersWithCount(int count) {
    return 'Участники ($count)';
  }

  @override
  String get notificationPreferences => 'Настройки уведомлений';

  @override
  String leaveChannelConfirm(String channelName) {
    return 'Вы уверены, что хотите покинуть «$channelName»?';
  }

  @override
  String get leave => 'Покинуть';

  @override
  String get editChannel => 'Редактировать канал';

  @override
  String get name => 'Название';

  @override
  String get channelNameHintEdit => 'Название канала';

  @override
  String get nameCannotBeEmpty => 'Название не может быть пустым';

  @override
  String get channelHeader => 'Заголовок канала';

  @override
  String get channelHeaderDescription =>
      'Текст, отображаемый в верхней части канала. Часто используется для ссылок и справочной информации.';

  @override
  String get channelPurpose => 'Назначение канала';

  @override
  String get channelPurposeDescription =>
      'Опишите назначение этого канала. Помогает другим пользователям понять, для чего он создан.';

  @override
  String get failedToUpdateChannel => 'Не удалось обновить канал';

  @override
  String get members => 'Участники';

  @override
  String get admins => 'Администраторы';

  @override
  String get removeAdmin => 'Снять администратора';

  @override
  String get makeAdmin => 'Сделать администратором';

  @override
  String get removeFromChannel => 'Удалить из канала';

  @override
  String get remove => 'Удалить';

  @override
  String removeFromChannelConfirm(String userName) {
    return 'Удалить $userName из канала?';
  }

  @override
  String get searchUsers => 'Поиск пользователей...';

  @override
  String userAdded(String userName) {
    return '$userName добавлен';
  }

  @override
  String get recentMentions => 'Последние упоминания';

  @override
  String get noRecentMentions => 'Нет упоминаний';

  @override
  String get savedMessages => 'Сохранённые сообщения';

  @override
  String get noSavedMessages => 'Нет сохранённых сообщений';

  @override
  String get noThreads => 'Нет тредов';

  @override
  String repliesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ответов',
      few: '$count ответа',
      one: '1 ответ',
    );
    return '$_temp0';
  }

  @override
  String get noDrafts => 'Нет черновиков';

  @override
  String get unknownChannel => 'Неизвестный канал';

  @override
  String get thread => 'Тред';

  @override
  String get userProfile => 'Профиль пользователя';

  @override
  String get sendMessage => 'Отправить сообщение';

  @override
  String get userNotFound => 'Пользователь не найден';

  @override
  String get position => 'Должность';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get chooseFromGallery => 'Выбрать из галереи';

  @override
  String get avatarUpdated => 'Аватар обновлён';

  @override
  String get authenticationRequired => 'Требуется аутентификация';

  @override
  String get unlock => 'Разблокировать';

  @override
  String get skip => 'Пропустить';

  @override
  String get realtimeMessaging => 'Обмен сообщениями в реальном времени';

  @override
  String get realtimeMessagingDesc =>
      'Отправляйте сообщения, делитесь файлами и реагируйте эмодзи. Всё синхронизировано в реальном времени с вашим сервером Mattermost.';

  @override
  String get quickActions => 'Быстрые действия';

  @override
  String get quickActionsDesc =>
      'Нажмите и удерживайте сообщение для ответа, пересылки, закрепления и редактирования. Свайпните вправо для быстрого ответа.';

  @override
  String get stayOrganized => 'Будьте организованы';

  @override
  String get stayOrganizedDesc =>
      'Используйте каналы, треды и поиск для организации общения. Закрепляйте важные сообщения и сохраняйте их на потом.';

  @override
  String get next => 'Далее';

  @override
  String get getStarted => 'Начать';

  @override
  String get saved => 'Сохранённые';

  @override
  String get mentions => 'Упоминания';

  @override
  String get retry => 'Повторить';

  @override
  String get pinned => 'Закреплено';

  @override
  String get edited => '(изменено)';

  @override
  String get forwarded => 'Переслано';

  @override
  String forwardedFrom(String channelName) {
    return 'Переслано из #$channelName';
  }

  @override
  String newMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count новых сообщений',
      few: '$count новых сообщения',
      one: '1 новое сообщение',
    );
    return '$_temp0';
  }

  @override
  String get noPinnedMessages => 'Нет закреплённых сообщений';

  @override
  String get searchEmoji => 'Поиск эмодзи...';

  @override
  String get nothingFound => 'Ничего не найдено';

  @override
  String get noEmojisYet => 'Пока нет эмодзи';

  @override
  String get searchMessages => 'Поиск сообщений...';

  @override
  String get filters => 'Фильтры';

  @override
  String get searchMessagesHint => 'Поиск сообщений';

  @override
  String get useFiltersHint => 'Используйте фильтры для точных результатов';

  @override
  String get searchFilters => 'Фильтры поиска';

  @override
  String get fromUser => 'От пользователя';

  @override
  String get inChannel => 'В канале';

  @override
  String get files => 'Файлы';

  @override
  String get images => 'Изображения';

  @override
  String get links => 'Ссылки';

  @override
  String get after => 'После';

  @override
  String get before => 'До';

  @override
  String get onDate => 'На дату';

  @override
  String get applyFilters => 'Применить фильтры';

  @override
  String get defaultNotif => 'По умолчанию';

  @override
  String get useGlobalSetting => 'Использовать глобальную настройку';

  @override
  String get allMessages => 'Все сообщения';

  @override
  String get notifyEveryMessage => 'Уведомлять о каждом новом сообщении';

  @override
  String get mentionsOnly => 'Только упоминания';

  @override
  String get onlyWhenMentioned => 'Только при упоминании';

  @override
  String get nothing => 'Ничего';

  @override
  String get neverNotify => 'Никогда не уведомлять для этого канала';

  @override
  String notificationsChannelTitle(String channelName) {
    return 'Уведомления — $channelName';
  }

  @override
  String get language => 'Язык';

  @override
  String get systemLanguage => 'Системный';

  @override
  String get english => 'English';

  @override
  String get russian => 'Русский';

  @override
  String get team => 'Команда';

  @override
  String get switchTeam => 'Сменить команду';

  @override
  String lastSeenAt(String time) {
    return 'Был(а) в сети $time';
  }

  @override
  String get lastSeenJustNow => 'Был(а) в сети только что';

  @override
  String get commonChannels => 'Общие каналы';

  @override
  String get noCommonChannels => 'Нет общих каналов';

  @override
  String get jumpToDate => 'Перейти к дате';

  @override
  String get noMessagesOnDate => 'Нет сообщений за эту дату';

  @override
  String get clearImageCache => 'Очистить кэш изображений';

  @override
  String get imageCacheCleared => 'Кэш изображений очищён';

  @override
  String get imageCache => 'Кэш изображений';

  @override
  String get slashCommands => 'Слэш-команды';

  @override
  String get noCommandsAvailable => 'Нет доступных команд';

  @override
  String commandFailed(String message) {
    return 'Ошибка команды: $message';
  }

  @override
  String get readOnlyChannel => 'Этот канал доступен только для чтения';

  @override
  String get channelFiles => 'Файлы';

  @override
  String get noFiles => 'Нет файлов в этом канале';

  @override
  String get allFiles => 'Все';

  @override
  String get documents => 'Документы';

  @override
  String get servers => 'Серверы';

  @override
  String get addServer => 'Добавить сервер';

  @override
  String get removeServer => 'Удалить сервер';

  @override
  String removeServerConfirm(String serverName) {
    return 'Удалить сервер $serverName? Данные на сервере не будут удалены.';
  }

  @override
  String get activeServer => 'Активный';

  @override
  String get noOtherServers => 'Нет других серверов';

  @override
  String get serverAdded => 'Сервер добавлен';

  @override
  String get serverRemoved => 'Сервер удалён';

  @override
  String get cannotRemoveLastServer => 'Нельзя удалить единственный сервер';
}
