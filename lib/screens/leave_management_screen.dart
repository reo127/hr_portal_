import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../services/leave_service.dart';
import '../services/auth_service.dart';
import '../models/leave_balance.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final LeaveService _leaveService = LeaveService();
  final AuthService _authService = AuthService();
  LeaveBalance? _leaveBalance;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLeaveBalance();
  }

  Future<void> _fetchLeaveBalance() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final user = await _authService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final leaveBalance = await _leaveService.getLeaveBalance(user.userId);
      setState(() {
        _leaveBalance = leaveBalance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildLeaveBox({
    required String title,
    required int count,
    required Color color,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.43,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
                        onPressed: _fetchLeaveBalance,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [                      
                        const SizedBox(height: 0),
                        Wrap(
                          spacing: 12,
                          runSpacing: 0,
                          children: [
                            _buildLeaveBox(
                              title: 'Casual Leave/Sick Leave',
                              count: (_leaveBalance!.casualLeave + _leaveBalance!.sickLeave),
                              color: const Color(0xFF2196F3),
                            ),
                            _buildLeaveBox(
                              title: 'Earned Leave',
                              count: _leaveBalance!.earnedLeave,
                              color: const Color(0xFF4CAF50),
                            ),
                            _buildLeaveBox(
                              title: 'Comp-Off',
                              count: _leaveBalance!.compLeaveDetails.total,
                              color: const Color(0xFFFF9800),
                            ),
                            _buildLeaveBox(
                              title: 'Bereavement Leave',
                              count: _leaveBalance!.bereavementLeave,
                              color: const Color(0xFF9C27B0),
                            ),
                            _buildLeaveBox(
                              title: 'Loss of Pay (This Month)',
                              count: _leaveBalance!.currentMonthLOP,
                              color: const Color(0xFFF44336),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
