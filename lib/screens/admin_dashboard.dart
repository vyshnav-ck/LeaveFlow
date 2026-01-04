import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/leave_provider.dart';
import '../models/leave_model.dart';
import 'admin_users_screen.dart';
import 'admin_analytics_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _search = '';
  String _filter = 'All'; // All / Pending / Approved / Rejected
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ================= FILTER =================
  List<LeaveModel> _applyFilters(List<LeaveModel> list) {
    var filtered = list;

    if (_filter != 'All') {
      filtered = filtered.where((l) => l.status == _filter).toList();
    }

    if (_search.trim().isNotEmpty) {
      final q = _search.toLowerCase();
      filtered = filtered.where(
        (l) =>
            l.name.toLowerCase().contains(q) ||
            l.reason.toLowerCase().contains(q),
      ).toList();
    }

    return filtered;
  }

  // ================= REJECT WITH COMMENT =================
  Future<void> _rejectWithComment(
    BuildContext context,
    LeaveModel item,
  ) async {
    final commentCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject Leave'),
        content: TextField(
          controller: commentCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Provider.of<LeaveProvider>(context, listen: false)
          .updateLeaveStatusWithComment(
        leaveId: item.id,
        status: 'Rejected',
        comment: commentCtrl.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave rejected')),
      );
    }
  }

  // ================= CARD =================
  Widget _buildCard(BuildContext context, LeaveModel item) {
    Color statusColor = item.status == 'Pending'
        ? Colors.orange
        : (item.status == 'Approved'
            ? Colors.green
            : Colors.red);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text(
          item.reason,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${item.name}\n${item.startDate} → ${item.endDate}',
        ),
        isThreeLine: true,
        trailing: Text(
          item.status,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => _openActions(context, item),
      ),
    );
  }

  // ================= ACTION SHEET =================
  void _openActions(BuildContext context, LeaveModel item) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          children: [
            ListTile(title: Text('Name: ${item.name}')),
            ListTile(title: Text('Reason: ${item.reason}')),
            ListTile(title: Text('From: ${item.startDate}')),
            ListTile(title: Text('To: ${item.endDate}')),
            ListTile(title: Text('Days: ${item.totalDays}')),
            const SizedBox(height: 12),

            // ===== ADMIN ACTIONS =====
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await Provider.of<LeaveProvider>(
                        context,
                        listen: false,
                      ).updateLeaveStatusWithComment(
                        leaveId: item.id,
                        status: 'Approved',
                      );

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Approved')),
                      );
                    },
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _rejectWithComment(context, item);
                    },
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LeaveProvider>(context);
    final list = _applyFilters(provider.leaveList);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: 'Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminAnalyticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Employees',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminUsersScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by name or reason',
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filter,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                  ],
                  onChanged: (v) =>
                      setState(() => _filter = v ?? 'All'),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No leaves found'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (c, i) => _buildCard(c, list[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

