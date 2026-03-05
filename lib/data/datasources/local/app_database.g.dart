// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PostsTable extends Posts with TableInfo<$PostsTable, Post> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PostsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelIdMeta = const VerificationMeta(
    'channelId',
  );
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
    'channel_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rootIdMeta = const VerificationMeta('rootId');
  @override
  late final GeneratedColumn<String> rootId = GeneratedColumn<String>(
    'root_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createAtMeta = const VerificationMeta(
    'createAt',
  );
  @override
  late final GeneratedColumn<int> createAt = GeneratedColumn<int>(
    'create_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updateAtMeta = const VerificationMeta(
    'updateAt',
  );
  @override
  late final GeneratedColumn<int> updateAt = GeneratedColumn<int>(
    'update_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deleteAtMeta = const VerificationMeta(
    'deleteAt',
  );
  @override
  late final GeneratedColumn<int> deleteAt = GeneratedColumn<int>(
    'delete_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _editAtMeta = const VerificationMeta('editAt');
  @override
  late final GeneratedColumn<int> editAt = GeneratedColumn<int>(
    'edit_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _fileIdsJsonMeta = const VerificationMeta(
    'fileIdsJson',
  );
  @override
  late final GeneratedColumn<String> fileIdsJson = GeneratedColumn<String>(
    'file_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _filesJsonMeta = const VerificationMeta(
    'filesJson',
  );
  @override
  late final GeneratedColumn<String> filesJson = GeneratedColumn<String>(
    'files_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _replyCountMeta = const VerificationMeta(
    'replyCount',
  );
  @override
  late final GeneratedColumn<int> replyCount = GeneratedColumn<int>(
    'reply_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reactionsJsonMeta = const VerificationMeta(
    'reactionsJson',
  );
  @override
  late final GeneratedColumn<String> reactionsJson = GeneratedColumn<String>(
    'reactions_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _pendingIdMeta = const VerificationMeta(
    'pendingId',
  );
  @override
  late final GeneratedColumn<String> pendingId = GeneratedColumn<String>(
    'pending_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _isPendingMeta = const VerificationMeta(
    'isPending',
  );
  @override
  late final GeneratedColumn<bool> isPending = GeneratedColumn<bool>(
    'is_pending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pending" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sendStatusMeta = const VerificationMeta(
    'sendStatus',
  );
  @override
  late final GeneratedColumn<int> sendStatus = GeneratedColumn<int>(
    'send_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    channelId,
    userId,
    rootId,
    message,
    createAt,
    updateAt,
    deleteAt,
    editAt,
    type,
    metadataJson,
    fileIdsJson,
    filesJson,
    isPinned,
    replyCount,
    reactionsJson,
    pendingId,
    priority,
    isPending,
    sendStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'posts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Post> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(
        _channelIdMeta,
        channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta),
      );
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('root_id')) {
      context.handle(
        _rootIdMeta,
        rootId.isAcceptableOrUnknown(data['root_id']!, _rootIdMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('create_at')) {
      context.handle(
        _createAtMeta,
        createAt.isAcceptableOrUnknown(data['create_at']!, _createAtMeta),
      );
    }
    if (data.containsKey('update_at')) {
      context.handle(
        _updateAtMeta,
        updateAt.isAcceptableOrUnknown(data['update_at']!, _updateAtMeta),
      );
    }
    if (data.containsKey('delete_at')) {
      context.handle(
        _deleteAtMeta,
        deleteAt.isAcceptableOrUnknown(data['delete_at']!, _deleteAtMeta),
      );
    }
    if (data.containsKey('edit_at')) {
      context.handle(
        _editAtMeta,
        editAt.isAcceptableOrUnknown(data['edit_at']!, _editAtMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    if (data.containsKey('file_ids_json')) {
      context.handle(
        _fileIdsJsonMeta,
        fileIdsJson.isAcceptableOrUnknown(
          data['file_ids_json']!,
          _fileIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('files_json')) {
      context.handle(
        _filesJsonMeta,
        filesJson.isAcceptableOrUnknown(data['files_json']!, _filesJsonMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('reply_count')) {
      context.handle(
        _replyCountMeta,
        replyCount.isAcceptableOrUnknown(data['reply_count']!, _replyCountMeta),
      );
    }
    if (data.containsKey('reactions_json')) {
      context.handle(
        _reactionsJsonMeta,
        reactionsJson.isAcceptableOrUnknown(
          data['reactions_json']!,
          _reactionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('pending_id')) {
      context.handle(
        _pendingIdMeta,
        pendingId.isAcceptableOrUnknown(data['pending_id']!, _pendingIdMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('is_pending')) {
      context.handle(
        _isPendingMeta,
        isPending.isAcceptableOrUnknown(data['is_pending']!, _isPendingMeta),
      );
    }
    if (data.containsKey('send_status')) {
      context.handle(
        _sendStatusMeta,
        sendStatus.isAcceptableOrUnknown(data['send_status']!, _sendStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Post map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Post(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      channelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      rootId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}root_id'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      createAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}create_at'],
      )!,
      updateAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}update_at'],
      )!,
      deleteAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delete_at'],
      )!,
      editAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edit_at'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
      fileIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_ids_json'],
      )!,
      filesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}files_json'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      replyCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reply_count'],
      )!,
      reactionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reactions_json'],
      )!,
      pendingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pending_id'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      isPending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pending'],
      )!,
      sendStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}send_status'],
      )!,
    );
  }

  @override
  $PostsTable createAlias(String alias) {
    return $PostsTable(attachedDatabase, alias);
  }
}

