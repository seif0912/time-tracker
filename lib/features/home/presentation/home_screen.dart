import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/presentation/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _logout(WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                },
              ),

              // Future navigation items will go here.
              //
              // ListTile(
              //   leading: const Icon(Icons.timer_outlined),
              //   title: const Text('Tasks'),
              // ),
              const Spacer(),

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Log out'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _logout(ref);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'Home',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
