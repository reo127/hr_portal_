import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../services/task_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'employee_task_desk_screen.dart';
import 'client_screen.dart';
import 'interview_questions_screen.dart';
import 'leave_management_screen.dart';
import 'report_screen.dart';
import 'policy_center_screen.dart';
import 'feedback_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hoursController = TextEditingController();
  int _selectedMinutes = 15; // Default minutes
  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'inprogress';

  final List<Task> _tasks = [];
  final TaskService _taskService = TaskService();

  // Pagination state
  int _currentPage = 1;
  final int _limit = 10;
  int _totalTasks = 0;
  int _totalPages = 0;
  bool _hasMore = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  // Fetch tasks from API
  Future<void> _fetchTasks() async {
    print('DEBUG HomeScreen: _fetchTasks called');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('DEBUG HomeScreen: Calling taskService.getTasks');
      final result = await _taskService.getTasks(
        page: _currentPage,
        limit: _limit,
      );

      print('DEBUG HomeScreen: Result received: $result');

      setState(() {
        _tasks.clear();
        _tasks.addAll(result['tasks'] as List<Task>);
        _totalTasks = result['total'];
        _totalPages = result['totalPages'];
        _hasMore = result['hasMore'];
        _isLoading = false;
      });

      print('DEBUG HomeScreen: Tasks updated, count: ${_tasks.length}');
    } catch (e) {
      print('DEBUG HomeScreen: Error caught: $e');
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Go to next page
  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
      _fetchTasks();
    }
  }

  // Go to previous page
  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _fetchTasks();
    }
  }

  // Convert hours and minutes to total hours (decimal)
  double _calculateTotalHours() {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutesInHours = _selectedMinutes / 60.0;
    return hours + minutesInHours;
  }

  // Show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addTask() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get userId and username from provider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final userId = authProvider.user?.userId;
        final employeeName = authProvider.user?.username;

        if (userId == null || employeeName == null) {
          throw Exception('User data not found');
        }

        // Format date as YYYY-MM-DD
        final formattedDate =
            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

        // Create task object
        final newTask = Task(
          id: '',
          title: _titleController.text,
          description: _descriptionController.text,
          hours: _calculateTotalHours().toInt(),
          status: _selectedStatus,
          date: formattedDate,
          userId: userId,
          employeeName: employeeName,
          reason: '',
        );

        print('DEBUG: Creating task with data:');
        print('  title: ${_titleController.text}');
        print('  description: ${_descriptionController.text}');
        print('  hours: ${_calculateTotalHours().toInt()}');
        print('  status: $_selectedStatus');
        print('  date: $formattedDate');
        print('  userId: $userId');
        print('  employeeName: $employeeName');

        // Call API to create task
        await _taskService.createTask(newTask);

        // Clear form
        _titleController.clear();
        _descriptionController.clear();
        _hoursController.clear();
        _selectedMinutes = 15;
        _selectedDate = DateTime.now();
        _selectedStatus = 'inprogress';

        // Refresh tasks list
        await _fetchTasks();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task added successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to add task: ${e.toString().replaceFirst('Exception: ', '')}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showEditDialog(Task task) {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    final hoursController = TextEditingController(text: task.hours.toString());
    int selectedMinutes = 15;
    String status = task.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: hoursController,
                        decoration: const InputDecoration(
                          labelText: 'Hours',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: selectedMinutes,
                        decoration: const InputDecoration(
                          labelText: 'Minutes',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15')),
                          DropdownMenuItem(value: 30, child: Text('30')),
                          DropdownMenuItem(value: 45, child: Text('45')),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedMinutes = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'inprogress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      status = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  // Create updated task with all existing fields
                  final updatedTask = task.copyWith(
                    title: titleController.text,
                    description: descriptionController.text,
                    hours: int.tryParse(hoursController.text) ?? task.hours,
                    status: status,
                  );

                  // Call API to update task
                  await _taskService.updateTask(updatedTask);

                  // Refresh tasks list
                  await _fetchTasks();

                  if (mounted) {
                    nav.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Task updated successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to update task: ${e.toString().replaceFirst('Exception: ', '')}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

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

  void _showAddTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Add New Task',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    isDense: true,
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hoursController,
                        decoration: const InputDecoration(
                          labelText: 'Hours',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter hours';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _selectedMinutes,
                        decoration: const InputDecoration(
                          labelText: 'Minutes',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15')),
                          DropdownMenuItem(value: 30, child: Text('30')),
                          DropdownMenuItem(value: 45, child: Text('45')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedMinutes = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                            isDense: true,
                          ),
                          child: Text(
                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'inprogress',
                            child: Text('In Progress'),
                          ),
                          DropdownMenuItem(
                            value: 'completed',
                            child: Text('Completed'),
                          ),
                          DropdownMenuItem(
                            value: 'pending',
                            child: Text('Pending'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    await _addTask();
                    if (mounted) nav.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Add Task', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Management'),
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
              subtitle: Text('$_totalTasks total'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('Employee Task Desk'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeeTaskDeskScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Client'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ClientScreen(),
                  ),
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
                  MaterialPageRoute(
                    builder: (context) => const InterviewQuestionsScreen(),
                  ),
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
                  MaterialPageRoute(
                    builder: (context) => const LeaveManagementScreen(),
                  ),
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
                  MaterialPageRoute(
                    builder: (context) => const ReportScreen(),
                  ),
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
                  MaterialPageRoute(
                    builder: (context) => const PolicyCenterScreen(),
                  ),
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
                  MaterialPageRoute(
                    builder: (context) => const FeedbackScreen(),
                  ),
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Tasks',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_totalTasks tasks',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchTasks,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _tasks.isEmpty
                ? const Center(
                    child: Text(
                      'No tasks found.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final task = _tasks[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: task.status == 'completed'
                                      ? Colors.green
                                      : task.status == 'inprogress'
                                      ? Colors.blue
                                      : Colors.orange,
                                  child: Icon(
                                    task.status == 'completed'
                                        ? Icons.check
                                        : task.status == 'inprogress'
                                        ? Icons.play_arrow
                                        : Icons.pending,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(task.description),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text('${task.hours} hour(s)'),
                                        const SizedBox(width: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: task.status == 'completed'
                                                ? Colors.green[100]
                                                : task.status == 'inprogress'
                                                ? Colors.blue[100]
                                                : Colors.orange[100],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            task.status == 'inprogress'
                                                ? 'IN PROGRESS'
                                                : task.status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: task.status == 'completed'
                                                  ? Colors.green[800]
                                                  : task.status == 'inprogress'
                                                  ? Colors.blue[800]
                                                  : Colors.orange[800],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.edit),
                                onTap: () => _showEditDialog(task),
                              ),
                            );
                          },
                        ),
                      ),
                      // Pagination controls
                      if (_totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back_ios_new),
                                  onPressed: _currentPage > 1
                                      ? _previousPage
                                      : null,
                                ),
                                Text(
                                  'Page $_currentPage of $_totalPages',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios),
                                  onPressed: _currentPage < _totalPages
                                      ? _nextPage
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: FloatingActionButton.extended(
          onPressed: _showAddTaskDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Task'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
