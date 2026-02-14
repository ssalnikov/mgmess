import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/repositories/file_repository.dart';

class MessageInput extends StatefulWidget {
  final String channelId;
  final void Function(String message, {List<String>? fileIds}) onSend;

  const MessageInput({
    super.key,
    required this.channelId,
    required this.onSend,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final List<String> _pendingFileIds = [];
  final List<String> _pendingFileNames = [];
  bool _isUploading = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingFileIds.isEmpty) return;

    widget.onSend(
      text,
      fileIds: _pendingFileIds.isNotEmpty ? List.from(_pendingFileIds) : null,
    );

    _controller.clear();
    setState(() {
      _pendingFileIds.clear();
      _pendingFileNames.clear();
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
        if (_pendingFileNames.isNotEmpty)
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
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.accent),
                  onPressed: _isUploading ? null : _showAttachMenu,
                ),
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
                    icon: const Icon(Icons.send, color: AppColors.accent),
                    onPressed: _send,
                  ),
              ],
            ),
          ),
        ),
      ],
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
