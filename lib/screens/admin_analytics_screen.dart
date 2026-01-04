// lib/screens/admin_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'employee_detail_screen.dart';
import '../models/leave_model.dart'; // optional: if you want typed conversion

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final _fire = FirebaseFirestore.instance;
  final DateFormat monthFmt = DateFormat.yMMM();

  // Helper to try parse possible string dates or timestamps
  DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
    if (val is String) {
      return DateTime.tryParse(val);
    }
    return null;
  }

  // Build a simple small bar for the month values (widget)
Widget _monthBars(Map<String, int> data) {
  if (data.isEmpty) return const SizedBox();

  final maxVal = data.values.isNotEmpty ? data.values.reduce((a, b) => a > b ? a : b) : 0;

  return SizedBox(
    height: 120, // smaller than before
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.entries.map((e) {
          final label = e.key;
          final val = e.value;
          // cap bar height to 100 so it can't push layout
          final double barHeight = maxVal == 0 ? 8.0 : ((val / maxVal) * 80.0).clamp(8.0, 100.0);
          return Container(
            width: 64, // slightly narrower
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade400,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10), // smaller font
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  val.toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ),
  );
}


  // Build small stat card
  Widget _statCard(String label, String value, {Color? color}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color ?? Colors.black)),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pending_actions),
            tooltip: 'Pending leaves',
            onPressed: () {
              // go to AdminDashboard or filter view if you have a route
              Navigator.pop(context); // fallback depends on your nav structure
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fire.collection('leaves').orderBy('startDate', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Error loading analytics'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          // Compute totals
          int total = docs.length;
          int pending = 0, approved = 0, rejected = 0;
          int thisMonthCount = 0;

          // month aggregation for last 6 months
          final now = DateTime.now();
          final monthBuckets = <String, int>{};
          for (int i = 5; i >= 0; i--) {
            final d = DateTime(now.year, now.month - i, 1);
            monthBuckets[monthFmt.format(d)] = 0;
          }

          for (final d in docs) {
            final data = d.data() as Map<String, dynamic>;
            final status = (data['status'] ?? '').toString();
            if (status.toLowerCase() == 'pending') pending++;
            else if (status.toLowerCase() == 'approved') approved++;
            else if (status.toLowerCase() == 'rejected') rejected++;

            // parse start date
            final start = _parseDate(data['startDate']);
            if (start != null) {
              if (start.year == now.year && start.month == now.month) thisMonthCount++;
              final key = monthFmt.format(DateTime(start.year, start.month, 1));
              if (monthBuckets.containsKey(key)) monthBuckets[key] = (monthBuckets[key] ?? 0) + 1;
            }
          }

          // recent leaves list (limit 6)
          final recent = docs.take(6).map((d) {
            final m = d.data() as Map<String, dynamic>;
            return {
              'id': d.id,
              'name': m['name'] ?? 'Unknown',
              'reason': m['reason'] ?? '-',
              'startDate': _parseDate(m['startDate'])?.toIso8601String() ?? '',
              'status': m['status'] ?? '',
              'uid': m['uid'] ?? null,
            };
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // top stats row
                Row(
                  children: [
                    Expanded(child: _statCard('Total leaves', total.toString())),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Pending', pending.toString(), color: Colors.orange)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('Approved', approved.toString(), color: Colors.green)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _statCard('Rejected', rejected.toString(), color: Colors.red)),
                    const SizedBox(width: 8),
                    Expanded(child: _statCard('This month', thisMonthCount.toString())),
                    const SizedBox(width: 8),
                    Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [const Text('Avg per month'), const SizedBox(height:6), Text(((total / 6).round()).toString(), style: const TextStyle(fontSize:16,fontWeight:FontWeight.bold))])))),
                  ],
                ),

                const SizedBox(height: 16),

                const Text('Leaves — last 6 months', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _monthBars(monthBuckets),

                const SizedBox(height: 16),
                const Text('Recent leaves', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                // recent list
                ...recent.map((r) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(r['name'] ?? ''),
                      subtitle: Text('${r['reason']}\n${r['startDate'] != '' ? DateTime.tryParse(r['startDate'])?.toLocal().toString().split(' ').first ?? '' : ''}'),
                      isThreeLine: true,
                      trailing: Text(r['status'] ?? ''),
                      onTap: () {
                        // if you have EmployeeDetail or LeaveDetail, navigate appropriately
                      },
                    ),
                  );
                }).toList(),

                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Open Admin Dashboard'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
