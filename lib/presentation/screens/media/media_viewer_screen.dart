import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../../core/di/injection.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../domain/entities/file_info.dart';

class MediaViewerScreen extends StatefulWidget {
  final List<FileInfo> files;
  final int initialIndex;

  const MediaViewerScreen({
    super.key,
    required this.files,
    this.initialIndex = 0,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late int _currentIndex;
  late PageController _pageController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1}/${widget.files.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_alt, color: Colors.white),
              onPressed: _saveToGallery,
            ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: currentSession.getAuthToken(),
        builder: (context, snapshot) {
          final token = snapshot.data;
          if (token == null) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          final headers = {'Authorization': 'Bearer $token'};
          return PhotoViewGallery.builder(
            pageController: _pageController,
            itemCount: widget.files.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            builder: (context, index) {
              final file = widget.files[index];
              final url =
                  '${currentSession.baseUrl}${ApiEndpoints.file(file.id)}';
              return PhotoViewGalleryPageOptions(
                imageProvider: CachedNetworkImageProvider(
                  url,
                  headers: headers,
                ),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 3,
                heroAttributes: PhotoViewHeroAttributes(tag: file.id),
              );
            },
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveToGallery() async {
    setState(() => _isSaving = true);
    try {
      final file = widget.files[_currentIndex];
      final url = '${currentSession.baseUrl}${ApiEndpoints.file(file.id)}';
      final apiClient = currentSession.apiClient;

      final response = await apiClient.dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = Uint8List.fromList(response.data!);
      await Gal.putImageBytes(bytes, name: file.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to gallery')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
