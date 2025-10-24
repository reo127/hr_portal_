import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class PolicyCenterScreen extends StatefulWidget {
  const PolicyCenterScreen({super.key});

  @override
  State<PolicyCenterScreen> createState() => _PolicyCenterScreenState();
}

class _PolicyCenterScreenState extends State<PolicyCenterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Policy Center'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const AppDrawer(currentRoute: 'policy_center'),
      body: const Center(
        child: Text(
          'Policy Center Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
