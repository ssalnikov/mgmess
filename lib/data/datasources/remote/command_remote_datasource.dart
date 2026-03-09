import '../../../core/error/exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../models/slash_command_model.dart';

class CommandRemoteDataSource {
  final ApiClient _apiClient;

  CommandRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<List<SlashCommandModel>> getAutocompleteCommands(
    String channelId,
  ) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.commandsAutocomplete,
        queryParameters: {'channel_id': channelId},
      );
      final data = response.data;
      if (data is List) {
        return data
            .map((e) =>
                SlashCommandModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      // Some servers wrap in {"commands": [...]}
      if (data is Map<String, dynamic> && data['commands'] is List) {
        return (data['commands'] as List)
            .map((e) =>
                SlashCommandModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw ServerException(message: 'Failed to get commands: $e');
    }
  }

  Future<CommandResponseModel> executeCommand({
    required String channelId,
    required String command,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.commandsExecute,
        data: {
          'channel_id': channelId,
          'command': command,
        },
      );
      return CommandResponseModel.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException(message: 'Failed to execute command: $e');
    }
  }
}
