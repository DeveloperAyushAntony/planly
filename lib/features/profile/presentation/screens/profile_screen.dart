import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planly/features/auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProfileProvider>().startProfileStream(user.id);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final user = context.read<ProfileProvider>().user;
    if (user != null) {
      context.read<ProfileProvider>().updateProfile(
        user.copyWith(name: _nameController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Consumer<ProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.updateStatus == ProfileStatus.loaded) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    duration: Duration(seconds: 2),
                  ),
                );
                profileProvider.resetUpdateStatus();
              }
            });
          } else if (profileProvider.updateStatus == ProfileStatus.error &&
              profileProvider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(profileProvider.errorMessage!),
                    duration: Duration(seconds: 2),
                  ),
                );
                profileProvider.resetUpdateStatus();
              }
            });
          }

          final user = profileProvider.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: user.email,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Dark Mode'),
                trailing: Switch(
                  value: user.themeMode == 'dark',
                  onChanged: (val) {
                    final newMode = val ? 'dark' : 'light';
                    profileProvider.updateThemeMode(user.id, newMode);
                  },
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed:
                    profileProvider.updateStatus == ProfileStatus.loading
                        ? null
                        : _saveProfile,
                child:
                    profileProvider.updateStatus == ProfileStatus.loading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('Save Profile'),
              ),
            ],
          );
        },
      ),
    );
  }
}
