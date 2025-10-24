import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class EmployeeTaskDeskScreen extends StatefulWidget {
  const EmployeeTaskDeskScreen({super.key});

  @override
  State<EmployeeTaskDeskScreen> createState() => _EmployeeTaskDeskScreenState();
}

class _EmployeeTaskDeskScreenState extends State<EmployeeTaskDeskScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Task Desk'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const AppDrawer(currentRoute: 'employee_task_desk'),
      body: const Center(
        child: Text(
          'Employee Task Desk Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
