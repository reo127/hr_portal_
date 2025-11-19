import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/app_drawer.dart';
import '../services/leave_service.dart';
import '../services/auth_service.dart';
import '../models/leave_balance.dart';
import '../models/leave.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  final LeaveService _leaveService = LeaveService();
  final AuthService _authService = AuthService();
  LeaveBalance? _leaveBalance;
  List<Leave> _leaveHistory = [];
  bool _isLoading = true;
  bool _isLoadingHistory = false;
  String? _errorMessage;

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

      print('DEBUG: Leave history count: ${leaveHistory.length}');

      setState(() {
        _leaveBalance = leaveBalance;
        _leaveHistory = leaveHistory;
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    // Leave History Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                    const SizedBox(height: 12),
                    Expanded(
                      child: _leaveHistory.isEmpty
                          ? const Center(
                              child: Text(
                                'No leave history found',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                    ),
                  ],
                ),
    );
  }
}
