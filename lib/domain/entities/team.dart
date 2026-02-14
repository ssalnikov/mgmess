import 'package:equatable/equatable.dart';

class Team extends Equatable {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final String type;

  const Team({
    required this.id,
    required this.name,
    this.displayName = '',
    this.description = '',
    this.type = 'O',
  });

  @override
  List<Object?> get props => [id];
}
