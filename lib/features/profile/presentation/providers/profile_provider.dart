import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:planly/features/auth/domain/entities/user_entity.dart';
import '../../domain/usecases/profile_usecases.dart';

enum ProfileStatus { initial, loading, loaded, error }

class ProfileProvider extends ChangeNotifier {
  final UpdateProfileUseCase updateProfileUseCase;
  final UpdateThemeModeUseCase updateThemeModeUseCase;
  final Stream<UserEntity> Function(String) getProfileStream;

  ProfileStatus _status = ProfileStatus.initial;
  ProfileStatus _updateStatus = ProfileStatus.initial;
  UserEntity? _user;
  String? _errorMessage;
  StreamSubscription<UserEntity>? _profileSubscription;

  ProfileProvider({
    required this.updateProfileUseCase,
    required this.updateThemeModeUseCase,
    required this.getProfileStream,
  });

  ProfileStatus get status => _status;
  ProfileStatus get updateStatus => _updateStatus;
  UserEntity? get user => _user;
  String? get errorMessage => _errorMessage;

  void startProfileStream(String uid) {
    _status = ProfileStatus.loading;
    Future.microtask(() => notifyListeners());

    _profileSubscription?.cancel();
    _profileSubscription = getProfileStream(uid).listen(
      (user) {
        _user = user;
        _status = ProfileStatus.loaded;
        notifyListeners();
      },
      onError: (e) {
        _status = ProfileStatus.error;
        _errorMessage = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> updateProfile(UserEntity user) async {
    _updateStatus = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await updateProfileUseCase(user);
      _updateStatus = ProfileStatus.loaded;
      notifyListeners();
    } catch (e) {
      _updateStatus = ProfileStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateThemeMode(String uid, String themeMode) async {
    _updateStatus = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await updateThemeModeUseCase(ThemeParams(uid: uid, themeMode: themeMode));
      _updateStatus = ProfileStatus.loaded;
      notifyListeners();
    } catch (e) {
      _updateStatus = ProfileStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void resetUpdateStatus() {
    _updateStatus = ProfileStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _updateStatus = ProfileStatus.initial;
    notifyListeners();
  }

  void clearProfile() {
    _profileSubscription?.cancel();
    _profileSubscription = null;
    _user = null;
    _status = ProfileStatus.initial;
    _updateStatus = ProfileStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }

  void resetStatus() {
    _status = ProfileStatus.initial;
    notifyListeners();
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    super.dispose();
  }
}
