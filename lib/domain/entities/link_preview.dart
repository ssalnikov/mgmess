import 'package:equatable/equatable.dart';

class LinkPreview extends Equatable {
  final String url;
  final String title;
  final String description;
  final String siteName;
  final String? imageUrl;

  const LinkPreview({
    required this.url,
    this.title = '',
    this.description = '',
    this.siteName = '',
    this.imageUrl,
  });

  @override
  List<Object?> get props => [url, title, description, siteName, imageUrl];
}
