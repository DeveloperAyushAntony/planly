import 'package:planly/features/auth/domain/entities/user_entity.dart';

abstract class ProfileRepository {
  Future<void> updateProfile(UserEntity user);
  Future<void> updateThemeMode(String uid, String themeMode);
  Stream<UserEntity> getProfile(String uid);
}
