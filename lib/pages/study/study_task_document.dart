import 'package:cloud_firestore/cloud_firestore.dart';

import 'study_models.dart';

class StudyTaskDocument {
  const StudyTaskDocument({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    required this.completedAt,
    required this.dueAt,
  });

  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final DateTime? dueAt;

  factory StudyTaskDocument.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return StudyTaskDocument.fromMap(snapshot.id, snapshot.data());
  }

  factory StudyTaskDocument.fromMap(String id, Map<String, dynamic>? data) {
    final Map<String, dynamic> source = data ?? <String, dynamic>{};
    return StudyTaskDocument(
      id: id,
      title: _readString(source['title']) ?? 'Untitled task',
      description: _readString(source['description']),
      isCompleted: source['isCompleted'] is bool
          ? source['isCompleted'] as bool
          : false,
      createdAt: _readTimestamp(source['createdAt']),
      updatedAt: _readTimestamp(source['updatedAt']),
      completedAt: _readTimestamp(source['completedAt']),
      dueAt: _readTimestamp(source['dueAt']),
    );
  }

  StudyTask toStudyTask() {
    return StudyTask(
      id: id,
      title: title,
      subject: description ?? 'Study Task',
      isCompleted: isCompleted,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
      dueAt: dueAt,
    );
  }

  static String? _readString(Object? value) {
    if (value is String) {
      final String trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return null;
  }

  static DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
