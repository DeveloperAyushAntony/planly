import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planly/features/auth/data/models/user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<void> updateProfile(UserModel user);
  Future<void> updateThemeMode(String uid, String themeMode);
  Stream<UserModel> getProfile(String uid);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final FirebaseFirestore firestore;

  ProfileRemoteDataSourceImpl({required this.firestore});

  @override
  Future<void> updateProfile(UserModel user) async {
    await firestore.collection('users').doc(user.id).update(user.toFirestore());
  }

  @override
  Future<void> updateThemeMode(String uid, String themeMode) async {
    await firestore.collection('users').doc(uid).update({
      'themeMode': themeMode,
    });
  }

  @override
  Stream<UserModel> getProfile(String uid) {
    return firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => UserModel.fromFirestore(doc));
  }
}
