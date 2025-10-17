import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../services/task_service.dart';
import 'login_screen.dart';

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

  final List<Task> _tasks = [];
  final TaskService _taskService = TaskService();

  // Pagination state
  int _currentPage = 1;
  final int _limit = 5;
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

  void _addTask() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _tasks.add(Task(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          hours: _calculateTotalHours().toInt(),
          status: 'pending',
        ));
      });

      _titleController.clear();
      _descriptionController.clear();
      _hoursController.clear();
      _selectedMinutes = 15;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task added successfully!')),
      );
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
              onPressed: () {
                setState(() {
                  final index = _tasks.indexWhere((t) => t.id == task.id);
                  if (index != -1) {
                    _tasks[index] = Task(
                      id: task.id,
                      title: titleController.text,
                      description: descriptionController.text,
                      hours: int.tryParse(hoursController.text) ?? task.hours,
                      status: status,
                    );
                  }
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Task updated successfully!')),
                );
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
                  decoration: const BoxDecoration(
                    color: Colors.deepPurple,
                  ),
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
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add New Task',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
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
                    ),
                    maxLines: 3,
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
                        flex: 2,
                        child: TextFormField(
                          controller: _hoursController,
                          decoration: const InputDecoration(
                            labelText: 'Hours',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.access_time),
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
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: _selectedMinutes,
                          decoration: const InputDecoration(
                            labelText: 'Minutes',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer),
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addTask,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Add Task', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Tasks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$_totalTasks total tasks',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
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
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _tasks.length,
                                    itemBuilder: (context, index) {
                                      final task = _tasks[index];
                                      return Card(
                                        margin:
                                            const EdgeInsets.only(bottom: 12),
                                        elevation: 2,
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                task.status == 'completed'
                                                    ? Colors.green
                                                    : Colors.orange,
                                            child: Icon(
                                              task.status == 'completed'
                                                  ? Icons.check
                                                  : Icons.pending,
                                              color: Colors.white,
                                            ),
                                          ),
                                          title: Text(
                                            task.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  task.status == 'completed'
                                                      ? TextDecoration
                                                          .lineThrough
                                                      : null,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Text(task.description),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Icon(Icons.access_time,
                                                      size: 16,
                                                      color: Colors.grey[600]),
                                                  const SizedBox(width: 4),
                                                  Text('${task.hours} hour(s)'),
                                                  const SizedBox(width: 16),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: task.status ==
                                                              'completed'
                                                          ? Colors.green[100]
                                                          : Colors.orange[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Text(
                                                      task.status.toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: task.status ==
                                                                'completed'
                                                            ? Colors.green[800]
                                                            : Colors
                                                                .orange[800],
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.arrow_back_ios_new),
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
                                          icon: const Icon(
                                              Icons.arrow_forward_ios),
                                          onPressed:
                                              _currentPage < _totalPages
                                                  ? _nextPage
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
            ),
          ],
        ),
      ),
    );
  }
}