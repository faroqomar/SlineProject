import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/profile_view_model.dart';
import './widgets/profile_avatar_widget.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/view/create_task_screen.dart';
import '../../portfolio/view/portfolio_screen.dart';
import '../../../features/favorites/routes/favorites_routes.dart';
import 'package:sline_app/features/auth/viewmodels/auth_view_model.dart';

/// Profile screen - user profile management and settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Load user data and fetch tasks when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileVM = context.read<ProfileViewModel>();
      profileVM.loadUserData();
      profileVM.fetchMyTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthViewModel>(
      create: (_) => AuthViewModel(),
      child: DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Profile Info'),
              Tab(text: 'My Tasks'),
              Tab(text: 'Portfolio'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Favorites',
              icon: const Icon(Icons.favorite_outline),
              onPressed: () {
                Navigator.of(context).pushNamed(FavoritesRoutes.routeName);
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthViewModel>().logout(context);
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Profile Info Tab
            Consumer<ProfileViewModel>(
              builder: (context, vm, child) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: vm.formKey,
                    child: Column(
                      children: [
                        const ProfileAvatarWidget(),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: vm.nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: vm.emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: vm.bioController,
                          decoration: const InputDecoration(
                            labelText: 'Bio',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.info),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await vm.updateProfile();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Profile updated successfully'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Update Profile'),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              await vm.changePassword();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password reset email sent'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Change Password'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            // My Tasks Tab
            Consumer<ProfileViewModel>(
              builder: (context, controller, child) {
                if (controller.isLoadingMyTasks) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (controller.myTasks.isEmpty) {
                  return const Center(child: Text('You haven’t posted any tasks yet.'));
                }
                return ListView.builder(
                  itemCount: controller.myTasks.length,
                  itemBuilder: (context, index) {
                    final Task task = controller.myTasks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(task.title),
                        subtitle: Text(task.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CreateTaskScreen(task: task),
                                  ),
                                ).then((_) {
                                  controller.fetchMyTasks();
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                controller.deleteMyTask(task.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const PortfolioScreen(),
          ],
        ),
      ),
    ));
  }
}
