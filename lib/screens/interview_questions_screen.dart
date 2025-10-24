import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class InterviewQuestionsScreen extends StatefulWidget {
  const InterviewQuestionsScreen({super.key});

  @override
  State<InterviewQuestionsScreen> createState() => _InterviewQuestionsScreenState();
}

class _InterviewQuestionsScreenState extends State<InterviewQuestionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview Questions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const AppDrawer(currentRoute: 'interview_questions'),
      body: const Center(
        child: Text(
          'Interview Questions Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
