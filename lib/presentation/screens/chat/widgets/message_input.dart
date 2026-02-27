import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../domain/entities/post.dart';
import '../../../../core/storage/draft_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/draft.dart';
import '../../../../domain/entities/user.dart';
import '../../../../domain/repositories/file_repository.dart';
import '../../../../domain/repositories/user_repository.dart';
import 'markdown_toolbar.dart';
import 'mention_autocomplete.dart';

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

  const MessageInput({
    super.key,
    required this.channelId,
    this.channelName = '',
    this.initialDraft,
    required this.onSend,
    this.editingPost,
    this.onCancelEdit,
    this.onSaveEdit,
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
  final _draftStorage = sl<DraftStorage>();

  // Edit mode
  String? _savedDraftText;
  bool get _isEditing => widget.editingPost != null;

  // Priority
  String? _selectedPriority;

  // Mentions
  List<User> _mentionResults = [];
  bool _showMentions = false;
  bool _suppressMentionCheck = false;
  Timer? _mentionDebounce;
  final _userRepository = sl<UserRepository>();

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
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
      setState(() {
        _showMentions = false;
        _mentionResults = [];
      });
    }
  }

  String? _getMentionQuery() {
    final text = _controller.text;
    if (text.isEmpty) return null;

    final selection = _controller.selection;
    // Use cursor position if valid, otherwise assume end of text
    final cursorPos = (selection.isValid && selection.isCollapsed)
        ? selection.baseOffset
        : text.length;
    if (cursorPos <= 0 || cursorPos > text.length) return null;

    final textBeforeCursor = text.substring(0, cursorPos);

    // Find last @ that starts a mention (preceded by space/start of string)
    final atIndex = textBeforeCursor.lastIndexOf('@');
    if (atIndex < 0) return null;
    if (atIndex > 0 && textBeforeCursor[atIndex - 1] != ' ' && textBeforeCursor[atIndex - 1] != '\n') {
      return null;
    }

    final query = textBeforeCursor.substring(atIndex + 1);
    // No spaces in mention query, require at least 1 char
    if (query.isEmpty || query.contains(' ') || query.contains('\n')) {
      return null;
    }

    return query;
  }

  void _checkForMention() {
    if (_suppressMentionCheck) return;
    final query = _getMentionQuery();
    if (query == null) {
      if (_showMentions) {
        setState(() {
          _showMentions = false;
          _mentionResults = [];
        });
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
    final result = await _userRepository.autocompleteUsers(
      query,
      channelId: widget.channelId,
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        debugPrint('Mention autocomplete error: ${failure.message}');
        setState(() {
          _showMentions = false;
          _mentionResults = [];
        });
      },
      (users) {
        setState(() {
          _mentionResults = users;
          _showMentions = users.isNotEmpty;
        });
      },
    );
  }

  void _onMentionSelected(User user) {
    final text = _controller.text;
    final selection = _controller.selection;
    final cursorPos = (selection.isValid && selection.isCollapsed)
        ? selection.baseOffset
        : text.length;
    final textBeforeCursor = text.substring(0, cursorPos);
    final atIndex = textBeforeCursor.lastIndexOf('@');
    if (atIndex < 0) return;

    final textAfterCursor = text.substring(cursorPos);
    final replacement = '@${user.username} ';
    final newText = text.substring(0, atIndex) + replacement + textAfterCursor;

    _suppressMentionCheck = true;
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: atIndex + replacement.length,
    );
    _suppressMentionCheck = false;

    setState(() {
      _showMentions = false;
      _mentionResults = [];
    });
  }

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
    _draftTimer?.cancel();
    _mentionDebounce?.cancel();
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

    if (text.isEmpty && _pendingFileIds.isEmpty) return;

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
    });
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

    final repo = sl<FileRepository>();
    final result = await repo.uploadFiles(
      channelId: widget.channelId,
      filePaths: [path],
    );

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: ${failure.message}')),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_showMentions && _mentionResults.isNotEmpty)
          MentionAutocomplete(
            users: _mentionResults,
            onSelect: _onMentionSelected,
          ),
        if (!_isEditing && _pendingFileNames.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            color: AppColors.backgroundLight,
            child: Wrap(
              spacing: 8,
              children: _pendingFileNames.asMap().entries.map((entry) {
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
        MarkdownToolbar(controller: _controller, focusNode: _focusNode),
        if (!_isEditing) _buildPriorityBar(),
        if (_isEditing)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: AppColors.accent.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Editing message',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: widget.onCancelEdit,
                  child: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
          child: SafeArea(
            child: Row(
              children: [
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.add, color: AppColors.accent),
                    onPressed: _isUploading ? null : _showAttachMenu,
                  ),
                if (_isEditing) const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 4,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Write a message...',
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (_) => _checkForMention(),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                if (_isUploading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.check : Icons.send,
                      color: AppColors.accent,
                    ),
                    onPressed: _send,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: AppColors.backgroundLight,
      child: Row(
        children: [
          const Icon(Icons.flag_outlined, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Standard'),
            selected: _selectedPriority == null,
            onSelected: (_) => setState(() => _selectedPriority = null),
            labelStyle: TextStyle(
              fontSize: 12,
              color: _selectedPriority == null ? Colors.white : AppColors.textSecondary,
            ),
            selectedColor: AppColors.textSecondary,
            backgroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: const Text('Important'),
            selected: _selectedPriority == 'important',
            onSelected: (_) => setState(() => _selectedPriority = 'important'),
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
            label: const Text('Urgent'),
            selected: _selectedPriority == 'urgent',
            onSelected: (_) => setState(() => _selectedPriority = 'urgent'),
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
              title: const Text('Photo from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('File'),
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
