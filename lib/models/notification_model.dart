import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic>? meta;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.meta,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];

    return AppNotification(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      read: map['read'] ?? false,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      meta: map['meta'],
    );
  }
}

