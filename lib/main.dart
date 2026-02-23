import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:planly/firebase_options.dart';

import 'package:planly/core/theme/app_theme.dart';
import 'package:planly/core/constants/app_constants.dart';
import 'package:planly/core/config/app_config.dart';
import 'package:planly/core/network/connectivity_banner.dart';

// Features - Auth
import 'package:planly/features/auth/domain/repositories/auth_repository.dart';
import 'package:planly/features/auth/domain/usecases/auth_usecases.dart';
import 'package:planly/features/auth/presentation/providers/auth_provider.dart';

// Features - Profile
import 'package:planly/features/profile/domain/repositories/profile_repository.dart';
import 'package:planly/features/profile/domain/usecases/profile_usecases.dart';
import 'package:planly/features/profile/presentation/providers/profile_provider.dart';

// Features - Tasks
import 'package:planly/features/tasks/data/models/task_model.dart';
import 'package:planly/features/tasks/domain/repositories/task_repository.dart';
import 'package:planly/features/tasks/domain/usecases/task_usecases.dart';
import 'package:planly/features/tasks/presentation/providers/task_provider.dart';

// Screens
import 'package:planly/features/auth/presentation/screens/login_screen.dart';
import 'package:planly/features/tasks/presentation/screens/dashboard_screen.dart';

import "package:planly/core/di/injection_container.dart" as di;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(TaskModelAdapter().typeId)) {
    Hive.registerAdapter(TaskModelAdapter());
  }
  await Hive.openBox<TaskModel>(AppConstants.taskBoxName);
  await Hive.openBox<Map>(AppConstants.pendingActionsBoxName);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize dependency injection
  await di.init();

  runApp(const PlanlyApp());
}

class PlanlyApp extends StatelessWidget {
  const PlanlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: di.sl<AppConfig>()),
        Provider.value(value: di.sl<AuthRepository>()),
        Provider.value(value: di.sl<ProfileRepository>()),
        Provider.value(value: di.sl<TaskRepository>()),
        Provider.value(value: di.sl<Connectivity>()),

        ChangeNotifierProvider<AuthProvider>(
          create:
              (context) => AuthProvider(
                loginUseCase: di.sl<LoginUseCase>(),
                registerUseCase: di.sl<RegisterUseCase>(),
                logoutUseCase: di.sl<LogoutUseCase>(),
                onAuthStateChanged: di.sl<AuthRepository>().onAuthStateChanged,
              ),
        ),

        ChangeNotifierProvider<ProfileProvider>(
          create:
              (context) => ProfileProvider(
                updateProfileUseCase: di.sl<UpdateProfileUseCase>(),
                updateThemeModeUseCase: di.sl<UpdateThemeModeUseCase>(),
                getProfileStream:
                    (uid) => di.sl<ProfileRepository>().getProfile(uid),
              ),
        ),

        ChangeNotifierProvider<TaskProvider>(
          create:
              (context) => TaskProvider(
                fetchTasksUseCase: di.sl<FetchTasksUseCase>(),
                addTaskUseCase: di.sl<AddTaskUseCase>(),
                updateTaskUseCase: di.sl<UpdateTaskUseCase>(),
                deleteTaskUseCase: di.sl<DeleteTaskUseCase>(),
                syncTasksUseCase: di.sl<SyncTasksUseCase>(),
              ),
        ),
      ],
      child: const PlanlyAppView(),
    );
  }
}

class PlanlyAppView extends StatelessWidget {
  const PlanlyAppView({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector2<ProfileProvider, AppConfig, ThemeMode>(
      selector:
          (context, profileProvider, config) =>
              profileProvider.user?.themeMode == config.themeModeDark
                  ? ThemeMode.dark
                  : ThemeMode.light,
      builder: (context, themeMode, child) {
        final config = context.read<AppConfig>();
        return MaterialApp(
          title: config.appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: const RootScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.status == AuthStatus.initial ||
                    authProvider.status == AuthStatus.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Remove splash screen once we have an auth status
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  FlutterNativeSplash.remove();
                });

                if (authProvider.status == AuthStatus.authenticated &&
                    authProvider.user != null) {
                  // Trigger profile loading if not already loaded
                  final profileProvider = context.read<ProfileProvider>();
                  if (profileProvider.status == ProfileStatus.initial) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (authProvider.user != null) {
                        profileProvider.startProfileStream(
                          authProvider.user!.id,
                        );
                      }
                    });
                  }
                  return const DashboardScreen();
                }

                return const LoginScreen();
              },
            ),
          ),
        ],
      ),
    );
  }
}
