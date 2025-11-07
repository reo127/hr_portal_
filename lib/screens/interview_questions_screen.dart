import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../services/interview_service.dart';
import '../models/interview_stats.dart';
import '../models/interview.dart';
import 'package:intl/intl.dart';

class InterviewQuestionsScreen extends StatefulWidget {
  const InterviewQuestionsScreen({super.key});

  @override
  State<InterviewQuestionsScreen> createState() => _InterviewQuestionsScreenState();
}

class _InterviewQuestionsScreenState extends State<InterviewQuestionsScreen> {
  final InterviewService _interviewService = InterviewService();
  final TextEditingController _searchController = TextEditingController();
  InterviewStats? _stats;
  List<Interview> _interviews = [];
  InterviewPagination? _pagination;
  bool _isLoading = true;
  bool _isLoadingInterviews = false;
  String? _errorMessage;
  int _currentPage = 1;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    // Just trigger rebuild to show/hide clear button
    setState(() {});
  }

  void _performSearch() {
    if (_searchQuery != _searchController.text) {
      setState(() {
        _searchQuery = _searchController.text;
        _currentPage = 1; // Reset to first page on search
      });
      _loadInterviews();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _interviewService.getInterviewStats();
      final interviewsData = await _interviewService.getInterviews(
        page: _currentPage,
        search: _searchQuery,
      );

      setState(() {
        _stats = stats;
        _interviews = interviewsData['interviews'] as List<Interview>;
        _pagination = interviewsData['pagination'] as InterviewPagination;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInterviews() async {
    setState(() {
      _isLoadingInterviews = true;
    });

    try {
      final interviewsData = await _interviewService.getInterviews(
        page: _currentPage,
        search: _searchQuery,
      );

      setState(() {
        _interviews = interviewsData['interviews'] as List<Interview>;
        _pagination = interviewsData['pagination'] as InterviewPagination;
        _isLoadingInterviews = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoadingInterviews = false;
      });
    }
  }

  void _nextPage() {
    if (_pagination != null && _currentPage < _pagination!.totalPages) {
      setState(() {
        _currentPage++;
      });
      _loadInterviews();
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _loadInterviews();
    }
  }

  void _showAddInterviewDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Interview'),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Interview form will be implemented here.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement save functionality
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showInterviewDetails(Interview interview) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    String formattedDate = '';
    try {
      formattedDate = dateFormatter.format(DateTime.parse(interview.date));
    } catch (e) {
      formattedDate = interview.date;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Interview Details',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Client Name', interview.clientName),
                        const SizedBox(height: 16),
                        _buildDetailRow('Date', formattedDate),
                        const SizedBox(height: 16),
                        _buildDetailRow('Job Role', interview.jobRole),
                        const SizedBox(height: 16),
                        _buildDetailRow('Employee Name', interview.employeeName),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text(
                              'Status: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            _buildStatusChip(interview.status),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Questions:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            interview.questions,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'notavailable':
      case 'not available':
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
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interview Questions'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: const AppDrawer(currentRoute: 'interview_questions'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Add New Interview Button
                      ElevatedButton.icon(
                        onPressed: _showAddInterviewDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add New Interview'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Stats Grid (Compact)
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              title: 'Total',
                              value: _stats?.total ?? 0,
                              icon: Icons.assessment,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Accepted',
                              value: _stats?.accepted ?? 0,
                              icon: Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              title: 'Rejected',
                              value: _stats?.rejected ?? 0,
                              icon: Icons.cancel,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              title: 'N/A',
                              value: _stats?.notAvailable ?? 0,
                              icon: Icons.help_outline,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Search Field
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: (_) => _performSearch(),
                              decoration: InputDecoration(
                                hintText: 'Search by Employee, Client, Job Role, Date(dd-mm-yyyy)',
                                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                          _performSearch();
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _performSearch,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Search'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Interviews List Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Interviews',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_pagination != null)
                            Text(
                              'Page ${_pagination!.currentPage} of ${_pagination!.totalPages}',
                              style: const TextStyle(fontSize: 14),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Interviews List
                      Expanded(
                        child: _isLoadingInterviews
                            ? const Center(child: CircularProgressIndicator())
                            : _interviews.isEmpty
                                ? const Center(
                                    child: Text('No interviews found'),
                                  )
                                : ListView.builder(
                                    itemCount: _interviews.length,
                                    itemBuilder: (context, index) {
                                      final interview = _interviews[index];
                                      String formattedDate = '';
                                      try {
                                        formattedDate = dateFormatter.format(
                                            DateTime.parse(interview.date));
                                      } catch (e) {
                                        formattedDate = interview.date;
                                      }

                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        child: ListTile(
                                          onTap: () => _showInterviewDetails(interview),
                                          leading: CircleAvatar(
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            child: Text(
                                              interview.serialNumber.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            interview.jobRole,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 4),
                                              Text(
                                                '${interview.clientName} • $formattedDate',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                interview.employeeName,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: _buildStatusChip(
                                            interview.status,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                      // Pagination Controls
                      if (_pagination != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _currentPage > 1 ? _previousPage : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Page $_currentPage of ${_pagination!.totalPages}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: _currentPage < _pagination!.totalPages
                                  ? _nextPage
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
    );
  }
}
