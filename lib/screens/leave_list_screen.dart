// lib/screens/leave_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/leave_provider.dart';
import '../models/leave_model.dart';
import 'leave_detail_screen.dart';
import 'apply_leave_screen.dart';
import '../widgets/status_chip.dart';

class LeaveListScreen extends StatefulWidget {
  const LeaveListScreen({Key? key}) : super(key: key);

  @override
  State<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen> {
  @override
  void initState() {
    super.initState();

    // ✅ FORCE START LISTENING HERE AS BACKUP
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<LeaveProvider>(context, listen: false);
      provider.startListening(); // admin handled inside provider
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaveProvider = Provider.of<LeaveProvider>(context);

    debugPrint("📊 LEAVE LIST UI COUNT = ${leaveProvider.leaveList.length}");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaves'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApplyLeaveScreen()),
              );
            },
          ),
        ],
      ),
      body: leaveProvider.leaveList.isEmpty
          ? const Center(child: Text('No leaves yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: leaveProvider.leaveList.length,
              itemBuilder: (context, index) {
                final item = leaveProvider.leaveList[index];

                Color statusColor = item.status == 'Pending'
                    ? Colors.orange
                    : (item.status == 'Approved'
                        ? Colors.green
                        : Colors.red);

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LeaveDetailScreen(leave: item),
                        ),
                      );
                    },
                    title: Text(item.reason,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${item.startDate} → ${item.endDate}\nBy: ${item.name}'),
                    isThreeLine: true,
                    trailing: StatusChip(status: item.status),

                  ),
                );
              },
            ),
    );
  }
}


