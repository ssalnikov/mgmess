import 'package:flutter/material.dart';

class FileIcon extends StatelessWidget {
  final String extension_;
  final double size;

  const FileIcon({
    super.key,
    required this.extension_,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          extension_.toUpperCase(),
          style: TextStyle(
            color: _color,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.25,
          ),
        ),
      ),
    );
  }

  Color get _color {
    switch (extension_.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}
