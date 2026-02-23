import 'package:planly/core/usecases/usecase.dart';
import 'package:planly/features/auth/domain/entities/user_entity.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase implements UseCase<void, UserEntity> {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<void> call(UserEntity user) {
    return repository.updateProfile(user);
  }
}

class UpdateThemeModeUseCase implements UseCase<void, ThemeParams> {
  final ProfileRepository repository;

  UpdateThemeModeUseCase(this.repository);

  @override
  Future<void> call(ThemeParams params) {
    return repository.updateThemeMode(params.uid, params.themeMode);
  }
}

class ThemeParams {
  final String uid;
  final String themeMode;

  ThemeParams({required this.uid, required this.themeMode});
}
