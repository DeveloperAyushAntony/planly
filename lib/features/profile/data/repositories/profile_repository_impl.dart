import 'package:planly/features/auth/data/models/user_model.dart';
import 'package:planly/features/auth/domain/entities/user_entity.dart';
import 'package:planly/features/profile/domain/repositories/profile_repository.dart';
import 'package:planly/features/profile/data/datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> updateProfile(UserEntity user) async {
    final userModel = UserModel(
      id: user.id,
      name: user.name,
      email: user.email,
      createdAt: user.createdAt,
      themeMode: user.themeMode,
    );
    return await remoteDataSource.updateProfile(userModel);
  }

  @override
  Future<void> updateThemeMode(String uid, String themeMode) async {
    return await remoteDataSource.updateThemeMode(uid, themeMode);
  }

  @override
  Stream<UserEntity> getProfile(String uid) {
    return remoteDataSource.getProfile(uid).map((model) => model as UserEntity);
  }
}
