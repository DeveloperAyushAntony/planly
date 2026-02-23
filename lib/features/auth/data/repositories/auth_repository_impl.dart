import 'package:planly/features/auth/domain/entities/user_entity.dart';
import 'package:planly/features/auth/domain/repositories/auth_repository.dart';
import 'package:planly/features/auth/data/datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserEntity> login(String email, String password) async {
    return await remoteDataSource.login(email, password);
  }

  @override
  Future<UserEntity> register(
    String name,
    String email,
    String password,
  ) async {
    return await remoteDataSource.register(name, email, password);
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return await remoteDataSource.getCurrentUser();
  }

  @override
  Stream<UserEntity?> get onAuthStateChanged {
    return remoteDataSource.onAuthStateChanged;
  }
}
