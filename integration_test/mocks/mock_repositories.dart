import 'package:mocktail/mocktail.dart';

import 'package:mgmess/domain/repositories/auth_repository.dart';
import 'package:mgmess/domain/repositories/channel_repository.dart';
import 'package:mgmess/domain/repositories/post_repository.dart';
import 'package:mgmess/domain/repositories/user_repository.dart';
import 'package:mgmess/domain/repositories/file_repository.dart';
import 'package:mgmess/domain/repositories/seens_repository.dart';
import 'package:mgmess/domain/repositories/notification_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockChannelRepository extends Mock implements ChannelRepository {}

class MockPostRepository extends Mock implements PostRepository {}

class MockUserRepository extends Mock implements UserRepository {}

class MockFileRepository extends Mock implements FileRepository {}

class MockSeensRepository extends Mock implements SeensRepository {}

class MockNotificationRepository extends Mock
    implements NotificationRepository {}
