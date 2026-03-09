import 'package:equatable/equatable.dart';

class SlashCommand extends Equatable {
  final String id;
  final String trigger;
  final String displayName;
  final String description;
  final String autoCompleteHint;

  const SlashCommand({
    required this.id,
    required this.trigger,
    this.displayName = '',
    this.description = '',
    this.autoCompleteHint = '',
  });

  @override
  List<Object?> get props => [id, trigger];
}

class CommandResponse extends Equatable {
  /// "in_channel" or "ephemeral"
  final String responseType;
  final String text;
  final String gotoLocation;

  const CommandResponse({
    this.responseType = '',
    this.text = '',
    this.gotoLocation = '',
  });

  bool get isEphemeral => responseType == 'ephemeral';

  @override
  List<Object?> get props => [responseType, text, gotoLocation];
}
