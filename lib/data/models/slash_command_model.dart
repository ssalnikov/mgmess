import '../../domain/entities/slash_command.dart';

class SlashCommandModel extends SlashCommand {
  const SlashCommandModel({
    required super.id,
    required super.trigger,
    super.displayName,
    super.description,
    super.autoCompleteHint,
  });

  factory SlashCommandModel.fromJson(Map<String, dynamic> json) {
    return SlashCommandModel(
      id: json['id'] as String? ?? '',
      trigger: json['trigger'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      description: json['auto_complete_desc'] as String? ??
          json['description'] as String? ??
          '',
      autoCompleteHint: json['auto_complete_hint'] as String? ?? '',
    );
  }
}

class CommandResponseModel extends CommandResponse {
  const CommandResponseModel({
    super.responseType,
    super.text,
    super.gotoLocation,
  });

  factory CommandResponseModel.fromJson(Map<String, dynamic> json) {
    return CommandResponseModel(
      responseType: json['response_type'] as String? ?? '',
      text: json['text'] as String? ?? '',
      gotoLocation: json['goto_location'] as String? ?? '',
    );
  }
}
