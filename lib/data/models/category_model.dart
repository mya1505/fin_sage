import 'package:equatable/equatable.dart';

class CategoryModel extends Equatable {
  const CategoryModel({
    required this.id,
    required this.name,
    required this.colorHex,
    this.icon = 'wallet',
  });

  final int? id;
  final String name;
  final String colorHex;
  final String icon;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_hex': colorHex,
      'icon': icon,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorHex: map['color_hex'] as String,
      icon: map['icon'] as String? ?? 'wallet',
    );
  }

  @override
  List<Object?> get props => [id, name, colorHex, icon];
}
