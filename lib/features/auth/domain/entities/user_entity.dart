import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final String themeMode;
  final String? avatarUrl;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.themeMode = 'light',
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [id, name, email, createdAt, themeMode, avatarUrl];

  UserEntity copyWith({
    String? name,
    String? email,
    DateTime? createdAt,
    String? themeMode,
    String? avatarUrl,
  }) {
    return UserEntity(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      themeMode: themeMode ?? this.themeMode,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
