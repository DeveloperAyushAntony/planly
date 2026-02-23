import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planly/core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String name, String email, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get onAuthStateChanged;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) throw AuthException('User not found');

      return _getUserFromFirestore(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) throw AuthException('Registration failed');

      final userModel = UserModel(
        id: credential.user!.uid,
        name: name,
        email: email,
        createdAt: DateTime.now(),
        themeMode: 'light',
      );

      await firestore
          .collection('users')
          .doc(userModel.id)
          .set(userModel.toFirestore());
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;
    return _getUserFromFirestore(user.uid);
  }

  @override
  Stream<UserModel?> get onAuthStateChanged {
    return firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      return _getUserFromFirestore(user.uid);
    });
  }

  Future<UserModel> _getUserFromFirestore(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw AuthException('User profile not found in Firestore');
    return UserModel.fromFirestore(doc);
  }

  AuthException _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException('No user found for that email.', e.code);
      case 'wrong-password':
        return AuthException('Wrong password provided.', e.code);
      case 'email-already-in-use':
        return AuthException('Email is already in use.', e.code);
      case 'invalid-email':
        return AuthException('Invalid email address.', e.code);
      case 'weak-password':
        return AuthException('The password is too weak.', e.code);
      default:
        return AuthException(e.message ?? 'Authentication failed', e.code);
    }
  }
}
