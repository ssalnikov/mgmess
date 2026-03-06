import '../../../core/error/exceptions.dart';
import '../../../domain/entities/channel_category.dart';
import '../../models/channel_category_model.dart';
import 'daos/channel_category_dao.dart';
import 'mappers/channel_category_mapper.dart';

class ChannelCategoryLocalDataSource {
  final ChannelCategoryDao _dao;

  ChannelCategoryLocalDataSource({required ChannelCategoryDao dao})
      : _dao = dao;

  Future<void> cacheCategories(List<ChannelCategory> categories,
      {required String userId}) async {
    try {
      await _dao.deleteAllForUser(userId);
      final companions =
          categories.map((c) => ChannelCategoryMapper.toCompanion(c)).toList();
      await _dao.upsertCategories(companions);
    } catch (e) {
      throw CacheException(message: 'Failed to cache categories: $e');
    }
  }

  Future<List<ChannelCategoryModel>> getCategories(String userId) async {
    try {
      final entries = await _dao.getCategoriesByUser(userId);
      return entries.map(ChannelCategoryMapper.fromEntry).toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get cached categories: $e');
    }
  }

  Future<void> updateCollapsed(String categoryId, bool collapsed) async {
    try {
      await _dao.updateCollapsed(categoryId, collapsed);
    } catch (e) {
      throw CacheException(message: 'Failed to update collapsed: $e');
    }
  }
}
