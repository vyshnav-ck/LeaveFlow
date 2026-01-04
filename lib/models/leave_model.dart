import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveModel {
  final String id;
  final String uid;
  final String name;
  final String reason;
  final String startDate;
  final String endDate;
  final int totalDays;
  final String status;
  final DateTime createdAt;
  final String? adminComment;
  final DateTime? reviewedAt;

  LeaveModel({
    required this.id,
    required this.uid,
    required this.name,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.status,
    required this.createdAt,
    this.adminComment,
    this.reviewedAt,
  });

  /// ✅ SAFE FIRESTORE PARSER
  factory LeaveModel.fromMap(String id, Map<String, dynamic> map) {
    return LeaveModel(
      id: id,
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      reason: map['reason'] ?? '',
      startDate: map['startDate'] ?? '',
      endDate: map['endDate'] ?? '',
      totalDays: (map['totalDays'] ?? 0) as int,
      status: map['status'] ?? 'Pending',

      // 🔥 THIS IS THE FIX
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] is DateTime
              ? map['createdAt']
              : DateTime.now(),

      adminComment: map['adminComment'],
      reviewedAt: map['reviewedAt'] is Timestamp
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// ✅ SAFE WRITE TO FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'reason': reason,
      'startDate': startDate,
      'endDate': endDate,
      'totalDays': totalDays,
      'status': status,
      'createdAt': createdAt,
      'adminComment': adminComment,
      'reviewedAt': reviewedAt,
    };
  }
}

