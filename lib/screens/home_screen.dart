import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../services/task_service.dart';
import '../widgets/app_drawer.dart';

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
  int _selectedMinutes = 0; // Default minutes
  DateTime _selectedDate = DateTime.now();
  String _selectedStatus = 'inprogress';

  final List<Task> _tasks = [];
  final TaskService _taskService = TaskService();

  // Week-based navigation state
  late DateTime _currentWeekStart;
  late DateTime _currentWeekEnd;
  Map<String, List<Task>> _tasksByDay = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _calculateCurrentWeek();
    _fetchTasks();
  }

  // Calculate the current week (Monday to Saturday)
  void _calculateCurrentWeek() {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday

    print('DEBUG: Today is $now, weekday: $weekday');

    // Calculate Monday of current week
    _currentWeekStart = now.subtract(Duration(days: weekday - 1));
    print('DEBUG: Before normalization - Start: $_currentWeekStart');

    // Calculate Saturday of current week (Monday + 5 days)
    _currentWeekEnd = _currentWeekStart.add(const Duration(days: 5));
    print('DEBUG: Before normalization - End: $_currentWeekEnd');

    // Normalize to start of day
    _currentWeekStart = DateTime(_currentWeekStart.year, _currentWeekStart.month, _currentWeekStart.day);
    _currentWeekEnd = DateTime(_currentWeekEnd.year, _currentWeekEnd.month, _currentWeekEnd.day);

    print('DEBUG: After normalization - Start: $_currentWeekStart (${DateFormat('EEEE').format(_currentWeekStart)})');
    print('DEBUG: After normalization - End: $_currentWeekEnd (${DateFormat('EEEE').format(_currentWeekEnd)})');
    print('DEBUG: Week range text: ${_getWeekRangeText()}');
  }

  // Go to previous week
  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
      _currentWeekEnd = _currentWeekEnd.subtract(const Duration(days: 7));
    });
    _fetchTasks();
  }

  // Go to next week
  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
      _currentWeekEnd = _currentWeekEnd.add(const Duration(days: 7));
    });
    _fetchTasks();
  }

  // Format week range for display
  String _getWeekRangeText() {
    final dateFormat = DateFormat('MMM dd');
    return '${dateFormat.format(_currentWeekStart)} - ${dateFormat.format(_currentWeekEnd)}';
  }

  // Group tasks by day
  void _groupTasksByDay(List<Task> tasks) {
    _tasksByDay.clear();

    print('DEBUG: Grouping ${tasks.length} tasks');
    print('DEBUG: Week range: $_currentWeekStart to $_currentWeekEnd');

    // Initialize all days (Mon-Sat) with empty lists
    for (int i = 0; i < 6; i++) {
      final day = _currentWeekStart.add(Duration(days: i));
      final dayKey = DateFormat('yyyy-MM-dd').format(day);
      _tasksByDay[dayKey] = [];
      print('DEBUG: Initialized day key: $dayKey');
    }

    // Group tasks by their date
    for (var task in tasks) {
      if (task.date != null) {
        try {
          final taskDateStr = task.date!.split('T')[0]; // Get YYYY-MM-DD part
          print('DEBUG: Task "${task.title}" has date: $taskDateStr');

          if (_tasksByDay.containsKey(taskDateStr)) {
            _tasksByDay[taskDateStr]!.add(task);
            print('DEBUG: Added task to $taskDateStr (now has ${_tasksByDay[taskDateStr]!.length} tasks)');
          } else {
            print('DEBUG: Task date $taskDateStr not in current week keys: ${_tasksByDay.keys.toList()}');
          }
        } catch (e) {
          print('DEBUG: Error parsing task date: ${task.date}');
        }
      }
    }

    print('DEBUG: Final grouping - ${_tasksByDay.length} days:');
    _tasksByDay.forEach((key, value) {
      print('DEBUG:   $key: ${value.length} tasks');
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  // Fetch tasks from API for the current week
  Future<void> _fetchTasks() async {
    print('DEBUG HomeScreen: _fetchTasks called for week $_currentWeekStart to $_currentWeekEnd');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('DEBUG HomeScreen: Calling taskService.getTasks with date range');
      final result = await _taskService.getTasks(
        startDate: _currentWeekStart,
        endDate: _currentWeekEnd,
      );

      print('DEBUG HomeScreen: Result received: $result');

      setState(() {
        _tasks.clear();
        _tasks.addAll(result['tasks'] as List<Task>);
        _groupTasksByDay(_tasks);
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

  // Convert hours and minutes to total hours (decimal)
  double _calculateTotalHours() {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutesInHours = _selectedMinutes / 60.0;
    return hours + minutesInHours;
  }

  // Format hours for display (e.g., 5.5 -> "5h 30m", 5.0 -> "5h")
  String _formatHours(double hours) {
    final wholeHours = hours.floor();
    final minutes = ((hours - wholeHours) * 60).round();

    if (minutes == 0) {
      return '${wholeHours}h';
    } else {
      return '${wholeHours}h ${minutes}m';
    }
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
          hours: _calculateTotalHours(),
          status: _selectedStatus,
          date: formattedDate,
          userId: userId,
          employeeName: employeeName,
          reason: '',
        );

        print('DEBUG: Creating task with data:');
        print('  title: ${_titleController.text}');
        print('  description: ${_descriptionController.text}');
        print('  hours: ${_calculateTotalHours()}');
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
        _selectedMinutes = 0;
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
    final formKey = GlobalKey<FormState>();
    final isLeaveTask = task.onLeave == true;
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    // Extract whole hours and minutes from double
    final wholeHours = task.hours.floor();
    final minutes = ((task.hours - wholeHours) * 60).round();
    final hoursController = TextEditingController(text: wholeHours.toString());
    final detailsController = TextEditingController(text: task.details ?? '');
    int selectedMinutes = minutes;
    String status = isLeaveTask ? 'leave' : task.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isLeaveTask ? 'Edit Leave' : 'Edit Task'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    enabled: !isLeaveTask,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    enabled: !isLeaveTask,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Description is required';
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
                          controller: hoursController,
                          enabled: !isLeaveTask,
                          decoration: const InputDecoration(
                            labelText: 'Hours',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Hours is required';
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
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: selectedMinutes,
                        decoration: const InputDecoration(
                          labelText: 'Minutes',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('00')),
                          DropdownMenuItem(value: 15, child: Text('15')),
                          DropdownMenuItem(value: 30, child: Text('30')),
                          DropdownMenuItem(value: 45, child: Text('45')),
                        ],
                        onChanged: isLeaveTask ? null : (value) {
                          setDialogState(() {
                            selectedMinutes = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isLeaveTask)
                  TextFormField(
                    initialValue: 'Leave',
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                  )
                else
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
                const SizedBox(height: 12),
                  TextFormField(
                    controller: detailsController,
                    decoration: const InputDecoration(
                      labelText: 'Details',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Details is required';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  // Calculate total hours from hours and minutes
                  final hours = int.tryParse(hoursController.text) ?? 0;
                  final totalHours = hours + (selectedMinutes / 60.0);

                  // Create updated task with all existing fields
                  final updatedTask = task.copyWith(
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    hours: totalHours,
                    status: status,
                    details: detailsController.text.trim(),
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
                          DropdownMenuItem(value: 0, child: Text('00')),
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
      drawer: const AppDrawer(currentRoute: 'tasks'),
      body: Column(
        children: [
          // Week navigation header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Your Tasks',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_tasks.length} tasks',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Week navigation controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: _previousWeek,
                      tooltip: 'Previous Week',
                    ),
                    Column(
                      children: [
                        Text(
                          _getWeekRangeText(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Mon - Sat',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: _nextWeek,
                      tooltip: 'Next Week',
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Task list
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
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tasksByDay.length,
                        itemBuilder: (context, index) {
                          final dayDate = _currentWeekStart.add(Duration(days: index));
                          final dayKey = DateFormat('yyyy-MM-dd').format(dayDate);
                          final dayTasks = _tasksByDay[dayKey] ?? [];

                          // Format day as "Nov 14 Friday"
                          final dayHeader = DateFormat('MMM dd EEEE').format(dayDate);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Day header
                              Padding(
                                padding: EdgeInsets.only(bottom: 8, top: index == 0 ? 0 : 16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      dayHeader,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: dayTasks.isEmpty
                                            ? Colors.grey[200]
                                            : Colors.deepPurple[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${dayTasks.length}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: dayTasks.isEmpty
                                              ? Colors.grey[600]
                                              : Colors.deepPurple[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Tasks for this day or empty state
                              if (dayTasks.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.event_available, color: Colors.grey[400], size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'No tasks scheduled',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ...dayTasks.map((task) => Card(
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
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 16,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatHours(task.hours),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
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
                                                  borderRadius: BorderRadius.circular(12),
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
                                  ),
                                ),
                            ],
                          );
                        },
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
