import '../entities/post.dart';

abstract class WsPostParser {
  Post? parsePost(String jsonString);
}
