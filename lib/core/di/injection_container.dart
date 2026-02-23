import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:planly/core/config/app_config.dart';
import 'package:planly/core/constants/app_constants.dart';

// Auth
import 'package:planly/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:planly/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:planly/features/auth/domain/repositories/auth_repository.dart';
import 'package:planly/features/auth/domain/usecases/auth_usecases.dart';

// Profile
import 'package:planly/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:planly/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:planly/features/profile/domain/repositories/profile_repository.dart';
import 'package:planly/features/profile/domain/usecases/profile_usecases.dart';

// Tasks
import 'package:planly/features/tasks/data/datasources/task_local_data_source.dart';
import 'package:planly/features/tasks/data/datasources/task_remote_data_source.dart';
import 'package:planly/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:planly/features/tasks/data/models/task_model.dart';
import 'package:planly/features/tasks/domain/repositories/task_repository.dart';
import 'package:planly/features/tasks/domain/usecases/task_usecases.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External dependencies
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(
    () => Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl)),
  );
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton<Box<TaskModel>>(
    () => Hive.box<TaskModel>(AppConstants.taskBoxName),
  );
  sl.registerLazySingleton<Box<Map>>(
    () => Hive.box<Map>(AppConstants.pendingActionsBoxName),
  );

  // Configuration
  sl.registerLazySingleton(
    () => AppConfig(
      appName: AppConstants.appName,
      apiBaseUrl: AppConstants.apiBaseUrl,
      taskBoxName: AppConstants.taskBoxName,
      themeModeDark: AppConstants.darkTheme,
      themeModeLight: AppConstants.lightTheme,
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(firebaseAuth: sl(), firestore: sl()),
  );
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(firestore: sl()),
  );
  sl.registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSourceImpl(
      dio: sl(),
      baseUrl: sl<AppConfig>().apiBaseUrl,
    ),
  );
  sl.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(taskBox: sl(), pendingActionsBox: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      connectivity: sl(),
      authRepository: sl(),
    ),
  );

  // Use cases - Auth
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // Use cases - Profile
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateThemeModeUseCase(sl()));

  // Use cases - Task
  sl.registerLazySingleton(() => FetchTasksUseCase(sl()));
  sl.registerLazySingleton(() => AddTaskUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTaskUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTaskUseCase(sl()));
  sl.registerLazySingleton(() => SyncTasksUseCase(sl()));
}
