import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestConnectionScreen extends StatefulWidget {
  const TestConnectionScreen({super.key});

  @override
  State<TestConnectionScreen> createState() => _TestConnectionScreenState();
}

class _TestConnectionScreenState extends State<TestConnectionScreen> {
  String _status = 'Testing connection...';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      setState(() {
        _status = 'Testing Supabase connection...';
        _loading = true;
      });

      final client = Supabase.instance.client;

      // Test 1: Check client initialization
      setState(() =>
          _status = '✅ Supabase client initialized\nTesting authentication...');

      // Test 2: Check current user
      final user = client.auth.currentUser;
      if (user != null) {
        setState(() => _status =
            '✅ User authenticated: ${user.email}\nTesting database access...');

        // Test 3: Try simple query (with RLS disabled)
        try {
          final response = await client.from('admins').select('count').count();
          setState(() => _status =
              '✅ Database connection successful\n✅ Admin table accessible\nAdmins count: $response');
        } catch (dbError) {
          setState(() => _status =
              '✅ User authenticated: ${user.email}\n❌ Database error: $dbError');
        }
      } else {
        setState(() => _status =
            '✅ Supabase client initialized\n❌ No user authenticated\nPlease login first');
      }
    } catch (e) {
      setState(() => _status = '❌ Connection failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Supabase Connection'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (_loading)
                      const CircularProgressIndicator()
                    else
                      Text(
                        _status,
                        style: const TextStyle(fontSize: 16),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testConnection,
              child: const Text('Test Again'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debugging Steps',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Make sure you\'ve run the database_setup.sql script\n'
                      '2. Create an admin user in Supabase Auth\n'
                      '3. Run the debug_database.sql script\n'
                      '4. Check if RLS policies are blocking requests\n'
                      '5. Verify the admin record exists',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
