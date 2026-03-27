import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/custom_emoji_cache.dart';
import '../../../../core/utils/emoji_map.dart';
import '../../../../domain/entities/post.dart';
import '../../../../domain/entities/slash_command.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/draft.dart';
import '../../../../domain/entities/user.dart';
import 'emoji_autocomplete.dart';
import 'emoji_picker_sheet.dart';
import 'mention_autocomplete.dart';
import 'slash_command_autocomplete.dart';

class MessageInput extends StatefulWidget {
  final String channelId;
  final String channelName;
  final String? initialDraft;
  final void Function(
    String message, {
    List<String>? fileIds,
    String? priority,
  }) onSend;
  final Post? editingPost;
  final VoidCallback? onCancelEdit;
  final void Function(String postId, String message)? onSaveEdit;
  final Post? forwardingPost;
  final VoidCallback? onCancelForward;

  const MessageInput({
    super.key,
    required this.channelId,
    this.channelName = '',
    this.initialDraft,
    required this.onSend,
    this.editingPost,
    this.onCancelEdit,
    this.onSaveEdit,
    this.forwardingPost,
    this.onCancelForward,
  });

  @override
  State<MessageInput> createState() => MessageInputState();
}

class MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final List<String> _pendingFileIds = [];
  final List<String> _pendingFileNames = [];
  bool _isUploading = false;
  Timer? _draftTimer;
  final _draftStorage = currentSession.draftStorage;

  // Edit mode
  String? _savedDraftText;
  bool get _isEditing => widget.editingPost != null;

  bool get _isForwarding => widget.forwardingPost != null;

  // Priority
  String? _selectedPriority;
  bool _showPriorityBar = false;

  // Mentions
  List<MentionItem> _mentionItems = [];
  bool _showMentions = false;
  bool _suppressMentionCheck = false;
  Timer? _mentionDebounce;
  late final _userRepository = currentSession.userRepository;
  final LayerLink _mentionLayerLink = LayerLink();
  OverlayEntry? _mentionOverlay;
  Set<String> _channelMemberIds = {};

  // Emoji autocomplete
  List<EmojiAutocompleteItem> _emojiResults = [];
  bool _showEmojis = false;
  bool _suppressEmojiCheck = false;
  Timer? _emojiDebounce;
  final LayerLink _emojiLayerLink = LayerLink();
  OverlayEntry? _emojiOverlay;
  Map<String, String>? _authHeaders;
  List<String> _recentEmojis = [];

  // Slash commands
  List<SlashCommand> _commandResults = [];
  bool _showCommands = false;
  bool _suppressCommandCheck = false;
  Timer? _commandDebounce;
  late final _postRepository = currentSession.postRepository;
  final LayerLink _commandLayerLink = LayerLink();
  OverlayEntry? _commandOverlay;
  List<SlashCommand>? _cachedCommands;

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _loadAuthHeaders();
    _loadRecentEmojis();
    CustomEmojiCache.ensureLoaded();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  Future<void> _loadAuthHeaders() async {
    final token = await currentSession.getAuthToken();
    if (mounted) {
      _authHeaders = {
        if (token != null) 'Authorization': 'Bearer $token',
      };
    }
  }

  Future<void> _loadRecentEmojis() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      _recentEmojis = prefs.getStringList('recent_emojis_${currentSession.accountId}') ?? [];
    }
  }

  @override
  void didUpdateWidget(covariant MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingPost != null && oldWidget.editingPost == null) {
      _savedDraftText = _controller.text;
      _controller.text = widget.editingPost!.message;
      _focusNode.requestFocus();
    } else if (widget.editingPost == null && oldWidget.editingPost != null) {
      _controller.text = _savedDraftText ?? '';
      _savedDraftText = null;
    }
  }

  Future<void> _loadDraft() async {
    if (widget.initialDraft != null && widget.initialDraft!.isNotEmpty) {
      _controller.text = widget.initialDraft!;
      return;
    }
    final draft = await _draftStorage.getDraft(widget.channelId);
    if (draft != null && mounted) {
      _controller.text = draft.message;
    }
  }

  void _onTextChanged() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 500), _saveDraft);
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _showMentions = false;
      _mentionItems = [];
      _updateMentionOverlay();
      _showCommands = false;
      _commandResults = [];
      _updateCommandOverlay();
      _showEmojis = false;
      _emojiResults = [];
      _updateEmojiOverlay();
    }
  }

  // ===== Mention autocomplete =====

  String? _getMentionQuery() {
    final text = _controller.text;
    if (text.isEmpty) return null;

    final selection = _controller.selection;
    final cursorPos = (selection.isValid && selection.isCollapsed)
        ? selection.baseOffset
        : text.length;
    if (cursorPos <= 0 || cursorPos > text.length) return null;

    final textBeforeCursor = text.substring(0, cursorPos);

    final atIndex = textBeforeCursor.lastIndexOf('@');
    if (atIndex < 0) return null;
    if (atIndex > 0 &&
        textBeforeCursor[atIndex - 1] != ' ' &&
        textBeforeCursor[atIndex - 1] != '\n') {
      return null;
    }

    final query = textBeforeCursor.substring(atIndex + 1);
    if (query.contains(' ') || query.contains('\n')) {
      return null;
    }

    return query;
  }

  static const _specialMentions = [
    MentionItem.special(
      specialMention: 'all',
      specialDescription: 'Notify everyone in the channel',
    ),
    MentionItem.special(
      specialMention: 'channel',
      specialDescription: 'Notify everyone in the channel',
    ),
    MentionItem.special(
      specialMention: 'here',
      specialDescription: 'Notify everyone who is online',
    ),
  ];

  void _checkForMention() {
    if (_suppressMentionCheck) return;
    final query = _getMentionQuery();
    if (query == null) {
      if (_showMentions) {
        _showMentions = false;
        _mentionItems = [];
        _updateMentionOverlay();
      }
      _mentionDebounce?.cancel();
      return;
    }

    _mentionDebounce?.cancel();
    _mentionDebounce = Timer(const Duration(milliseconds: 300), () {
      _fetchMentions(query);
    });
  }

  Future<void> _fetchMentions(String query) async {
    if (query.isEmpty) {
      // Empty query: show special mentions + channel members
      final result = await currentSession.channelRepository.getChannelMembers(
        widget.channelId,
      );
      if (!mounted) return;
      result.fold(
        (failure) {
          _mentionItems = List.of(_specialMentions);
          _channelMemberIds = {};
        },
        (members) {
          _channelMemberIds = members.map((m) => m.user.id).toSet();
          _mentionItems = [
            ..._specialMentions,
            ...members.map((m) => MentionItem.user(m.user)),
          ];
        },
      );
      _showMentions = _mentionItems.isNotEmpty;
      _updateMentionOverlay();
      return;
    }

    // Filter special mentions by query
    final matchingSpecials = _specialMentions
        .where((s) => s.specialMention!.startsWith(query.toLowerCase()))
        .toList();

    // Search server-wide
    String? teamId;
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) teamId = authState.teamId;

    final result = await _userRepository.autocompleteUsers(
      query,
      teamId: teamId,
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        _mentionItems = matchingSpecials;
        _showMentions = matchingSpecials.isNotEmpty;
      },
      (users) {
        // Sort: channel members first, then others
        final inChannel = <User>[];
        final outOfChannel = <User>[];
        for (final u in users) {
          if (_channelMemberIds.contains(u.id)) {
            inChannel.add(u);
          } else {
            outOfChannel.add(u);
          }
        }
        _mentionItems = [
          ...matchingSpecials,
          ...inChannel.map((u) => MentionItem.user(u)),
          ...outOfChannel.map((u) => MentionItem.user(u)),
        ];
        _showMentions = _mentionItems.isNotEmpty;
      },
    );
    _updateMentionOverlay();
  }

  void _onMentionSelected(MentionItem item) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursorPos = (selection.isValid && selection.isCollapsed)
        ? selection.baseOffset
        : text.length;
    final textBeforeCursor = text.substring(0, cursorPos);
    final atIndex = textBeforeCursor.lastIndexOf('@');
    if (atIndex < 0) return;

    final textAfterCursor = text.substring(cursorPos);
    final replacement = '@${item.username} ';
    final newText = text.substring(0, atIndex) + replacement + textAfterCursor;

    _suppressMentionCheck = true;
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: atIndex + replacement.length,
    );
    _suppressMentionCheck = false;

    _showMentions = false;
    _mentionItems = [];
    _updateMentionOverlay();
  }

  void _updateMentionOverlay() {
    if (_showMentions && _mentionItems.isNotEmpty) {
      if (_mentionOverlay != null) {
        _mentionOverlay!.markNeedsBuild();
      } else {
        _mentionOverlay = OverlayEntry(
          builder: (context) {
            return Positioned(
              width: MediaQuery.of(this.context).size.width,
              child: CompositedTransformFollower(
                link: _mentionLayerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 0),
                followerAnchor: Alignment.bottomLeft,
                targetAnchor: Alignment.topLeft,
                child: MentionAutocomplete(
                  items: _mentionItems,
                  onSelect: _onMentionSelected,
                ),
              ),
            );
          },
        );
        Overlay.of(context).insert(_mentionOverlay!);
      }
    } else {
      _mentionOverlay?.remove();
      _mentionOverlay = null;
    }
  }

  // ===== Slash command autocomplete =====

  String? _getCommandQuery() {
    final text = _controller.text;
    if (text.isEmpty || !text.startsWith('/')) return null;

    final selection = _controller.selection;
    final cursorPos = (selection.isValid && selection.isCollapsed)
        ? selection.baseOffset
        : text.length;

    // Only show autocomplete if cursor is in the command part (before first space)
    final firstSpace = text.indexOf(' ');
    if (firstSpace >= 0 && cursorPos > firstSpace) return null;

    // Extract the command trigger typed so far (without the leading /)
    final query = text.substring(1, cursorPos);
    if (query.contains('\n')) return null;

    return query;
  }

  void _checkForCommand() {
    if (_suppressCommandCheck) return;
    final query = _getCommandQuery();
    if (query == null) {
      if (_showCommands) {
        _showCommands = false;
        _commandResults = [];
        _updateCommandOverlay();
      }
      _commandDebounce?.cancel();
      return;
    }

    _commandDebounce?.cancel();
    _commandDebounce = Timer(const Duration(milliseconds: 200), () {
      _fetchCommands(query);
    });
  }

  Future<void> _fetchCommands(String query) async {
    // Load commands once and cache
    if (_cachedCommands == null) {
      final result =
          await _postRepository.getAutocompleteCommands(widget.channelId);
      if (!mounted) return;
      result.fold(
        (failure) {
          _cachedCommands = [];
        },
        (commands) {
          _cachedCommands = commands;
        },
      );
    }

    final all = _cachedCommands ?? [];
    final filtered = query.isEmpty
        ? all
        : all
            .where((c) => c.trigger.startsWith(query.toLowerCase()))
            .toList();

    _commandResults = filtered;
    _showCommands = filtered.isNotEmpty;
    _updateCommandOverlay();
  }

  void _onCommandSelected(SlashCommand command) {
    _suppressCommandCheck = true;
    _controller.text = '/${command.trigger} ';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _suppressCommandCheck = false;

    _showCommands = false;
    _commandResults = [];
    _updateCommandOverlay();
    _focusNode.requestFocus();
  }

  void _updateCommandOverlay() {
    if (_showCommands && _commandResults.isNotEmpty) {
      if (_commandOverlay != null) {
        _commandOverlay!.markNeedsBuild();
      } else {
        _commandOverlay = OverlayEntry(
          builder: (context) {
            return Positioned(
              width: MediaQuery.of(this.context).size.width,
              child: CompositedTransformFollower(
                link: _commandLayerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 0),
                followerAnchor: Alignment.bottomLeft,
                targetAnchor: Alignment.topLeft,
                child: SlashCommandAutocomplete(
                  commands: _commandResults,
                  onSelect: _onCommandSelected,
                ),
              ),
            );
          },
        );
        Overlay.of(context).insert(_commandOverlay!);
      }
    } else {
      _commandOverlay?.remove();
      _commandOverlay = null;
    }
  }

  // ===== Emoji autocomplete =====

  String? _getEmojiQuery() {
    final text = _controller.text;
    if (text.isEmpty) return null;

    final selection = _controller.selection;
    final cursorPos = (selection.isValid && selection.isCollapsed)
        ? selection.baseOffset
        : text.length;
    if (cursorPos <= 0 || cursorPos > text.length) return null;

    final textBeforeCursor = text.substring(0, cursorPos);

    final colonIndex = textBeforeCursor.lastIndexOf(':');
    if (colonIndex < 0) return null;
    // Colon must be at start or preceded by space/newline
    if (colonIndex > 0 &&
        textBeforeCursor[colonIndex - 1] != ' ' &&
        textBeforeCursor[colonIndex - 1] != '\n') {
      return null;
    }

    final query = textBeforeCursor.substring(colonIndex + 1);
    if (query.contains(' ') || query.contains('\n') || query.contains(':')) {
      return null;
    }
    // Require at least 2 characters to start searching
    if (query.length < 2) return null;

    return query.toLowerCase();
  }

  void _checkForEmoji() {
    if (_suppressEmojiCheck) return;
    final query = _getEmojiQuery();
    if (query == null) {
      if (_showEmojis) {
        _showEmojis = false;
        _emojiResults = [];
        _updateEmojiOverlay();
      }
      _emojiDebounce?.cancel();
      return;
    }

    _emojiDebounce?.cancel();
    _emojiDebounce = Timer(const Duration(milliseconds: 200), () {
      _fetchEmojis(query);
    });
  }

  void _fetchEmojis(String query) {
    final results = <EmojiAutocompleteItem>[];
    final seen = <String>{};
    const maxResults = 20;

    // 1. Recent (last used) emojis first
    for (final name in _recentEmojis) {
      if (results.length >= maxResults) break;
      if (!name.contains(query) || seen.contains(name)) continue;
      seen.add(name);
      final unicode = emojiMap[name];
      final url = CustomEmojiCache.getUrl(name);
      results.add(EmojiAutocompleteItem(
        name: name,
        unicode: unicode,
        imageUrl: unicode == null ? url : null,
      ));
    }

    // 2. Custom (server) emojis
    for (final e in CustomEmojiCache.urls.entries) {
      if (results.length >= maxResults) break;
      if (!e.key.contains(query) || seen.contains(e.key)) continue;
      seen.add(e.key);
      results.add(EmojiAutocompleteItem(name: e.key, imageUrl: e.value));
    }

    // 3. Standard emojis from all categories
    for (final e in emojiMap.entries) {
      if (results.length >= maxResults) break;
      if (!e.key.contains(query) || seen.contains(e.key)) continue;
      seen.add(e.key);
      results.add(EmojiAutocompleteItem(name: e.key, unicode: e.value));
    }

    _emojiResults = results;
    _showEmojis = results.isNotEmpty;
    _updateEmojiOverlay();
  }

  void _onEmojiAutocompleteSelected(EmojiAutocompleteItem item) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursorPos = (selection.isValid && selection.isCollapsed)
        ? selection.baseOffset
        : text.length;
    final textBeforeCursor = text.substring(0, cursorPos);
    final colonIndex = textBeforeCursor.lastIndexOf(':');
    if (colonIndex < 0) return;

    final textAfterCursor = text.substring(cursorPos);
    // Use unicode if available, otherwise :name: format
    final replacement = item.unicode ?? ':${item.name}: ';
    final newText =
        text.substring(0, colonIndex) + replacement + textAfterCursor;

    _suppressEmojiCheck = true;
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: colonIndex + replacement.length,
    );
    _suppressEmojiCheck = false;

    _showEmojis = false;
    _emojiResults = [];
    _updateEmojiOverlay();
  }

  void _updateEmojiOverlay() {
    if (_showEmojis && _emojiResults.isNotEmpty) {
      if (_emojiOverlay != null) {
        _emojiOverlay!.markNeedsBuild();
      } else {
        _emojiOverlay = OverlayEntry(
          builder: (context) {
            return Positioned(
              width: MediaQuery.of(this.context).size.width,
              child: CompositedTransformFollower(
                link: _emojiLayerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 0),
                followerAnchor: Alignment.bottomLeft,
                targetAnchor: Alignment.topLeft,
                child: EmojiAutocomplete(
                  items: _emojiResults,
                  onSelect: _onEmojiAutocompleteSelected,
                  authHeaders: _authHeaders,
                ),
              ),
            );
          },
        );
        Overlay.of(context).insert(_emojiOverlay!);
      }
    } else {
      _emojiOverlay?.remove();
      _emojiOverlay = null;
    }
  }

  // ===== Actions =====

  Future<void> _saveDraft() async {
    final text = _controller.text.trim();
    await _draftStorage.saveDraft(Draft(
      channelId: widget.channelId,
      channelName: widget.channelName,
      message: text,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _mentionOverlay?.remove();
    _mentionOverlay = null;
    _commandOverlay?.remove();
    _commandOverlay = null;
    _emojiOverlay?.remove();
    _emojiOverlay = null;
    _draftTimer?.cancel();
    _mentionDebounce?.cancel();
    _commandDebounce?.cancel();
    _emojiDebounce?.cancel();
    _saveDraft();
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();

    if (_isEditing) {
      if (text.isEmpty) return;
      widget.onSaveEdit?.call(widget.editingPost!.id, text);
      return;
    }

    if (text.isEmpty && _pendingFileIds.isEmpty && !_isForwarding) return;

    HapticFeedback.lightImpact();
    widget.onSend(
      text,
      fileIds: _pendingFileIds.isNotEmpty ? List.from(_pendingFileIds) : null,
      priority: _selectedPriority,
    );

    _controller.clear();
    _draftTimer?.cancel();
    _draftStorage.deleteDraft(widget.channelId);
    setState(() {
      _pendingFileIds.clear();
      _pendingFileNames.clear();
      _selectedPriority = null;
      _showPriorityBar = false;
    });
  }

  void focusInput() {
    _focusNode.requestFocus();
  }

  void insertQuote(String text) {
    final quoted =
        '${text.split('\n').map((line) => '> $line').join('\n')}\n\n';
    final current = _controller.text;
    _controller.text = '$quoted$current';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _focusNode.requestFocus();
  }

  void _insertMention() {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursorPos = (selection.isValid && selection.isCollapsed)
        ? selection.baseOffset
        : text.length;

    // Insert @ at cursor position
    final before = text.substring(0, cursorPos);
    final after = text.substring(cursorPos);
    final needsSpace = before.isNotEmpty && !before.endsWith(' ') && !before.endsWith('\n');
    final insert = '${needsSpace ? ' ' : ''}@';

    _controller.text = '$before$insert$after';
    _controller.selection = TextSelection.collapsed(
      offset: cursorPos + insert.length,
    );
    _focusNode.requestFocus();

    // Trigger mention search
    Future.microtask(() => _checkForMention());
  }

  void _insertSlashCommand() {
    // If text is not empty and doesn't start with /, put cursor at start
    if (_controller.text.isNotEmpty && !_controller.text.startsWith('/')) {
      _controller.text = '/${_controller.text}';
      _controller.selection = const TextSelection.collapsed(offset: 1);
    } else if (_controller.text.isEmpty) {
      _controller.text = '/';
      _controller.selection = const TextSelection.collapsed(offset: 1);
    }
    _focusNode.requestFocus();

    // Trigger command search
    Future.microtask(() => _checkForCommand());
  }

  void _openEmojiPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => EmojiPickerSheet(
        onEmojiSelected: (emojiName) {
          _insertEmoji(emojiName);
        },
      ),
    );
  }

  void _insertEmoji(String emojiName) {
    // Convert emoji name to unicode character, or use :name: format for custom emojis
    final unicode = emojiMap[emojiName];
    final emojiText = unicode ?? ':$emojiName: ';

    final text = _controller.text;
    final selection = _controller.selection;
    final cursorPos = (selection.isValid && selection.isCollapsed)
        ? selection.baseOffset
        : text.length;

    final before = text.substring(0, cursorPos);
    final after = text.substring(cursorPos);

    _controller.text = '$before$emojiText$after';
    _controller.selection = TextSelection.collapsed(
      offset: cursorPos + emojiText.length,
    );
    _focusNode.requestFocus();
  }

  void _togglePriorityBar() {
    setState(() {
      _showPriorityBar = !_showPriorityBar;
      if (!_showPriorityBar) {
        _selectedPriority = null;
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    await _uploadFile(image.path, image.name);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;
    await _uploadFile(file.path!, file.name);
  }

  Future<void> _uploadFile(String path, String name) async {
    setState(() => _isUploading = true);

    final repo = currentSession.fileRepository;
    final result = await repo.uploadFiles(
      channelId: widget.channelId,
      filePaths: [path],
    );

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.uploadFailed(failure.message))),
          );
        }
      },
      (files) {
        setState(() {
          for (final f in files) {
            _pendingFileIds.add(f.id);
            _pendingFileNames.add(f.name);
          }
        });
      },
    );

    setState(() => _isUploading = false);
  }

  void _onInputChanged(String _) {
    _checkForMention();
    _checkForCommand();
    _checkForEmoji();
  }

  // ===== Build =====

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _mentionLayerLink,
      child: CompositedTransformTarget(
        link: _commandLayerLink,
        child: CompositedTransformTarget(
          link: _emojiLayerLink,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // File previews
            if (!_isEditing && _pendingFileNames.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: AppColors.backgroundLight,
                child: Wrap(
                  spacing: 8,
                  children:
                      _pendingFileNames.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onDeleted: () {
                        setState(() {
                          _pendingFileIds.removeAt(entry.key);
                          _pendingFileNames.removeAt(entry.key);
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            // Priority bar (toggleable)
            if (!_isEditing && _showPriorityBar) _buildPriorityBar(),
            if (_isEditing)
              _InputBanner(
                icon: Icons.edit_outlined,
                label: context.l10n.editingMessage,
                onCancel: widget.onCancelEdit,
              ),
            if (_isForwarding)
              _InputBanner(
                icon: Icons.shortcut,
                label: context.l10n.forwardingMessage,
                subtitle: widget.forwardingPost!.message.isNotEmpty
                    ? widget.forwardingPost!.message
                    : null,
                onCancel: widget.onCancelForward,
              ),
            // Main input area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Text field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: context.l10n.writeAMessage,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onChanged: _onInputChanged,
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  // Toolbar row — pushed to the very bottom
                  Padding(
                    padding: EdgeInsets.only(
                      left: MediaQuery.of(context).padding.bottom * 0.6 + 6,
                      right: MediaQuery.of(context).padding.bottom * 0.6 + 6,
                      top: 2,
                    ),
                    child: Row(
                      children: [
                        if (!_isEditing) ...[
                          // Attach (+)
                          _ToolbarButton(
                            icon: Icons.add,
                            onPressed:
                                _isUploading ? null : _showAttachMenu,
                          ),
                          // Mention (@)
                          _ToolbarButton(
                            icon: Icons.alternate_email,
                            onPressed: _insertMention,
                          ),
                          // Slash command (/)
                          _ToolbarButton(
                            icon: Icons.data_object,
                            onPressed: _insertSlashCommand,
                          ),
                          // Emoji
                          _ToolbarButton(
                            icon: Icons.emoji_emotions_outlined,
                            onPressed: _openEmojiPicker,
                          ),
                          // Priority (flag)
                          _ToolbarButton(
                            icon: _selectedPriority == null
                                ? Icons.flag_outlined
                                : Icons.flag,
                            color: _priorityColor,
                            onPressed: _togglePriorityBar,
                          ),
                        ],
                        if (_isEditing) const SizedBox(width: 8),
                        const Spacer(),
                        // Upload progress or Send button
                        if (_isUploading)
                          const Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          )
                        else
                          _ToolbarButton(
                            icon: _isEditing ? Icons.check : Icons.send,
                            color: AppColors.accent,
                            onPressed: _send,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Color get _priorityColor {
    switch (_selectedPriority) {
      case 'important':
        return AppColors.priorityImportant;
      case 'urgent':
        return AppColors.priorityUrgent;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildPriorityBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: AppColors.backgroundLight,
      child: Row(
        children: [
          const Icon(Icons.flag_outlined,
              size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(context.l10n.standard),
            selected: _selectedPriority == null,
            onSelected: (_) => setState(() => _selectedPriority = null),
            labelStyle: TextStyle(
              fontSize: 12,
              color: _selectedPriority == null
                  ? Colors.white
                  : AppColors.textSecondary,
            ),
            selectedColor: AppColors.textSecondary,
            backgroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: Text(context.l10n.important),
            selected: _selectedPriority == 'important',
            onSelected: (_) =>
                setState(() => _selectedPriority = 'important'),
            labelStyle: TextStyle(
              fontSize: 12,
              color: _selectedPriority == 'important'
                  ? Colors.white
                  : AppColors.priorityImportant,
            ),
            selectedColor: AppColors.priorityImportant,
            backgroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: Text(context.l10n.urgent),
            selected: _selectedPriority == 'urgent',
            onSelected: (_) =>
                setState(() => _selectedPriority = 'urgent'),
            labelStyle: TextStyle(
              fontSize: 12,
              color: _selectedPriority == 'urgent'
                  ? Colors.white
                  : AppColors.priorityUrgent,
            ),
            selectedColor: AppColors.priorityUrgent,
            backgroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: Text(context.l10n.photoFromGallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(context.l10n.file),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBanner extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onCancel;

  const _InputBanner({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.accent.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: subtitle == null
                ? Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: const Icon(Icons.close,
                size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback? onPressed;

  const _ToolbarButton({
    required this.icon,
    this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: IconButton(
        icon: Icon(icon, size: 30),
        color: color ?? AppColors.textSecondary,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: onPressed,
      ),
    );
  }
}