class Post extends DataClass implements Insertable<Post> {
  final String id;
  final String channelId;
  final String userId;
  final String rootId;
  final String message;
  final int createAt;
  final int updateAt;
  final int deleteAt;
  final int editAt;
  final String type;
  final String metadataJson;
  final String fileIdsJson;
  final String filesJson;
  final bool isPinned;
  final int replyCount;
  final String reactionsJson;
  final String pendingId;
  final String priority;
  final bool isPending;
  final int sendStatus;
  const Post({
    required this.id,
    required this.channelId,
    required this.userId,
    required this.rootId,
    required this.message,
    required this.createAt,
    required this.updateAt,
    required this.deleteAt,
    required this.editAt,
    required this.type,
    required this.metadataJson,
    required this.fileIdsJson,
    required this.filesJson,
    required this.isPinned,
    required this.replyCount,
    required this.reactionsJson,
    required this.pendingId,
    required this.priority,
    required this.isPending,
    required this.sendStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['channel_id'] = Variable<String>(channelId);
    map['user_id'] = Variable<String>(userId);
    map['root_id'] = Variable<String>(rootId);
    map['message'] = Variable<String>(message);
    map['create_at'] = Variable<int>(createAt);
    map['update_at'] = Variable<int>(updateAt);
    map['delete_at'] = Variable<int>(deleteAt);
    map['edit_at'] = Variable<int>(editAt);
    map['type'] = Variable<String>(type);
    map['metadata_json'] = Variable<String>(metadataJson);
    map['file_ids_json'] = Variable<String>(fileIdsJson);
    map['files_json'] = Variable<String>(filesJson);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['reply_count'] = Variable<int>(replyCount);
    map['reactions_json'] = Variable<String>(reactionsJson);
    map['pending_id'] = Variable<String>(pendingId);
    map['priority'] = Variable<String>(priority);
    map['is_pending'] = Variable<bool>(isPending);
    map['send_status'] = Variable<int>(sendStatus);
    return map;
  }

  PostsCompanion toCompanion(bool nullToAbsent) {
    return PostsCompanion(
      id: Value(id),
      channelId: Value(channelId),
      userId: Value(userId),
      rootId: Value(rootId),
      message: Value(message),
      createAt: Value(createAt),
      updateAt: Value(updateAt),
      deleteAt: Value(deleteAt),
      editAt: Value(editAt),
      type: Value(type),
      metadataJson: Value(metadataJson),
      fileIdsJson: Value(fileIdsJson),
      filesJson: Value(filesJson),
      isPinned: Value(isPinned),
      replyCount: Value(replyCount),
      reactionsJson: Value(reactionsJson),
      pendingId: Value(pendingId),
      priority: Value(priority),
      isPending: Value(isPending),
      sendStatus: Value(sendStatus),
    );
  }

  factory Post.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Post(
      id: serializer.fromJson<String>(json['id']),
      channelId: serializer.fromJson<String>(json['channelId']),
      userId: serializer.fromJson<String>(json['userId']),
      rootId: serializer.fromJson<String>(json['rootId']),
      message: serializer.fromJson<String>(json['message']),
      createAt: serializer.fromJson<int>(json['createAt']),
      updateAt: serializer.fromJson<int>(json['updateAt']),
      deleteAt: serializer.fromJson<int>(json['deleteAt']),
      editAt: serializer.fromJson<int>(json['editAt']),
      type: serializer.fromJson<String>(json['type']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
      fileIdsJson: serializer.fromJson<String>(json['fileIdsJson']),
      filesJson: serializer.fromJson<String>(json['filesJson']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      replyCount: serializer.fromJson<int>(json['replyCount']),
      reactionsJson: serializer.fromJson<String>(json['reactionsJson']),
      pendingId: serializer.fromJson<String>(json['pendingId']),
      priority: serializer.fromJson<String>(json['priority']),
      isPending: serializer.fromJson<bool>(json['isPending']),
      sendStatus: serializer.fromJson<int>(json['sendStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'channelId': serializer.toJson<String>(channelId),
      'userId': serializer.toJson<String>(userId),
      'rootId': serializer.toJson<String>(rootId),
      'message': serializer.toJson<String>(message),
      'createAt': serializer.toJson<int>(createAt),
      'updateAt': serializer.toJson<int>(updateAt),
      'deleteAt': serializer.toJson<int>(deleteAt),
      'editAt': serializer.toJson<int>(editAt),
      'type': serializer.toJson<String>(type),
      'metadataJson': serializer.toJson<String>(metadataJson),
      'fileIdsJson': serializer.toJson<String>(fileIdsJson),
      'filesJson': serializer.toJson<String>(filesJson),
      'isPinned': serializer.toJson<bool>(isPinned),
      'replyCount': serializer.toJson<int>(replyCount),
      'reactionsJson': serializer.toJson<String>(reactionsJson),
      'pendingId': serializer.toJson<String>(pendingId),
      'priority': serializer.toJson<String>(priority),
      'isPending': serializer.toJson<bool>(isPending),
      'sendStatus': serializer.toJson<int>(sendStatus),
    };
  }

  Post copyWith({
    String? id,
    String? channelId,
    String? userId,
    String? rootId,
    String? message,
    int? createAt,
    int? updateAt,
    int? deleteAt,
    int? editAt,
    String? type,
    String? metadataJson,
    String? fileIdsJson,
    String? filesJson,
    bool? isPinned,
    int? replyCount,
    String? reactionsJson,
    String? pendingId,
    String? priority,
    bool? isPending,
    int? sendStatus,
  }) => Post(
    id: id ?? this.id,
    channelId: channelId ?? this.channelId,
    userId: userId ?? this.userId,
    rootId: rootId ?? this.rootId,
    message: message ?? this.message,
    createAt: createAt ?? this.createAt,
    updateAt: updateAt ?? this.updateAt,
    deleteAt: deleteAt ?? this.deleteAt,
    editAt: editAt ?? this.editAt,
    type: type ?? this.type,
    metadataJson: metadataJson ?? this.metadataJson,
    fileIdsJson: fileIdsJson ?? this.fileIdsJson,
    filesJson: filesJson ?? this.filesJson,
    isPinned: isPinned ?? this.isPinned,
    replyCount: replyCount ?? this.replyCount,
    reactionsJson: reactionsJson ?? this.reactionsJson,
    pendingId: pendingId ?? this.pendingId,
    priority: priority ?? this.priority,
    isPending: isPending ?? this.isPending,
    sendStatus: sendStatus ?? this.sendStatus,
  );
  Post copyWithCompanion(PostsCompanion data) {
    return Post(
      id: data.id.present ? data.id.value : this.id,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      userId: data.userId.present ? data.userId.value : this.userId,
      rootId: data.rootId.present ? data.rootId.value : this.rootId,
      message: data.message.present ? data.message.value : this.message,
      createAt: data.createAt.present ? data.createAt.value : this.createAt,
      updateAt: data.updateAt.present ? data.updateAt.value : this.updateAt,
      deleteAt: data.deleteAt.present ? data.deleteAt.value : this.deleteAt,
      editAt: data.editAt.present ? data.editAt.value : this.editAt,
      type: data.type.present ? data.type.value : this.type,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      fileIdsJson: data.fileIdsJson.present
          ? data.fileIdsJson.value
          : this.fileIdsJson,
      filesJson: data.filesJson.present ? data.filesJson.value : this.filesJson,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      replyCount: data.replyCount.present
          ? data.replyCount.value
          : this.replyCount,
      reactionsJson: data.reactionsJson.present
          ? data.reactionsJson.value
          : this.reactionsJson,
      pendingId: data.pendingId.present ? data.pendingId.value : this.pendingId,
      priority: data.priority.present ? data.priority.value : this.priority,
      isPending: data.isPending.present ? data.isPending.value : this.isPending,
      sendStatus: data.sendStatus.present
          ? data.sendStatus.value
          : this.sendStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Post(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('userId: $userId, ')
          ..write('rootId: $rootId, ')
          ..write('message: $message, ')
          ..write('createAt: $createAt, ')
          ..write('updateAt: $updateAt, ')
          ..write('deleteAt: $deleteAt, ')
          ..write('editAt: $editAt, ')
          ..write('type: $type, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('fileIdsJson: $fileIdsJson, ')
          ..write('filesJson: $filesJson, ')
          ..write('isPinned: $isPinned, ')
          ..write('replyCount: $replyCount, ')
          ..write('reactionsJson: $reactionsJson, ')
          ..write('pendingId: $pendingId, ')
          ..write('priority: $priority, ')
          ..write('isPending: $isPending, ')
          ..write('sendStatus: $sendStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    channelId,
    userId,
    rootId,
    message,
    createAt,
    updateAt,
    deleteAt,
    editAt,
    type,
    metadataJson,
    fileIdsJson,
    filesJson,
    isPinned,
    replyCount,
    reactionsJson,
    pendingId,
    priority,
    isPending,
    sendStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Post &&
          other.id == this.id &&
          other.channelId == this.channelId &&
          other.userId == this.userId &&
          other.rootId == this.rootId &&
          other.message == this.message &&
          other.createAt == this.createAt &&
          other.updateAt == this.updateAt &&
          other.deleteAt == this.deleteAt &&
          other.editAt == this.editAt &&
          other.type == this.type &&
          other.metadataJson == this.metadataJson &&
          other.fileIdsJson == this.fileIdsJson &&
          other.filesJson == this.filesJson &&
          other.isPinned == this.isPinned &&
          other.replyCount == this.replyCount &&
          other.reactionsJson == this.reactionsJson &&
          other.pendingId == this.pendingId &&
          other.priority == this.priority &&
          other.isPending == this.isPending &&
          other.sendStatus == this.sendStatus);
}

class PostsCompanion extends UpdateCompanion<Post> {
  final Value<String> id;
  final Value<String> channelId;
  final Value<String> userId;
  final Value<String> rootId;
  final Value<String> message;
  final Value<int> createAt;
  final Value<int> updateAt;
  final Value<int> deleteAt;
  final Value<int> editAt;
  final Value<String> type;
  final Value<String> metadataJson;
  final Value<String> fileIdsJson;
  final Value<String> filesJson;
  final Value<bool> isPinned;
  final Value<int> replyCount;
  final Value<String> reactionsJson;
  final Value<String> pendingId;
  final Value<String> priority;
  final Value<bool> isPending;
  final Value<int> sendStatus;
  final Value<int> rowid;
  const PostsCompanion({
    this.id = const Value.absent(),
    this.channelId = const Value.absent(),
    this.userId = const Value.absent(),
    this.rootId = const Value.absent(),
    this.message = const Value.absent(),
    this.createAt = const Value.absent(),
    this.updateAt = const Value.absent(),
    this.deleteAt = const Value.absent(),
    this.editAt = const Value.absent(),
    this.type = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.fileIdsJson = const Value.absent(),
    this.filesJson = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.replyCount = const Value.absent(),
    this.reactionsJson = const Value.absent(),
    this.pendingId = const Value.absent(),
    this.priority = const Value.absent(),
    this.isPending = const Value.absent(),
    this.sendStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PostsCompanion.insert({
    required String id,
    required String channelId,
    required String userId,
    this.rootId = const Value.absent(),
    this.message = const Value.absent(),
    this.createAt = const Value.absent(),
    this.updateAt = const Value.absent(),
    this.deleteAt = const Value.absent(),
    this.editAt = const Value.absent(),
    this.type = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.fileIdsJson = const Value.absent(),
    this.filesJson = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.replyCount = const Value.absent(),
    this.reactionsJson = const Value.absent(),
    this.pendingId = const Value.absent(),
    this.priority = const Value.absent(),
    this.isPending = const Value.absent(),
    this.sendStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       channelId = Value(channelId),
       userId = Value(userId);
  static Insertable<Post> custom({
    Expression<String>? id,
    Expression<String>? channelId,
    Expression<String>? userId,
    Expression<String>? rootId,
    Expression<String>? message,
    Expression<int>? createAt,
    Expression<int>? updateAt,
    Expression<int>? deleteAt,
    Expression<int>? editAt,
    Expression<String>? type,
    Expression<String>? metadataJson,
    Expression<String>? fileIdsJson,
    Expression<String>? filesJson,
    Expression<bool>? isPinned,
    Expression<int>? replyCount,
    Expression<String>? reactionsJson,
    Expression<String>? pendingId,
    Expression<String>? priority,
    Expression<bool>? isPending,
    Expression<int>? sendStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (userId != null) 'user_id': userId,
      if (rootId != null) 'root_id': rootId,
      if (message != null) 'message': message,
      if (createAt != null) 'create_at': createAt,
      if (updateAt != null) 'update_at': updateAt,
      if (deleteAt != null) 'delete_at': deleteAt,
      if (editAt != null) 'edit_at': editAt,
      if (type != null) 'type': type,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (fileIdsJson != null) 'file_ids_json': fileIdsJson,
      if (filesJson != null) 'files_json': filesJson,
      if (isPinned != null) 'is_pinned': isPinned,
      if (replyCount != null) 'reply_count': replyCount,
      if (reactionsJson != null) 'reactions_json': reactionsJson,
      if (pendingId != null) 'pending_id': pendingId,
      if (priority != null) 'priority': priority,
      if (isPending != null) 'is_pending': isPending,
      if (sendStatus != null) 'send_status': sendStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PostsCompanion copyWith({
    Value<String>? id,
    Value<String>? channelId,
    Value<String>? userId,
    Value<String>? rootId,
    Value<String>? message,
    Value<int>? createAt,
    Value<int>? updateAt,
    Value<int>? deleteAt,
    Value<int>? editAt,
    Value<String>? type,
    Value<String>? metadataJson,
    Value<String>? fileIdsJson,
    Value<String>? filesJson,
    Value<bool>? isPinned,
    Value<int>? replyCount,
    Value<String>? reactionsJson,
    Value<String>? pendingId,
    Value<String>? priority,
    Value<bool>? isPending,
    Value<int>? sendStatus,
    Value<int>? rowid,
  }) {
    return PostsCompanion(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      userId: userId ?? this.userId,
      rootId: rootId ?? this.rootId,
      message: message ?? this.message,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      deleteAt: deleteAt ?? this.deleteAt,
      editAt: editAt ?? this.editAt,
      type: type ?? this.type,
      metadataJson: metadataJson ?? this.metadataJson,
      fileIdsJson: fileIdsJson ?? this.fileIdsJson,
      filesJson: filesJson ?? this.filesJson,
      isPinned: isPinned ?? this.isPinned,
      replyCount: replyCount ?? this.replyCount,
      reactionsJson: reactionsJson ?? this.reactionsJson,
      pendingId: pendingId ?? this.pendingId,
      priority: priority ?? this.priority,
      isPending: isPending ?? this.isPending,
      sendStatus: sendStatus ?? this.sendStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (rootId.present) {
      map['root_id'] = Variable<String>(rootId.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (createAt.present) {
      map['create_at'] = Variable<int>(createAt.value);
    }
    if (updateAt.present) {
      map['update_at'] = Variable<int>(updateAt.value);
    }
    if (deleteAt.present) {
      map['delete_at'] = Variable<int>(deleteAt.value);
    }
    if (editAt.present) {
      map['edit_at'] = Variable<int>(editAt.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (fileIdsJson.present) {
      map['file_ids_json'] = Variable<String>(fileIdsJson.value);
    }
    if (filesJson.present) {
      map['files_json'] = Variable<String>(filesJson.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (replyCount.present) {
      map['reply_count'] = Variable<int>(replyCount.value);
    }
    if (reactionsJson.present) {
      map['reactions_json'] = Variable<String>(reactionsJson.value);
    }
    if (pendingId.present) {
      map['pending_id'] = Variable<String>(pendingId.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (isPending.present) {
      map['is_pending'] = Variable<bool>(isPending.value);
    }
    if (sendStatus.present) {
      map['send_status'] = Variable<int>(sendStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostsCompanion(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('userId: $userId, ')
          ..write('rootId: $rootId, ')
          ..write('message: $message, ')
          ..write('createAt: $createAt, ')
          ..write('updateAt: $updateAt, ')
          ..write('deleteAt: $deleteAt, ')
          ..write('editAt: $editAt, ')
          ..write('type: $type, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('fileIdsJson: $fileIdsJson, ')
          ..write('filesJson: $filesJson, ')
          ..write('isPinned: $isPinned, ')
          ..write('replyCount: $replyCount, ')
          ..write('reactionsJson: $reactionsJson, ')
          ..write('pendingId: $pendingId, ')
          ..write('priority: $priority, ')
          ..write('isPending: $isPending, ')
          ..write('sendStatus: $sendStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChannelsTable extends Channels with TableInfo<$ChannelsTable, Channel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _teamIdMeta = const VerificationMeta('teamId');
  @override
  late final GeneratedColumn<String> teamId = GeneratedColumn<String>(
    'team_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _headerMeta = const VerificationMeta('header');
  @override
  late final GeneratedColumn<String> header = GeneratedColumn<String>(
    'header',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _purposeMeta = const VerificationMeta(
    'purpose',
  );
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
    'purpose',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('O'),
  );
  static const VerificationMeta _createAtMeta = const VerificationMeta(
    'createAt',
  );
  @override
  late final GeneratedColumn<int> createAt = GeneratedColumn<int>(
    'create_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updateAtMeta = const VerificationMeta(
    'updateAt',
  );
  @override
  late final GeneratedColumn<int> updateAt = GeneratedColumn<int>(
    'update_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deleteAtMeta = const VerificationMeta(
    'deleteAt',
  );
  @override
  late final GeneratedColumn<int> deleteAt = GeneratedColumn<int>(
    'delete_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalMsgCountMeta = const VerificationMeta(
    'totalMsgCount',
  );
  @override
  late final GeneratedColumn<int> totalMsgCount = GeneratedColumn<int>(
    'total_msg_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPostAtMeta = const VerificationMeta(
    'lastPostAt',
  );
  @override
  late final GeneratedColumn<int> lastPostAt = GeneratedColumn<int>(
    'last_post_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalMsgCountRootMeta = const VerificationMeta(
    'totalMsgCountRoot',
  );
  @override
  late final GeneratedColumn<int> totalMsgCountRoot = GeneratedColumn<int>(
    'total_msg_count_root',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _msgCountRootMeta = const VerificationMeta(
    'msgCountRoot',
  );
  @override
  late final GeneratedColumn<int> msgCountRoot = GeneratedColumn<int>(
    'msg_count_root',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mentionCountRootMeta = const VerificationMeta(
    'mentionCountRoot',
  );
  @override
  late final GeneratedColumn<int> mentionCountRoot = GeneratedColumn<int>(
    'mention_count_root',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _urgentMentionCountMeta =
      const VerificationMeta('urgentMentionCount');
  @override
  late final GeneratedColumn<int> urgentMentionCount = GeneratedColumn<int>(
    'urgent_mention_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _msgCountMeta = const VerificationMeta(
    'msgCount',
  );
  @override
  late final GeneratedColumn<int> msgCount = GeneratedColumn<int>(
    'msg_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _mentionCountMeta = const VerificationMeta(
    'mentionCount',
  );
  @override
  late final GeneratedColumn<int> mentionCount = GeneratedColumn<int>(
    'mention_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastViewedAtMeta = const VerificationMeta(
    'lastViewedAt',
  );
  @override
  late final GeneratedColumn<int> lastViewedAt = GeneratedColumn<int>(
    'last_viewed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isMutedMeta = const VerificationMeta(
    'isMuted',
  );
  @override
  late final GeneratedColumn<bool> isMuted = GeneratedColumn<bool>(
    'is_muted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_muted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    teamId,
    name,
    displayName,
    header,
    purpose,
    type,
    createAt,
    updateAt,
    deleteAt,
    totalMsgCount,
    lastPostAt,
    totalMsgCountRoot,
    msgCountRoot,
    mentionCountRoot,
    urgentMentionCount,
    msgCount,
    mentionCount,
    lastViewedAt,
    isMuted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<Channel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('team_id')) {
      context.handle(
        _teamIdMeta,
        teamId.isAcceptableOrUnknown(data['team_id']!, _teamIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('header')) {
      context.handle(
        _headerMeta,
        header.isAcceptableOrUnknown(data['header']!, _headerMeta),
      );
    }
    if (data.containsKey('purpose')) {
      context.handle(
        _purposeMeta,
        purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('create_at')) {
      context.handle(
        _createAtMeta,
        createAt.isAcceptableOrUnknown(data['create_at']!, _createAtMeta),
      );
    }
    if (data.containsKey('update_at')) {
      context.handle(
        _updateAtMeta,
        updateAt.isAcceptableOrUnknown(data['update_at']!, _updateAtMeta),
      );
    }
    if (data.containsKey('delete_at')) {
      context.handle(
        _deleteAtMeta,
        deleteAt.isAcceptableOrUnknown(data['delete_at']!, _deleteAtMeta),
      );
    }
    if (data.containsKey('total_msg_count')) {
      context.handle(
        _totalMsgCountMeta,
        totalMsgCount.isAcceptableOrUnknown(
          data['total_msg_count']!,
          _totalMsgCountMeta,
        ),
      );
    }
    if (data.containsKey('last_post_at')) {
      context.handle(
        _lastPostAtMeta,
        lastPostAt.isAcceptableOrUnknown(
          data['last_post_at']!,
          _lastPostAtMeta,
        ),
      );
    }
    if (data.containsKey('total_msg_count_root')) {
      context.handle(
        _totalMsgCountRootMeta,
        totalMsgCountRoot.isAcceptableOrUnknown(
          data['total_msg_count_root']!,
          _totalMsgCountRootMeta,
        ),
      );
    }
    if (data.containsKey('msg_count_root')) {
      context.handle(
        _msgCountRootMeta,
        msgCountRoot.isAcceptableOrUnknown(
          data['msg_count_root']!,
          _msgCountRootMeta,
        ),
      );
    }
    if (data.containsKey('mention_count_root')) {
      context.handle(
        _mentionCountRootMeta,
        mentionCountRoot.isAcceptableOrUnknown(
          data['mention_count_root']!,
          _mentionCountRootMeta,
        ),
      );
    }
    if (data.containsKey('urgent_mention_count')) {
      context.handle(
        _urgentMentionCountMeta,
        urgentMentionCount.isAcceptableOrUnknown(
          data['urgent_mention_count']!,
          _urgentMentionCountMeta,
        ),
      );
    }
    if (data.containsKey('msg_count')) {
      context.handle(
        _msgCountMeta,
        msgCount.isAcceptableOrUnknown(data['msg_count']!, _msgCountMeta),
      );
    }
    if (data.containsKey('mention_count')) {
      context.handle(
        _mentionCountMeta,
        mentionCount.isAcceptableOrUnknown(
          data['mention_count']!,
          _mentionCountMeta,
        ),
      );
    }
    if (data.containsKey('last_viewed_at')) {
      context.handle(
        _lastViewedAtMeta,
        lastViewedAt.isAcceptableOrUnknown(
          data['last_viewed_at']!,
          _lastViewedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_muted')) {
      context.handle(
        _isMutedMeta,
        isMuted.isAcceptableOrUnknown(data['is_muted']!, _isMutedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Channel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Channel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      teamId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}team_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      header: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}header'],
      )!,
      purpose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purpose'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      createAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}create_at'],
      )!,
      updateAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}update_at'],
      )!,
      deleteAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delete_at'],
      )!,
      totalMsgCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_msg_count'],
      )!,
      lastPostAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_post_at'],
      )!,
      totalMsgCountRoot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_msg_count_root'],
      )!,
      msgCountRoot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}msg_count_root'],
      )!,
      mentionCountRoot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mention_count_root'],
      )!,
      urgentMentionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}urgent_mention_count'],
      )!,
      msgCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}msg_count'],
      )!,
      mentionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mention_count'],
      )!,
      lastViewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_viewed_at'],
      )!,
      isMuted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_muted'],
      )!,
    );
  }

  @override
  $ChannelsTable createAlias(String alias) {
    return $ChannelsTable(attachedDatabase, alias);
  }
}

class Channel extends DataClass implements Insertable<Channel> {
  final String id;
  final String teamId;
  final String name;
  final String displayName;
  final String header;
  final String purpose;
  final String type;
  final int createAt;
  final int updateAt;
  final int deleteAt;
  final int totalMsgCount;
  final int lastPostAt;
  final int totalMsgCountRoot;
  final int msgCountRoot;
  final int mentionCountRoot;
  final int urgentMentionCount;
  final int msgCount;
  final int mentionCount;
  final int lastViewedAt;
  final bool isMuted;
  const Channel({
    required this.id,
    required this.teamId,
    required this.name,
    required this.displayName,
    required this.header,
    required this.purpose,
    required this.type,
    required this.createAt,
    required this.updateAt,
    required this.deleteAt,
    required this.totalMsgCount,
    required this.lastPostAt,
    required this.totalMsgCountRoot,
    required this.msgCountRoot,
    required this.mentionCountRoot,
    required this.urgentMentionCount,
    required this.msgCount,
    required this.mentionCount,
    required this.lastViewedAt,
    required this.isMuted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['team_id'] = Variable<String>(teamId);
    map['name'] = Variable<String>(name);
    map['display_name'] = Variable<String>(displayName);
    map['header'] = Variable<String>(header);
    map['purpose'] = Variable<String>(purpose);
    map['type'] = Variable<String>(type);
    map['create_at'] = Variable<int>(createAt);
    map['update_at'] = Variable<int>(updateAt);
    map['delete_at'] = Variable<int>(deleteAt);
    map['total_msg_count'] = Variable<int>(totalMsgCount);
    map['last_post_at'] = Variable<int>(lastPostAt);
    map['total_msg_count_root'] = Variable<int>(totalMsgCountRoot);
    map['msg_count_root'] = Variable<int>(msgCountRoot);
    map['mention_count_root'] = Variable<int>(mentionCountRoot);
    map['urgent_mention_count'] = Variable<int>(urgentMentionCount);
    map['msg_count'] = Variable<int>(msgCount);
    map['mention_count'] = Variable<int>(mentionCount);
    map['last_viewed_at'] = Variable<int>(lastViewedAt);
    map['is_muted'] = Variable<bool>(isMuted);
    return map;
  }

  ChannelsCompanion toCompanion(bool nullToAbsent) {
    return ChannelsCompanion(
      id: Value(id),
      teamId: Value(teamId),
      name: Value(name),
      displayName: Value(displayName),
      header: Value(header),
      purpose: Value(purpose),
      type: Value(type),
      createAt: Value(createAt),
      updateAt: Value(updateAt),
      deleteAt: Value(deleteAt),
      totalMsgCount: Value(totalMsgCount),
      lastPostAt: Value(lastPostAt),
      totalMsgCountRoot: Value(totalMsgCountRoot),
      msgCountRoot: Value(msgCountRoot),
      mentionCountRoot: Value(mentionCountRoot),
      urgentMentionCount: Value(urgentMentionCount),
      msgCount: Value(msgCount),
      mentionCount: Value(mentionCount),
      lastViewedAt: Value(lastViewedAt),
      isMuted: Value(isMuted),
    );
  }

  factory Channel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Channel(
      id: serializer.fromJson<String>(json['id']),
      teamId: serializer.fromJson<String>(json['teamId']),
      name: serializer.fromJson<String>(json['name']),
      displayName: serializer.fromJson<String>(json['displayName']),
      header: serializer.fromJson<String>(json['header']),
      purpose: serializer.fromJson<String>(json['purpose']),
      type: serializer.fromJson<String>(json['type']),
      createAt: serializer.fromJson<int>(json['createAt']),
      updateAt: serializer.fromJson<int>(json['updateAt']),
      deleteAt: serializer.fromJson<int>(json['deleteAt']),
      totalMsgCount: serializer.fromJson<int>(json['totalMsgCount']),
      lastPostAt: serializer.fromJson<int>(json['lastPostAt']),
      totalMsgCountRoot: serializer.fromJson<int>(json['totalMsgCountRoot']),
      msgCountRoot: serializer.fromJson<int>(json['msgCountRoot']),
      mentionCountRoot: serializer.fromJson<int>(json['mentionCountRoot']),
      urgentMentionCount: serializer.fromJson<int>(json['urgentMentionCount']),
      msgCount: serializer.fromJson<int>(json['msgCount']),
      mentionCount: serializer.fromJson<int>(json['mentionCount']),
      lastViewedAt: serializer.fromJson<int>(json['lastViewedAt']),
      isMuted: serializer.fromJson<bool>(json['isMuted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'teamId': serializer.toJson<String>(teamId),
      'name': serializer.toJson<String>(name),
      'displayName': serializer.toJson<String>(displayName),
      'header': serializer.toJson<String>(header),
      'purpose': serializer.toJson<String>(purpose),
      'type': serializer.toJson<String>(type),
      'createAt': serializer.toJson<int>(createAt),
      'updateAt': serializer.toJson<int>(updateAt),
      'deleteAt': serializer.toJson<int>(deleteAt),
      'totalMsgCount': serializer.toJson<int>(totalMsgCount),
      'lastPostAt': serializer.toJson<int>(lastPostAt),
      'totalMsgCountRoot': serializer.toJson<int>(totalMsgCountRoot),
      'msgCountRoot': serializer.toJson<int>(msgCountRoot),
      'mentionCountRoot': serializer.toJson<int>(mentionCountRoot),
      'urgentMentionCount': serializer.toJson<int>(urgentMentionCount),
      'msgCount': serializer.toJson<int>(msgCount),
      'mentionCount': serializer.toJson<int>(mentionCount),
      'lastViewedAt': serializer.toJson<int>(lastViewedAt),
      'isMuted': serializer.toJson<bool>(isMuted),
    };
  }

  Channel copyWith({
    String? id,
    String? teamId,
    String? name,
    String? displayName,
    String? header,
    String? purpose,
    String? type,
    int? createAt,
    int? updateAt,
    int? deleteAt,
    int? totalMsgCount,
    int? lastPostAt,
    int? totalMsgCountRoot,
    int? msgCountRoot,
    int? mentionCountRoot,
    int? urgentMentionCount,
    int? msgCount,
    int? mentionCount,
    int? lastViewedAt,
    bool? isMuted,
  }) => Channel(
    id: id ?? this.id,
    teamId: teamId ?? this.teamId,
    name: name ?? this.name,
    displayName: displayName ?? this.displayName,
    header: header ?? this.header,
    purpose: purpose ?? this.purpose,
    type: type ?? this.type,
    createAt: createAt ?? this.createAt,
    updateAt: updateAt ?? this.updateAt,
    deleteAt: deleteAt ?? this.deleteAt,
    totalMsgCount: totalMsgCount ?? this.totalMsgCount,
    lastPostAt: lastPostAt ?? this.lastPostAt,
    totalMsgCountRoot: totalMsgCountRoot ?? this.totalMsgCountRoot,
    msgCountRoot: msgCountRoot ?? this.msgCountRoot,
    mentionCountRoot: mentionCountRoot ?? this.mentionCountRoot,
    urgentMentionCount: urgentMentionCount ?? this.urgentMentionCount,
    msgCount: msgCount ?? this.msgCount,
    mentionCount: mentionCount ?? this.mentionCount,
    lastViewedAt: lastViewedAt ?? this.lastViewedAt,
    isMuted: isMuted ?? this.isMuted,
  );
  Channel copyWithCompanion(ChannelsCompanion data) {
    return Channel(
      id: data.id.present ? data.id.value : this.id,
      teamId: data.teamId.present ? data.teamId.value : this.teamId,
      name: data.name.present ? data.name.value : this.name,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      header: data.header.present ? data.header.value : this.header,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
      type: data.type.present ? data.type.value : this.type,
      createAt: data.createAt.present ? data.createAt.value : this.createAt,
      updateAt: data.updateAt.present ? data.updateAt.value : this.updateAt,
      deleteAt: data.deleteAt.present ? data.deleteAt.value : this.deleteAt,
      totalMsgCount: data.totalMsgCount.present
          ? data.totalMsgCount.value
          : this.totalMsgCount,
      lastPostAt: data.lastPostAt.present
          ? data.lastPostAt.value
          : this.lastPostAt,
      totalMsgCountRoot: data.totalMsgCountRoot.present
          ? data.totalMsgCountRoot.value
          : this.totalMsgCountRoot,
      msgCountRoot: data.msgCountRoot.present
          ? data.msgCountRoot.value
          : this.msgCountRoot,
      mentionCountRoot: data.mentionCountRoot.present
          ? data.mentionCountRoot.value
          : this.mentionCountRoot,
      urgentMentionCount: data.urgentMentionCount.present
          ? data.urgentMentionCount.value
          : this.urgentMentionCount,
      msgCount: data.msgCount.present ? data.msgCount.value : this.msgCount,
      mentionCount: data.mentionCount.present
          ? data.mentionCount.value
          : this.mentionCount,
      lastViewedAt: data.lastViewedAt.present
          ? data.lastViewedAt.value
          : this.lastViewedAt,
      isMuted: data.isMuted.present ? data.isMuted.value : this.isMuted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Channel(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('header: $header, ')
          ..write('purpose: $purpose, ')
          ..write('type: $type, ')
          ..write('createAt: $createAt, ')
          ..write('updateAt: $updateAt, ')
          ..write('deleteAt: $deleteAt, ')
          ..write('totalMsgCount: $totalMsgCount, ')
          ..write('lastPostAt: $lastPostAt, ')
          ..write('totalMsgCountRoot: $totalMsgCountRoot, ')
          ..write('msgCountRoot: $msgCountRoot, ')
          ..write('mentionCountRoot: $mentionCountRoot, ')
          ..write('urgentMentionCount: $urgentMentionCount, ')
          ..write('msgCount: $msgCount, ')
          ..write('mentionCount: $mentionCount, ')
          ..write('lastViewedAt: $lastViewedAt, ')
          ..write('isMuted: $isMuted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    teamId,
    name,
    displayName,
    header,
    purpose,
    type,
    createAt,
    updateAt,
    deleteAt,
    totalMsgCount,
    lastPostAt,
    totalMsgCountRoot,
    msgCountRoot,
    mentionCountRoot,
    urgentMentionCount,
    msgCount,
    mentionCount,
    lastViewedAt,
    isMuted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Channel &&
          other.id == this.id &&
          other.teamId == this.teamId &&
          other.name == this.name &&
          other.displayName == this.displayName &&
          other.header == this.header &&
          other.purpose == this.purpose &&
          other.type == this.type &&
          other.createAt == this.createAt &&
          other.updateAt == this.updateAt &&
          other.deleteAt == this.deleteAt &&
          other.totalMsgCount == this.totalMsgCount &&
          other.lastPostAt == this.lastPostAt &&
          other.totalMsgCountRoot == this.totalMsgCountRoot &&
          other.msgCountRoot == this.msgCountRoot &&
          other.mentionCountRoot == this.mentionCountRoot &&
          other.urgentMentionCount == this.urgentMentionCount &&
          other.msgCount == this.msgCount &&
          other.mentionCount == this.mentionCount &&
          other.lastViewedAt == this.lastViewedAt &&
          other.isMuted == this.isMuted);
}

class ChannelsCompanion extends UpdateCompanion<Channel> {
  final Value<String> id;
  final Value<String> teamId;
  final Value<String> name;
  final Value<String> displayName;
  final Value<String> header;
  final Value<String> purpose;
  final Value<String> type;
  final Value<int> createAt;
  final Value<int> updateAt;
  final Value<int> deleteAt;
  final Value<int> totalMsgCount;
  final Value<int> lastPostAt;
  final Value<int> totalMsgCountRoot;
  final Value<int> msgCountRoot;
  final Value<int> mentionCountRoot;
  final Value<int> urgentMentionCount;
  final Value<int> msgCount;
  final Value<int> mentionCount;
  final Value<int> lastViewedAt;
  final Value<bool> isMuted;
  final Value<int> rowid;
  const ChannelsCompanion({
    this.id = const Value.absent(),
    this.teamId = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.header = const Value.absent(),
    this.purpose = const Value.absent(),
    this.type = const Value.absent(),
    this.createAt = const Value.absent(),
    this.updateAt = const Value.absent(),
    this.deleteAt = const Value.absent(),
    this.totalMsgCount = const Value.absent(),
    this.lastPostAt = const Value.absent(),
    this.totalMsgCountRoot = const Value.absent(),
    this.msgCountRoot = const Value.absent(),
    this.mentionCountRoot = const Value.absent(),
    this.urgentMentionCount = const Value.absent(),
    this.msgCount = const Value.absent(),
    this.mentionCount = const Value.absent(),
    this.lastViewedAt = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChannelsCompanion.insert({
    required String id,
    this.teamId = const Value.absent(),
    this.name = const Value.absent(),
    this.displayName = const Value.absent(),
    this.header = const Value.absent(),
    this.purpose = const Value.absent(),
    this.type = const Value.absent(),
    this.createAt = const Value.absent(),
    this.updateAt = const Value.absent(),
    this.deleteAt = const Value.absent(),
    this.totalMsgCount = const Value.absent(),
    this.lastPostAt = const Value.absent(),
    this.totalMsgCountRoot = const Value.absent(),
    this.msgCountRoot = const Value.absent(),
    this.mentionCountRoot = const Value.absent(),
    this.urgentMentionCount = const Value.absent(),
    this.msgCount = const Value.absent(),
    this.mentionCount = const Value.absent(),
    this.lastViewedAt = const Value.absent(),
    this.isMuted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Channel> custom({
    Expression<String>? id,
    Expression<String>? teamId,
    Expression<String>? name,
    Expression<String>? displayName,
    Expression<String>? header,
    Expression<String>? purpose,
    Expression<String>? type,
    Expression<int>? createAt,
    Expression<int>? updateAt,
    Expression<int>? deleteAt,
    Expression<int>? totalMsgCount,
    Expression<int>? lastPostAt,
    Expression<int>? totalMsgCountRoot,
    Expression<int>? msgCountRoot,
    Expression<int>? mentionCountRoot,
    Expression<int>? urgentMentionCount,
    Expression<int>? msgCount,
    Expression<int>? mentionCount,
    Expression<int>? lastViewedAt,
    Expression<bool>? isMuted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (teamId != null) 'team_id': teamId,
      if (name != null) 'name': name,
      if (displayName != null) 'display_name': displayName,
      if (header != null) 'header': header,
      if (purpose != null) 'purpose': purpose,
      if (type != null) 'type': type,
      if (createAt != null) 'create_at': createAt,
      if (updateAt != null) 'update_at': updateAt,
      if (deleteAt != null) 'delete_at': deleteAt,
      if (totalMsgCount != null) 'total_msg_count': totalMsgCount,
      if (lastPostAt != null) 'last_post_at': lastPostAt,
      if (totalMsgCountRoot != null) 'total_msg_count_root': totalMsgCountRoot,
      if (msgCountRoot != null) 'msg_count_root': msgCountRoot,
      if (mentionCountRoot != null) 'mention_count_root': mentionCountRoot,
      if (urgentMentionCount != null)
        'urgent_mention_count': urgentMentionCount,
      if (msgCount != null) 'msg_count': msgCount,
      if (mentionCount != null) 'mention_count': mentionCount,
      if (lastViewedAt != null) 'last_viewed_at': lastViewedAt,
      if (isMuted != null) 'is_muted': isMuted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChannelsCompanion copyWith({
    Value<String>? id,
    Value<String>? teamId,
    Value<String>? name,
    Value<String>? displayName,
    Value<String>? header,
    Value<String>? purpose,
    Value<String>? type,
    Value<int>? createAt,
    Value<int>? updateAt,
    Value<int>? deleteAt,
    Value<int>? totalMsgCount,
    Value<int>? lastPostAt,
    Value<int>? totalMsgCountRoot,
    Value<int>? msgCountRoot,
    Value<int>? mentionCountRoot,
    Value<int>? urgentMentionCount,
    Value<int>? msgCount,
    Value<int>? mentionCount,
    Value<int>? lastViewedAt,
    Value<bool>? isMuted,
    Value<int>? rowid,
  }) {
    return ChannelsCompanion(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      header: header ?? this.header,
      purpose: purpose ?? this.purpose,
      type: type ?? this.type,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      deleteAt: deleteAt ?? this.deleteAt,
      totalMsgCount: totalMsgCount ?? this.totalMsgCount,
      lastPostAt: lastPostAt ?? this.lastPostAt,
      totalMsgCountRoot: totalMsgCountRoot ?? this.totalMsgCountRoot,
      msgCountRoot: msgCountRoot ?? this.msgCountRoot,
      mentionCountRoot: mentionCountRoot ?? this.mentionCountRoot,
      urgentMentionCount: urgentMentionCount ?? this.urgentMentionCount,
      msgCount: msgCount ?? this.msgCount,
      mentionCount: mentionCount ?? this.mentionCount,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
      isMuted: isMuted ?? this.isMuted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (teamId.present) {
      map['team_id'] = Variable<String>(teamId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (header.present) {
      map['header'] = Variable<String>(header.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (createAt.present) {
      map['create_at'] = Variable<int>(createAt.value);
    }
    if (updateAt.present) {
      map['update_at'] = Variable<int>(updateAt.value);
    }
    if (deleteAt.present) {
      map['delete_at'] = Variable<int>(deleteAt.value);
    }
    if (totalMsgCount.present) {
      map['total_msg_count'] = Variable<int>(totalMsgCount.value);
    }
    if (lastPostAt.present) {
      map['last_post_at'] = Variable<int>(lastPostAt.value);
    }
    if (totalMsgCountRoot.present) {
      map['total_msg_count_root'] = Variable<int>(totalMsgCountRoot.value);
    }
    if (msgCountRoot.present) {
      map['msg_count_root'] = Variable<int>(msgCountRoot.value);
    }
    if (mentionCountRoot.present) {
      map['mention_count_root'] = Variable<int>(mentionCountRoot.value);
    }
    if (urgentMentionCount.present) {
      map['urgent_mention_count'] = Variable<int>(urgentMentionCount.value);
    }
    if (msgCount.present) {
      map['msg_count'] = Variable<int>(msgCount.value);
    }
    if (mentionCount.present) {
      map['mention_count'] = Variable<int>(mentionCount.value);
    }
    if (lastViewedAt.present) {
      map['last_viewed_at'] = Variable<int>(lastViewedAt.value);
    }
    if (isMuted.present) {
      map['is_muted'] = Variable<bool>(isMuted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelsCompanion(')
          ..write('id: $id, ')
          ..write('teamId: $teamId, ')
          ..write('name: $name, ')
          ..write('displayName: $displayName, ')
          ..write('header: $header, ')
          ..write('purpose: $purpose, ')
          ..write('type: $type, ')
          ..write('createAt: $createAt, ')
          ..write('updateAt: $updateAt, ')
          ..write('deleteAt: $deleteAt, ')
          ..write('totalMsgCount: $totalMsgCount, ')
          ..write('lastPostAt: $lastPostAt, ')
          ..write('totalMsgCountRoot: $totalMsgCountRoot, ')
          ..write('msgCountRoot: $msgCountRoot, ')
          ..write('mentionCountRoot: $mentionCountRoot, ')
          ..write('urgentMentionCount: $urgentMentionCount, ')
          ..write('msgCount: $msgCount, ')
          ..write('mentionCount: $mentionCount, ')
          ..write('lastViewedAt: $lastViewedAt, ')
          ..write('isMuted: $isMuted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _nicknameMeta = const VerificationMeta(
    'nickname',
  );
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
    'nickname',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<String> position = GeneratedColumn<String>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _localeMeta = const VerificationMeta('locale');
  @override
  late final GeneratedColumn<String> locale = GeneratedColumn<String>(
    'locale',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en'),
  );
  static const VerificationMeta _createAtMeta = const VerificationMeta(
    'createAt',
  );
  @override
  late final GeneratedColumn<int> createAt = GeneratedColumn<int>(
    'create_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updateAtMeta = const VerificationMeta(
    'updateAt',
  );
  @override
  late final GeneratedColumn<int> updateAt = GeneratedColumn<int>(
    'update_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deleteAtMeta = const VerificationMeta(
    'deleteAt',
  );
  @override
  late final GeneratedColumn<int> deleteAt = GeneratedColumn<int>(
    'delete_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('offline'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    username,
    email,
    firstName,
    lastName,
    nickname,
    position,
    locale,
    createAt,
    updateAt,
    deleteAt,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    }
    if (data.containsKey('nickname')) {
      context.handle(
        _nicknameMeta,
        nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('locale')) {
      context.handle(
        _localeMeta,
        locale.isAcceptableOrUnknown(data['locale']!, _localeMeta),
      );
    }
    if (data.containsKey('create_at')) {
      context.handle(
        _createAtMeta,
        createAt.isAcceptableOrUnknown(data['create_at']!, _createAtMeta),
      );
    }
    if (data.containsKey('update_at')) {
      context.handle(
        _updateAtMeta,
        updateAt.isAcceptableOrUnknown(data['update_at']!, _updateAtMeta),
      );
    }
    if (data.containsKey('delete_at')) {
      context.handle(
        _deleteAtMeta,
        deleteAt.isAcceptableOrUnknown(data['delete_at']!, _deleteAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      )!,
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      )!,
      nickname: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}position'],
      )!,
      locale: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locale'],
      )!,
      createAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}create_at'],
      )!,
      updateAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}update_at'],
      )!,
      deleteAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delete_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String nickname;
  final String position;
  final String locale;
  final int createAt;
  final int updateAt;
  final int deleteAt;
  final String status;
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.nickname,
    required this.position,
    required this.locale,
    required this.createAt,
    required this.updateAt,
    required this.deleteAt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['username'] = Variable<String>(username);
    map['email'] = Variable<String>(email);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    map['nickname'] = Variable<String>(nickname);
    map['position'] = Variable<String>(position);
    map['locale'] = Variable<String>(locale);
    map['create_at'] = Variable<int>(createAt);
    map['update_at'] = Variable<int>(updateAt);
    map['delete_at'] = Variable<int>(deleteAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      username: Value(username),
      email: Value(email),
      firstName: Value(firstName),
      lastName: Value(lastName),
      nickname: Value(nickname),
      position: Value(position),
      locale: Value(locale),
      createAt: Value(createAt),
      updateAt: Value(updateAt),
      deleteAt: Value(deleteAt),
      status: Value(status),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      email: serializer.fromJson<String>(json['email']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      nickname: serializer.fromJson<String>(json['nickname']),
      position: serializer.fromJson<String>(json['position']),
      locale: serializer.fromJson<String>(json['locale']),
      createAt: serializer.fromJson<int>(json['createAt']),
      updateAt: serializer.fromJson<int>(json['updateAt']),
      deleteAt: serializer.fromJson<int>(json['deleteAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'username': serializer.toJson<String>(username),
      'email': serializer.toJson<String>(email),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'nickname': serializer.toJson<String>(nickname),
      'position': serializer.toJson<String>(position),
      'locale': serializer.toJson<String>(locale),
      'createAt': serializer.toJson<int>(createAt),
      'updateAt': serializer.toJson<int>(updateAt),
      'deleteAt': serializer.toJson<int>(deleteAt),
      'status': serializer.toJson<String>(status),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? nickname,
    String? position,
    String? locale,
    int? createAt,
    int? updateAt,
    int? deleteAt,
    String? status,
  }) => User(
    id: id ?? this.id,
    username: username ?? this.username,
    email: email ?? this.email,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    nickname: nickname ?? this.nickname,
    position: position ?? this.position,
    locale: locale ?? this.locale,
    createAt: createAt ?? this.createAt,
    updateAt: updateAt ?? this.updateAt,
    deleteAt: deleteAt ?? this.deleteAt,
    status: status ?? this.status,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      email: data.email.present ? data.email.value : this.email,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
      position: data.position.present ? data.position.value : this.position,
      locale: data.locale.present ? data.locale.value : this.locale,
      createAt: data.createAt.present ? data.createAt.value : this.createAt,
      updateAt: data.updateAt.present ? data.updateAt.value : this.updateAt,
      deleteAt: data.deleteAt.present ? data.deleteAt.value : this.deleteAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('email: $email, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('nickname: $nickname, ')
          ..write('position: $position, ')
          ..write('locale: $locale, ')
          ..write('createAt: $createAt, ')
          ..write('updateAt: $updateAt, ')
          ..write('deleteAt: $deleteAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    username,
    email,
    firstName,
    lastName,
    nickname,
    position,
    locale,
    createAt,
    updateAt,
    deleteAt,
    status,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.username == this.username &&
          other.email == this.email &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.nickname == this.nickname &&
          other.position == this.position &&
          other.locale == this.locale &&
          other.createAt == this.createAt &&
          other.updateAt == this.updateAt &&
          other.deleteAt == this.deleteAt &&
          other.status == this.status);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> username;
  final Value<String> email;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String> nickname;
  final Value<String> position;
  final Value<String> locale;
  final Value<int> createAt;
  final Value<int> updateAt;
  final Value<int> deleteAt;
  final Value<String> status;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.email = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.nickname = const Value.absent(),
    this.position = const Value.absent(),
    this.locale = const Value.absent(),
    this.createAt = const Value.absent(),
    this.updateAt = const Value.absent(),
    this.deleteAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    this.username = const Value.absent(),
    this.email = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.nickname = const Value.absent(),
    this.position = const Value.absent(),
    this.locale = const Value.absent(),
    this.createAt = const Value.absent(),
    this.updateAt = const Value.absent(),
    this.deleteAt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? username,
    Expression<String>? email,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? nickname,
    Expression<String>? position,
    Expression<String>? locale,
    Expression<int>? createAt,
    Expression<int>? updateAt,
    Expression<int>? deleteAt,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (nickname != null) 'nickname': nickname,
      if (position != null) 'position': position,
      if (locale != null) 'locale': locale,
      if (createAt != null) 'create_at': createAt,
      if (updateAt != null) 'update_at': updateAt,
      if (deleteAt != null) 'delete_at': deleteAt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? username,
    Value<String>? email,
    Value<String>? firstName,
    Value<String>? lastName,
    Value<String>? nickname,
    Value<String>? position,
    Value<String>? locale,
    Value<int>? createAt,
    Value<int>? updateAt,
    Value<int>? deleteAt,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nickname: nickname ?? this.nickname,
      position: position ?? this.position,
      locale: locale ?? this.locale,
      createAt: createAt ?? this.createAt,
      updateAt: updateAt ?? this.updateAt,
      deleteAt: deleteAt ?? this.deleteAt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    if (position.present) {
      map['position'] = Variable<String>(position.value);
    }
    if (locale.present) {
      map['locale'] = Variable<String>(locale.value);
    }
    if (createAt.present) {
      map['create_at'] = Variable<int>(createAt.value);
    }
    if (updateAt.present) {
      map['update_at'] = Variable<int>(updateAt.value);
    }
    if (deleteAt.present) {
      map['delete_at'] = Variable<int>(deleteAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('email: $email, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('nickname: $nickname, ')
          ..write('position: $position, ')
          ..write('locale: $locale, ')
          ..write('createAt: $createAt, ')
          ..write('updateAt: $updateAt, ')
          ..write('deleteAt: $deleteAt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PostsTable posts = $PostsTable(this);
  late final $ChannelsTable channels = $ChannelsTable(this);
  late final $UsersTable users = $UsersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [posts, channels, users];
}

typedef $$PostsTableCreateCompanionBuilder =
    PostsCompanion Function({
      required String id,
      required String channelId,
      required String userId,
      Value<String> rootId,
      Value<String> message,
      Value<int> createAt,
      Value<int> updateAt,
      Value<int> deleteAt,
      Value<int> editAt,
      Value<String> type,
      Value<String> metadataJson,
      Value<String> fileIdsJson,
      Value<String> filesJson,
      Value<bool> isPinned,
      Value<int> replyCount,
      Value<String> reactionsJson,
      Value<String> pendingId,
      Value<String> priority,
      Value<bool> isPending,
      Value<int> sendStatus,
      Value<int> rowid,
    });
typedef $$PostsTableUpdateCompanionBuilder =
    PostsCompanion Function({
      Value<String> id,
      Value<String> channelId,
      Value<String> userId,
      Value<String> rootId,
      Value<String> message,
      Value<int> createAt,
      Value<int> updateAt,
      Value<int> deleteAt,
      Value<int> editAt,
      Value<String> type,
      Value<String> metadataJson,
      Value<String> fileIdsJson,
      Value<String> filesJson,
      Value<bool> isPinned,
      Value<int> replyCount,
      Value<String> reactionsJson,
      Value<String> pendingId,
      Value<String> priority,
      Value<bool> isPending,
      Value<int> sendStatus,
      Value<int> rowid,
    });

class $$PostsTableFilterComposer extends Composer<_$AppDatabase, $PostsTable> {
  $$PostsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rootId => $composableBuilder(
    column: $table.rootId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createAt => $composableBuilder(
    column: $table.createAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updateAt => $composableBuilder(
    column: $table.updateAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deleteAt => $composableBuilder(
    column: $table.deleteAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editAt => $composableBuilder(
    column: $table.editAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileIdsJson => $composableBuilder(
    column: $table.fileIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filesJson => $composableBuilder(
    column: $table.filesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get replyCount => $composableBuilder(
    column: $table.replyCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reactionsJson => $composableBuilder(
    column: $table.reactionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pendingId => $composableBuilder(
    column: $table.pendingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPending => $composableBuilder(
    column: $table.isPending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sendStatus => $composableBuilder(
    column: $table.sendStatus,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PostsTableOrderingComposer
    extends Composer<_$AppDatabase, $PostsTable> {
  $$PostsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelId => $composableBuilder(
    column: $table.channelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rootId => $composableBuilder(
    column: $table.rootId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createAt => $composableBuilder(
    column: $table.createAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updateAt => $composableBuilder(
    column: $table.updateAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deleteAt => $composableBuilder(
    column: $table.deleteAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editAt => $composableBuilder(
    column: $table.editAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileIdsJson => $composableBuilder(
    column: $table.fileIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filesJson => $composableBuilder(
    column: $table.filesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get replyCount => $composableBuilder(
    column: $table.replyCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reactionsJson => $composableBuilder(
    column: $table.reactionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pendingId => $composableBuilder(
    column: $table.pendingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPending => $composableBuilder(
    column: $table.isPending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sendStatus => $composableBuilder(
    column: $table.sendStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PostsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PostsTable> {
  $$PostsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get rootId =>
      $composableBuilder(column: $table.rootId, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get createAt =>
      $composableBuilder(column: $table.createAt, builder: (column) => column);

  GeneratedColumn<int> get updateAt =>
      $composableBuilder(column: $table.updateAt, builder: (column) => column);

  GeneratedColumn<int> get deleteAt =>
      $composableBuilder(column: $table.deleteAt, builder: (column) => column);

  GeneratedColumn<int> get editAt =>
      $composableBuilder(column: $table.editAt, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileIdsJson => $composableBuilder(
    column: $table.fileIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get filesJson =>
      $composableBuilder(column: $table.filesJson, builder: (column) => column);

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<int> get replyCount => $composableBuilder(
    column: $table.replyCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reactionsJson => $composableBuilder(
    column: $table.reactionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pendingId =>
      $composableBuilder(column: $table.pendingId, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<bool> get isPending =>
      $composableBuilder(column: $table.isPending, builder: (column) => column);

  GeneratedColumn<int> get sendStatus => $composableBuilder(
    column: $table.sendStatus,
    builder: (column) => column,
  );
}

class $$PostsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PostsTable,
          Post,
          $$PostsTableFilterComposer,
          $$PostsTableOrderingComposer,
          $$PostsTableAnnotationComposer,
          $$PostsTableCreateCompanionBuilder,
          $$PostsTableUpdateCompanionBuilder,
          (Post, BaseReferences<_$AppDatabase, $PostsTable, Post>),
          Post,
          PrefetchHooks Function()
        > {
  $$PostsTableTableManager(_$AppDatabase db, $PostsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PostsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PostsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PostsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> channelId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> rootId = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<int> createAt = const Value.absent(),
                Value<int> updateAt = const Value.absent(),
                Value<int> deleteAt = const Value.absent(),
                Value<int> editAt = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<String> fileIdsJson = const Value.absent(),
                Value<String> filesJson = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> replyCount = const Value.absent(),
                Value<String> reactionsJson = const Value.absent(),
                Value<String> pendingId = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<bool> isPending = const Value.absent(),
                Value<int> sendStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PostsCompanion(
                id: id,
                channelId: channelId,
                userId: userId,
                rootId: rootId,
                message: message,
                createAt: createAt,
                updateAt: updateAt,
                deleteAt: deleteAt,
                editAt: editAt,
                type: type,
                metadataJson: metadataJson,
                fileIdsJson: fileIdsJson,
                filesJson: filesJson,
                isPinned: isPinned,
                replyCount: replyCount,
                reactionsJson: reactionsJson,
                pendingId: pendingId,
                priority: priority,
                isPending: isPending,
                sendStatus: sendStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String channelId,
                required String userId,
                Value<String> rootId = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<int> createAt = const Value.absent(),
                Value<int> updateAt = const Value.absent(),
                Value<int> deleteAt = const Value.absent(),
                Value<int> editAt = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<String> fileIdsJson = const Value.absent(),
                Value<String> filesJson = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<int> replyCount = const Value.absent(),
                Value<String> reactionsJson = const Value.absent(),
                Value<String> pendingId = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<bool> isPending = const Value.absent(),
                Value<int> sendStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PostsCompanion.insert(
                id: id,
                channelId: channelId,
                userId: userId,
                rootId: rootId,
                message: message,
                createAt: createAt,
                updateAt: updateAt,
                deleteAt: deleteAt,
                editAt: editAt,
                type: type,
                metadataJson: metadataJson,
                fileIdsJson: fileIdsJson,
                filesJson: filesJson,
                isPinned: isPinned,
                replyCount: replyCount,
                reactionsJson: reactionsJson,
                pendingId: pendingId,
                priority: priority,
                isPending: isPending,
                sendStatus: sendStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PostsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PostsTable,
      Post,
      $$PostsTableFilterComposer,
      $$PostsTableOrderingComposer,
      $$PostsTableAnnotationComposer,
      $$PostsTableCreateCompanionBuilder,
      $$PostsTableUpdateCompanionBuilder,
      (Post, BaseReferences<_$AppDatabase, $PostsTable, Post>),
      Post,
      PrefetchHooks Function()
    >;
typedef $$ChannelsTableCreateCompanionBuilder =
    ChannelsCompanion Function({
      required String id,
      Value<String> teamId,
      Value<String> name,
      Value<String> displayName,
      Value<String> header,
      Value<String> purpose,
      Value<String> type,
      Value<int> createAt,
      Value<int> updateAt,
      Value<int> deleteAt,
      Value<int> totalMsgCount,
      Value<int> lastPostAt,
      Value<int> totalMsgCountRoot,
      Value<int> msgCountRoot,
      Value<int> mentionCountRoot,
      Value<int> urgentMentionCount,
      Value<int> msgCount,
      Value<int> mentionCount,
      Value<int> lastViewedAt,
      Value<bool> isMuted,
      Value<int> rowid,
    });
typedef $$ChannelsTableUpdateCompanionBuilder =
    ChannelsCompanion Function({
      Value<String> id,
      Value<String> teamId,
      Value<String> name,
      Value<String> displayName,
      Value<String> header,
      Value<String> purpose,
      Value<String> type,
      Value<int> createAt,
      Value<int> updateAt,
      Value<int> deleteAt,
      Value<int> totalMsgCount,
      Value<int> lastPostAt,
      Value<int> totalMsgCountRoot,
      Value<int> msgCountRoot,
      Value<int> mentionCountRoot,
      Value<int> urgentMentionCount,
      Value<int> msgCount,
      Value<int> mentionCount,
      Value<int> lastViewedAt,
      Value<bool> isMuted,
      Value<int> rowid,
    });

class $$ChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get header => $composableBuilder(
    column: $table.header,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createAt => $composableBuilder(
    column: $table.createAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updateAt => $composableBuilder(
    column: $table.updateAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deleteAt => $composableBuilder(
    column: $table.deleteAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalMsgCount => $composableBuilder(
    column: $table.totalMsgCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastPostAt => $composableBuilder(
    column: $table.lastPostAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalMsgCountRoot => $composableBuilder(
    column: $table.totalMsgCountRoot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get msgCountRoot => $composableBuilder(
    column: $table.msgCountRoot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mentionCountRoot => $composableBuilder(
    column: $table.mentionCountRoot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get urgentMentionCount => $composableBuilder(
    column: $table.urgentMentionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get msgCount => $composableBuilder(
    column: $table.msgCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mentionCount => $composableBuilder(
    column: $table.mentionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastViewedAt => $composableBuilder(
    column: $table.lastViewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teamId => $composableBuilder(
    column: $table.teamId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get header => $composableBuilder(
    column: $table.header,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createAt => $composableBuilder(
    column: $table.createAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updateAt => $composableBuilder(
    column: $table.updateAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deleteAt => $composableBuilder(
    column: $table.deleteAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMsgCount => $composableBuilder(
    column: $table.totalMsgCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastPostAt => $composableBuilder(
    column: $table.lastPostAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMsgCountRoot => $composableBuilder(
    column: $table.totalMsgCountRoot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get msgCountRoot => $composableBuilder(
    column: $table.msgCountRoot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mentionCountRoot => $composableBuilder(
    column: $table.mentionCountRoot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get urgentMentionCount => $composableBuilder(
    column: $table.urgentMentionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get msgCount => $composableBuilder(
    column: $table.msgCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mentionCount => $composableBuilder(
    column: $table.mentionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastViewedAt => $composableBuilder(
    column: $table.lastViewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMuted => $composableBuilder(
    column: $table.isMuted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get teamId =>
      $composableBuilder(column: $table.teamId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get header =>
      $composableBuilder(column: $table.header, builder: (column) => column);

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get createAt =>
      $composableBuilder(column: $table.createAt, builder: (column) => column);

  GeneratedColumn<int> get updateAt =>
      $composableBuilder(column: $table.updateAt, builder: (column) => column);

  GeneratedColumn<int> get deleteAt =>
      $composableBuilder(column: $table.deleteAt, builder: (column) => column);

  GeneratedColumn<int> get totalMsgCount => $composableBuilder(
    column: $table.totalMsgCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastPostAt => $composableBuilder(
    column: $table.lastPostAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalMsgCountRoot => $composableBuilder(
    column: $table.totalMsgCountRoot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get msgCountRoot => $composableBuilder(
    column: $table.msgCountRoot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mentionCountRoot => $composableBuilder(
    column: $table.mentionCountRoot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get urgentMentionCount => $composableBuilder(
    column: $table.urgentMentionCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get msgCount =>
      $composableBuilder(column: $table.msgCount, builder: (column) => column);

  GeneratedColumn<int> get mentionCount => $composableBuilder(
    column: $table.mentionCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastViewedAt => $composableBuilder(
    column: $table.lastViewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isMuted =>
      $composableBuilder(column: $table.isMuted, builder: (column) => column);
}

class $$ChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelsTable,
          Channel,
          $$ChannelsTableFilterComposer,
          $$ChannelsTableOrderingComposer,
          $$ChannelsTableAnnotationComposer,
          $$ChannelsTableCreateCompanionBuilder,
          $$ChannelsTableUpdateCompanionBuilder,
          (Channel, BaseReferences<_$AppDatabase, $ChannelsTable, Channel>),
          Channel,
          PrefetchHooks Function()
        > {
  $$ChannelsTableTableManager(_$AppDatabase db, $ChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> teamId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> header = const Value.absent(),
                Value<String> purpose = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> createAt = const Value.absent(),
                Value<int> updateAt = const Value.absent(),
                Value<int> deleteAt = const Value.absent(),
                Value<int> totalMsgCount = const Value.absent(),
                Value<int> lastPostAt = const Value.absent(),
                Value<int> totalMsgCountRoot = const Value.absent(),
                Value<int> msgCountRoot = const Value.absent(),
                Value<int> mentionCountRoot = const Value.absent(),
                Value<int> urgentMentionCount = const Value.absent(),
                Value<int> msgCount = const Value.absent(),
                Value<int> mentionCount = const Value.absent(),
                Value<int> lastViewedAt = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelsCompanion(
                id: id,
                teamId: teamId,
                name: name,
                displayName: displayName,
                header: header,
                purpose: purpose,
                type: type,
                createAt: createAt,
                updateAt: updateAt,
                deleteAt: deleteAt,
                totalMsgCount: totalMsgCount,
                lastPostAt: lastPostAt,
                totalMsgCountRoot: totalMsgCountRoot,
                msgCountRoot: msgCountRoot,
                mentionCountRoot: mentionCountRoot,
                urgentMentionCount: urgentMentionCount,
                msgCount: msgCount,
                mentionCount: mentionCount,
                lastViewedAt: lastViewedAt,
                isMuted: isMuted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> teamId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> header = const Value.absent(),
                Value<String> purpose = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> createAt = const Value.absent(),
                Value<int> updateAt = const Value.absent(),
                Value<int> deleteAt = const Value.absent(),
                Value<int> totalMsgCount = const Value.absent(),
                Value<int> lastPostAt = const Value.absent(),
                Value<int> totalMsgCountRoot = const Value.absent(),
                Value<int> msgCountRoot = const Value.absent(),
                Value<int> mentionCountRoot = const Value.absent(),
                Value<int> urgentMentionCount = const Value.absent(),
                Value<int> msgCount = const Value.absent(),
                Value<int> mentionCount = const Value.absent(),
                Value<int> lastViewedAt = const Value.absent(),
                Value<bool> isMuted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelsCompanion.insert(
                id: id,
                teamId: teamId,
                name: name,
                displayName: displayName,
                header: header,
                purpose: purpose,
                type: type,
                createAt: createAt,
                updateAt: updateAt,
                deleteAt: deleteAt,
                totalMsgCount: totalMsgCount,
                lastPostAt: lastPostAt,
                totalMsgCountRoot: totalMsgCountRoot,
                msgCountRoot: msgCountRoot,
                mentionCountRoot: mentionCountRoot,
                urgentMentionCount: urgentMentionCount,
                msgCount: msgCount,
                mentionCount: mentionCount,
                lastViewedAt: lastViewedAt,
                isMuted: isMuted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelsTable,
      Channel,
      $$ChannelsTableFilterComposer,
      $$ChannelsTableOrderingComposer,
      $$ChannelsTableAnnotationComposer,
      $$ChannelsTableCreateCompanionBuilder,
      $$ChannelsTableUpdateCompanionBuilder,
      (Channel, BaseReferences<_$AppDatabase, $ChannelsTable, Channel>),
      Channel,
      PrefetchHooks Function()
    >;
typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String id,
      Value<String> username,
      Value<String> email,
      Value<String> firstName,
      Value<String> lastName,
      Value<String> nickname,
      Value<String> position,
      Value<String> locale,
      Value<int> createAt,
      Value<int> updateAt,
      Value<int> deleteAt,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      Value<String> username,
      Value<String> email,
      Value<String> firstName,
      Value<String> lastName,
      Value<String> nickname,
      Value<String> position,
      Value<String> locale,
      Value<int> createAt,
      Value<int> updateAt,
      Value<int> deleteAt,
      Value<String> status,
      Value<int> rowid,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createAt => $composableBuilder(
    column: $table.createAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updateAt => $composableBuilder(
    column: $table.updateAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deleteAt => $composableBuilder(
    column: $table.deleteAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nickname => $composableBuilder(
    column: $table.nickname,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locale => $composableBuilder(
    column: $table.locale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createAt => $composableBuilder(
    column: $table.createAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updateAt => $composableBuilder(
    column: $table.updateAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deleteAt => $composableBuilder(
    column: $table.deleteAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  GeneratedColumn<String> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get locale =>
      $composableBuilder(column: $table.locale, builder: (column) => column);

  GeneratedColumn<int> get createAt =>
      $composableBuilder(column: $table.createAt, builder: (column) => column);

  GeneratedColumn<int> get updateAt =>
      $composableBuilder(column: $table.updateAt, builder: (column) => column);

  GeneratedColumn<int> get deleteAt =>
      $composableBuilder(column: $table.deleteAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<String> position = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<int> createAt = const Value.absent(),
                Value<int> updateAt = const Value.absent(),
                Value<int> deleteAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                username: username,
                email: email,
                firstName: firstName,
                lastName: lastName,
                nickname: nickname,
                position: position,
                locale: locale,
                createAt: createAt,
                updateAt: updateAt,
                deleteAt: deleteAt,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> username = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> firstName = const Value.absent(),
                Value<String> lastName = const Value.absent(),
                Value<String> nickname = const Value.absent(),
                Value<String> position = const Value.absent(),
                Value<String> locale = const Value.absent(),
                Value<int> createAt = const Value.absent(),
                Value<int> updateAt = const Value.absent(),
                Value<int> deleteAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                username: username,
                email: email,
                firstName: firstName,
                lastName: lastName,
                nickname: nickname,
                position: position,
                locale: locale,
                createAt: createAt,
                updateAt: updateAt,
                deleteAt: deleteAt,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PostsTableTableManager get posts =>
      $$PostsTableTableManager(_db, _db.posts);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db, _db.channels);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
}
