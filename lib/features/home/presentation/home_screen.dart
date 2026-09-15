import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// import '../../authentication/data/auth_providers.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../dashboard/presentation/dashboard_controller.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.invalidate(dashboardControllerProvider);
    });
  }

  Future<void> _logout() async {
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TimeTracker')),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const DrawerHeader(
                child: Center(
                  child: Text(
                    'TimeTracker',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home'),
                selected: true,
                onTap: () {
                  Navigator.of(context).pop();
                  ref.invalidate(dashboardControllerProvider);
                },
              ),

              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Tasks'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/tasks');
                },
              ),

              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archived Tasks'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/archived-tasks');
                },
              ),

              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('History'),
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/history');
                },
              ),

              const Spacer(),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log out'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _logout();
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: const DashboardScreen(),
    );
  }
}
