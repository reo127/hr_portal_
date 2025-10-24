import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/employee_task_desk_screen.dart';
import '../screens/client_screen.dart';
import '../screens/interview_questions_screen.dart';
import '../screens/leave_management_screen.dart';
import '../screens/report_screen.dart';
import '../screens/policy_center_screen.dart';
import '../screens/feedback_screen.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _navigateTo(BuildContext context, String route, Widget screen) {
    if (route != currentRoute) {
      Navigator.pop(context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
            selected: currentRoute == 'tasks',
            onTap: () => _navigateTo(context, 'tasks', const HomeScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: currentRoute == 'dashboard',
            onTap: () => _navigateTo(context, 'dashboard', const DashboardScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.assignment),
            title: const Text('Employee Task Desk'),
            selected: currentRoute == 'employee_task_desk',
            onTap: () => _navigateTo(context, 'employee_task_desk', const EmployeeTaskDeskScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Client'),
            selected: currentRoute == 'client',
            onTap: () => _navigateTo(context, 'client', const ClientScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.question_answer),
            title: const Text('Interview Questions'),
            selected: currentRoute == 'interview_questions',
            onTap: () => _navigateTo(context, 'interview_questions', const InterviewQuestionsScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.event_available),
            title: const Text('Leave Management'),
            selected: currentRoute == 'leave_management',
            onTap: () => _navigateTo(context, 'leave_management', const LeaveManagementScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Report'),
            selected: currentRoute == 'report',
            onTap: () => _navigateTo(context, 'report', const ReportScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.policy),
            title: const Text('Policy Center'),
            selected: currentRoute == 'policy_center',
            onTap: () => _navigateTo(context, 'policy_center', const PolicyCenterScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('Feedback'),
            selected: currentRoute == 'feedback',
            onTap: () => _navigateTo(context, 'feedback', const FeedbackScreen()),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}
