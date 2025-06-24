import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/admin_service.dart';

class DebugAuthScreen extends StatefulWidget {
  const DebugAuthScreen({super.key});

  @override
  State<DebugAuthScreen> createState() => _DebugAuthScreenState();
}

class _DebugAuthScreenState extends State<DebugAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _debugInfo = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentAuth();
  }

  Future<void> _checkCurrentAuth() async {
    setState(() {
      _debugInfo = 'Checking current authentication...\n';
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        setState(() {
          _debugInfo += 'No current user logged in\n';
        });
      } else {
        setState(() {
          _debugInfo +=
              'Current user: ${currentUser.email} (ID: ${currentUser.id})\n';
        });

        // Check admin record
        final adminService = AdminService(Supabase.instance.client);
        final admin = await adminService.getCurrentAdmin();

        if (admin == null) {
          setState(() {
            _debugInfo += 'ERROR: No admin record found for this user!\n';
            _debugInfo += 'This is likely why login fails.\n';
          });
        } else {
          setState(() {
            _debugInfo +=
                'Admin record found: ${admin.name} (Role: ${admin.role})\n';
            _debugInfo += 'Login should work correctly.\n';
          });
        }
      }
    } catch (e) {
      setState(() {
        _debugInfo += 'Error checking auth: $e\n';
      });
    }
  }

  Future<void> _testLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _debugInfo += 'Please provide email and password\n';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _debugInfo += '\n--- Starting Login Test ---\n';
      _debugInfo += 'Email: ${_emailController.text}\n';
    });

    try {
      // Step 1: Try to sign in
      setState(() {
        _debugInfo += 'Step 1: Attempting sign in...\n';
      });

      final authResponse =
          await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (authResponse.user == null) {
        setState(() {
          _debugInfo += 'ERROR: No user returned from auth\n';
        });
        return;
      }

      setState(() {
        _debugInfo += 'SUCCESS: User authenticated\n';
        _debugInfo += 'User ID: ${authResponse.user!.id}\n';
        _debugInfo += 'User Email: ${authResponse.user!.email}\n';
      });

      // Step 2: Check admin record
      setState(() {
        _debugInfo += 'Step 2: Checking admin record...\n';
      });

      final adminService = AdminService(Supabase.instance.client);
      final admin = await adminService.getCurrentAdmin();

      if (admin == null) {
        setState(() {
          _debugInfo += 'ERROR: No admin record found!\n';
          _debugInfo += 'You need to create an admin record in the database.\n';
          _debugInfo += 'Run the debug_auth_issue.sql script to create one.\n';
        });

        // Try to get more info about what's in the admins table
        try {
          final response = await Supabase.instance.client
              .from('admins')
              .select('id, name, email, auth_user_id, role')
              .limit(10);

          setState(() {
            _debugInfo += 'Current admin records in database:\n';
            for (final record in response) {
              _debugInfo +=
                  '  - ${record['name']} (${record['email']}) - Auth ID: ${record['auth_user_id']}\n';
            }
          });
        } catch (e) {
          setState(() {
            _debugInfo += 'Error querying admins table: $e\n';
          });
        }
      } else {
        setState(() {
          _debugInfo += 'SUCCESS: Admin record found!\n';
          _debugInfo += 'Name: ${admin.name}\n';
          _debugInfo += 'Email: ${admin.email}\n';
          _debugInfo += 'Role: ${admin.role}\n';
          _debugInfo += 'Login should work correctly now.\n';
        });

        // Test role check
        final isSuperAdmin = await adminService.isCurrentUserSuperAdmin();
        setState(() {
          _debugInfo += 'Is Super Admin: $isSuperAdmin\n';
        });
      }
    } catch (e) {
      setState(() {
        _debugInfo += 'ERROR during login: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Debug Authentication'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Authentication Debug Tool',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Email field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Admin Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),

            // Password field
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testLogin,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Test Login'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _checkCurrentAuth,
                    child: const Text('Check Current Auth'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Debug info
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
