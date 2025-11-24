import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/app_drawer.dart';
import '../services/leave_service.dart';
import '../services/auth_service.dart';
import '../services/holiday_service.dart';
import '../models/leave_balance.dart';
import '../models/leave.dart';
import '../models/holiday.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final LeaveService _leaveService = LeaveService();
  final AuthService _authService = AuthService();
  final HolidayService _holidayService = HolidayService();
  LeaveBalance? _leaveBalance;
  List<Leave> _leaveHistory = [];
  List<Holiday> _holidays = [];
  bool _isLoading = true;
  bool _isLoadingHistory = false;
  String? _errorMessage;

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Leave> _allCalendarLeaves = [];
  Map<DateTime, List<Leave>> _leaveEvents = {};

  // Form controllers and state
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  String? _selectedLeaveType;
  String _selectedSession = 'fullDay';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = await _authService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      print('DEBUG: Current user ID: ${user.userId}');

      final leaveBalance = await _leaveService.getLeaveBalance(user.userId);
      final leaveHistory = await _leaveService.getAllLeaves(user.userId);
      final calendarLeaves = await _leaveService.getAllLeavesForCalendar();

      List<Holiday> holidays = [];
      try {
        holidays = await _holidayService.getAllHolidays();
        print('DEBUG: Holidays fetched successfully: ${holidays.length}');
      } catch (e) {
        print('DEBUG: Error fetching holidays: $e');
        // Don't fail the whole screen if holidays fail
      }

      print('DEBUG: Leave history count: ${leaveHistory.length}');
      print('DEBUG: Calendar leaves count: ${calendarLeaves.length}');
      print('DEBUG: Holidays count: ${holidays.length}');

      // Build events map for calendar
      final eventsMap = <DateTime, List<Leave>>{};
      for (var leave in calendarLeaves) {
        try {
          final startDate = DateTime.parse(leave.startDate);
          final endDate = DateTime.parse(leave.endDate);

          // Add leave to each day in the range
          for (var day = startDate; day.isBefore(endDate.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
            final normalizedDay = DateTime(day.year, day.month, day.day);
            if (eventsMap[normalizedDay] == null) {
              eventsMap[normalizedDay] = [];
            }
            eventsMap[normalizedDay]!.add(leave);
          }
        } catch (e) {
          print('DEBUG: Error parsing leave dates: $e');
        }
      }

      setState(() {
        _leaveBalance = leaveBalance;
        _leaveHistory = leaveHistory;
        _allCalendarLeaves = calendarLeaves;
        _leaveEvents = eventsMap;
        _holidays = holidays;
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Error in _fetchData: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildCompactLeaveCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'applied':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Calendar helper methods
  List<Leave> _getEventsForDay(DateTime day) {
    // Skip weekends - return empty list for Saturday and Sunday
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return [];
    }

    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _leaveEvents[normalizedDay] ?? [];
  }

  // Get unique employee count for a day (Monday-Friday only)
  int _getUniqueEmployeeCount(DateTime day) {
    // Skip weekends (Saturday = 6, Sunday = 7)
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return 0;
    }

    final leaves = _getEventsForDay(day);
    if (leaves.isEmpty) return 0;

    // Count unique employees
    final uniqueUserIds = <String>{};
    for (var leave in leaves) {
      uniqueUserIds.add(leave.userId.id);
    }
    return uniqueUserIds.length;
  }

  // Show dialog with employees on leave for selected day
  void _showEmployeesOnLeave(DateTime day) {
    // Skip weekends
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return;
    }

    final leaves = _getEventsForDay(day);
    if (leaves.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No employees on leave this day')),
      );
      return;
    }

    // Group leaves by employee to avoid duplicates
    final Map<String, Leave> employeeLeaves = {};
    for (var leave in leaves) {
      if (!employeeLeaves.containsKey(leave.userId.id)) {
        employeeLeaves[leave.userId.id] = leave;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Employees on Leave - ${_formatDate(day.toString())}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: employeeLeaves.values.map((leave) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.userId.employeeName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            leave.getLeaveTypeDisplay(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(leave.getStatusDisplay()),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showLeaveDetails(Leave leave) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Details - ${leave.getLeaveTypeDisplay()}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', leave.getLeaveTypeDisplay()),
              const Divider(),
              _buildDetailRow('Applied Date', _formatDate(leave.appliedDate)),
              const Divider(),
              _buildDetailRow('From', _formatDate(leave.startDate)),
              const Divider(),
              _buildDetailRow('To', _formatDate(leave.endDate)),
              const Divider(),
              _buildDetailRow('Days', '${leave.totalDays} day(s)'),
              const Divider(),
              _buildDetailRow('Session', leave.session),
              const Divider(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 100,
                    child: Text(
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildStatusChip(leave.getStatusDisplay()),
                ],
              ),
              const Divider(),
              _buildDetailRow('Reason', leave.reason.isNotEmpty ? leave.reason : 'N/A'),
              if (leave.rejectionReason != null && leave.rejectionReason!.isNotEmpty) ...[
                const Divider(),
                _buildDetailRow('Rejection Reason', leave.rejectionReason!),
              ],
              const Divider(),
              _buildDetailRow('Manager', leave.manager.employeeName.isNotEmpty ? leave.manager.employeeName : 'N/A'),
              if (leave.approvedByName != null && leave.approvedByName!.isNotEmpty) ...[
                const Divider(),
                _buildDetailRow('Action By', leave.approvedByName!),
              ],
              if (leave.approvedDate != null && leave.approvedDate!.isNotEmpty) ...[
                const Divider(),
                _buildDetailRow('Action Date', _formatDate(leave.approvedDate!)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submitLeaveApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      final user = await _authService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      if (_selectedLeaveType == null) {
        throw Exception('Please select a leave type');
      }

      await _leaveService.applyLeave(
        userId: user.userId,
        leaveType: _selectedLeaveType!,
        startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
        endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
        session: _selectedSession,
        reason: _reasonController.text,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave application submitted successfully')),
        );
        // Refresh data
        _fetchData();
        // Reset form
        _reasonController.clear();
        _startDate = null;
        _endDate = null;
        _selectedLeaveType = null;
        _selectedSession = 'fullDay';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  int _getLeaveBalance(String leaveType) {
    if (_leaveBalance == null) return 0;

    switch (leaveType) {
      case 'casualLeave':
        // CL and SL are combined
        return _leaveBalance!.casualLeave + _leaveBalance!.sickLeave;
      case 'earnedLeave':
        return _leaveBalance!.earnedLeave;
      case 'compensatoryLeave':
        return _leaveBalance!.compLeaveDetails.total;
      case 'bereavementLeave':
        return _leaveBalance!.bereavementLeave;
      case 'lop':
        return 999; // LOP is always available
      default:
        return 0;
    }
  }

  bool _isLeaveTypeAvailable(String leaveType) {
    return _getLeaveBalance(leaveType) > 0;
  }

  String _getFirstAvailableLeaveType() {
    final leaveTypes = ['casualLeave', 'earnedLeave', 'compensatoryLeave', 'bereavementLeave', 'lop'];
    for (var type in leaveTypes) {
      if (_isLeaveTypeAvailable(type)) {
        return type;
      }
    }
    return 'lop'; // Default to LOP if nothing else available
  }

  void _showApplyLeaveDialog() {
    // Set initial leave type to first available
    _selectedLeaveType = _getFirstAvailableLeaveType();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Apply for Leave'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Leave Type', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedLeaveType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                        value: 'casualLeave',
                        enabled: _isLeaveTypeAvailable('casualLeave'),
                        child: Text(
                          'CL/SL (${_getLeaveBalance('casualLeave')})',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isLeaveTypeAvailable('casualLeave') ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'earnedLeave',
                        enabled: _isLeaveTypeAvailable('earnedLeave'),
                        child: Text(
                          'Earned Leave (${_getLeaveBalance('earnedLeave')})',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isLeaveTypeAvailable('earnedLeave') ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'compensatoryLeave',
                        enabled: _isLeaveTypeAvailable('compensatoryLeave'),
                        child: Text(
                          'Comp-Off (${_getLeaveBalance('compensatoryLeave')})',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isLeaveTypeAvailable('compensatoryLeave') ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'bereavementLeave',
                        enabled: _isLeaveTypeAvailable('bereavementLeave'),
                        child: Text(
                          'Bereavement Leave (${_getLeaveBalance('bereavementLeave')})',
                          style: TextStyle(
                            fontSize: 14,
                            color: _isLeaveTypeAvailable('bereavementLeave') ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                      const DropdownMenuItem(
                        value: 'lop',
                        child: Text('Loss of Pay', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedLeaveType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Start Date', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context, true).then((_) => setDialogState(() {})),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _startDate != null ? DateFormat('MMM dd, yyyy').format(_startDate!) : 'Select start date',
                        style: TextStyle(color: _startDate != null ? Colors.black : Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('End Date', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _selectDate(context, false).then((_) => setDialogState(() {})),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _endDate != null ? DateFormat('MMM dd, yyyy').format(_endDate!) : 'Select end date',
                        style: TextStyle(color: _endDate != null ? Colors.black : Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Session', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSession,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'fullDay', child: Text('Full Day')),
                      DropdownMenuItem(value: 'firstHalf', child: Text('First Half')),
                      DropdownMenuItem(value: 'secondHalf', child: Text('Second Half')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        _selectedSession = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Reason', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter reason for leave',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a reason';
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
              onPressed: _isSubmitting ? null : () {
                Navigator.pop(context);
                _reasonController.clear();
                _startDate = null;
                _endDate = null;
                _selectedLeaveType = null;
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitLeaveApplication,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showHolidayListDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Holiday List 2025'),
        content: SizedBox(
          width: double.maxFinite,
          child: _holidays.isEmpty
              ? const Center(child: Text('No holidays found'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _holidays.length,
                  itemBuilder: (context, index) {
                    final holiday = _holidays[index];
                    final date = DateTime.parse(holiday.date);
                    final dayOfWeek = DateFormat('EEEE').format(date);
                    final formattedDate = DateFormat('dd MMM yyyy').format(date);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.celebration,
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          holiday.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '$formattedDate • $dayOfWeek',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showApplyCompOffDialog() {
    // Placeholder for comp-off application
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apply Comp-Off feature coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const AppDrawer(currentRoute: 'leave_management'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Action Buttons Section
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _showApplyCompOffDialog,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: const Color(0xFF3F8E7E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Apply Comp-Off',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _showHolidayListDialog,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: const Color(0xFF3F8E7E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Holiday List',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _fetchData,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  backgroundColor: const Color(0xFF3F8E7E),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Refresh',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // Leave Calendar Section
                    Container(
                      margin: const EdgeInsets.all(16.0),
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        eventLoader: _getEventsForDay,
                        calendarFormat: CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.sunday,
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          // Show employees on leave dialog
                          _showEmployeesOnLeave(selectedDay);
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarBuilders: CalendarBuilders(
                          markerBuilder: (context, day, events) {
                            final count = _getUniqueEmployeeCount(day);
                            if (count == 0) return null;

                            return Positioned(
                              bottom: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    // Leave Balance Section - Compact Grid
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Leave Balance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactLeaveCard(
                                  title: 'CL/SL',
                                  count: (_leaveBalance!.casualLeave + _leaveBalance!.sickLeave),
                                  color: const Color(0xFF2196F3),
                                  icon: Icons.medical_services,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactLeaveCard(
                                  title: 'Earned',
                                  count: _leaveBalance!.earnedLeave,
                                  color: const Color(0xFF4CAF50),
                                  icon: Icons.event_available,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactLeaveCard(
                                  title: 'Comp-Off',
                                  count: _leaveBalance!.compLeaveDetails.total,
                                  color: const Color(0xFFFF9800),
                                  icon: Icons.swap_horiz,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildCompactLeaveCard(
                                  title: 'Bereavement',
                                  count: _leaveBalance!.bereavementLeave,
                                  color: const Color(0xFF9C27B0),
                                  icon: Icons.favorite,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildCompactLeaveCard(
                            title: 'Loss of Pay (This Month)',
                            count: _leaveBalance!.currentMonthLOP,
                            color: const Color(0xFFF44336),
                            icon: Icons.money_off,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Apply Leave Button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showApplyLeaveDialog,
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Apply for Leave',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: const Color(0xFF365e7d),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    // Leave History Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Leave History',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_leaveHistory.length} leave(s)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _leaveHistory.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(
                              child: Text(
                                'No leave history found',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                            itemCount: _leaveHistory.length,
                            itemBuilder: (context, index) {
                                final leave = _leaveHistory[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () => _showLeaveDetails(leave),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  leave.getLeaveTypeDisplay(),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              _buildStatusChip(leave.getStatusDisplay()),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${_formatDate(leave.startDate)} - ${_formatDate(leave.endDate)}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${leave.totalDays} day(s)',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.event_available, size: 14, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Applied: ${_formatDate(leave.appliedDate)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (leave.reason.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              leave.reason,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  ],
                ),
              ),
    );
  }
}
