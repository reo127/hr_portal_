import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'client_screen.dart';
import 'interview_questions_screen.dart';
import 'leave_management_screen.dart';
import 'report_screen.dart';
import 'policy_center_screen.dart';
import 'feedback_screen.dart';

class EmployeeTaskDeskScreen extends StatefulWidget {
  const EmployeeTaskDeskScreen({super.key});

  @override
  State<EmployeeTaskDeskScreen> createState() => _EmployeeTaskDeskScreenState();
}

class _EmployeeTaskDeskScreenState extends State<EmployeeTaskDeskScreen> {
  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Task Desk'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final username = authProvider.user?.username ?? 'User';
                return DrawerHeader(
                  decoration: const BoxDecoration(color: Colors.deepPurple),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.person, size: 64, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Task Manager',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.task),
              title: const Text('Tasks'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Employee Task Desk'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Client'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ClientScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_answer),
              title: const Text('Interview Questions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const InterviewQuestionsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('Leave Management'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LeaveManagementScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.policy),
              title: const Text('Policy Center'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PolicyCenterScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Feedback'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const FeedbackScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'Employee Task Desk Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
