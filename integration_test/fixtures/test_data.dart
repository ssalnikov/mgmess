import 'package:mgmess/domain/entities/channel.dart';
import 'package:mgmess/domain/entities/post.dart';
import 'package:mgmess/domain/entities/team.dart';
import 'package:mgmess/domain/entities/user.dart';

const testUser = User(
  id: 'user-001',
  username: 'testuser',
  email: 'test@my.games',
  firstName: 'Test',
  lastName: 'User',
  status: 'online',
);

const otherUser = User(
  id: 'user-002',
  username: 'otheruser',
  email: 'other@my.games',
  firstName: 'Other',
  lastName: 'User',
  status: 'online',
);

const testTeam = Team(
  id: 'team-001',
  name: 'mygames',
  displayName: 'MyGames',
  type: 'O',
);

final testChannels = [
  const Channel(
    id: 'ch-001',
    teamId: 'team-001',
    name: 'general',
    displayName: 'General',
    type: ChannelType.open,
    totalMsgCount: 100,
    lastPostAt: 1700000003000,
    msgCount: 100,
  ),
  const Channel(
    id: 'ch-002',
    teamId: 'team-001',
    name: 'flutter-dev',
    displayName: 'Flutter Development',
    type: ChannelType.open,
    totalMsgCount: 50,
    lastPostAt: 1700000002000,
    msgCount: 50,
  ),
  const Channel(
    id: 'ch-003',
    teamId: 'team-001',
    name: 'user-001__user-002',
    displayName: 'Other User',
    type: ChannelType.direct,
    totalMsgCount: 10,
    lastPostAt: 1700000001000,
    msgCount: 10,
  ),
];

final testPosts = [
  const Post(
    id: 'post-001',
    channelId: 'ch-001',
    userId: 'user-002',
    message: 'Hello everyone!',
    createAt: 1700000003000,
  ),
  const Post(
    id: 'post-002',
    channelId: 'ch-001',
    userId: 'user-001',
    message: 'Hi there!',
    createAt: 1700000002000,
  ),
  const Post(
    id: 'post-003',
    channelId: 'ch-001',
    userId: 'user-002',
    message: 'Welcome to MGMess',
    createAt: 1700000001000,
  ),
];

const testNewPost = Post(
  id: 'post-new-001',
  channelId: 'ch-001',
  userId: 'user-001',
  message: 'My new message',
  createAt: 1700000004000,
);

const testPostWithReply = Post(
  id: 'post-with-reply',
  channelId: 'ch-001',
  userId: 'user-002',
  message: 'Post with replies',
  createAt: 1700000005000,
  replyCount: 2,
);

const testPinnedPost = Post(
  id: 'post-pinned',
  channelId: 'ch-001',
  userId: 'user-002',
  message: 'This is pinned',
  createAt: 1700000006000,
  isPinned: true,
);
