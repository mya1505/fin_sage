import 'package:equatable/equatable.dart';

class BackupFileModel extends Equatable {
  const BackupFileModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.size,
  });

  final String id;
  final String name;
  final DateTime? createdAt;
  final int size;

  @override
  List<Object?> get props => [id, name, createdAt, size];
}
