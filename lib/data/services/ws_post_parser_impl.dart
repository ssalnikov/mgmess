import 'dart:convert';

import '../../domain/entities/post.dart';
import '../../domain/services/ws_post_parser.dart';
import '../models/post_model.dart';

class WsPostParserImpl implements WsPostParser {
  @override
  Post? parsePost(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return PostModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
