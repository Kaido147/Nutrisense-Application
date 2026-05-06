import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrisense/pages/study/study_task_document.dart';

void main() {
  group('StudyTaskDocument.fromFirestore', () {
    test('parses sparse documents safely', () {
      final StudyTaskDocument document = StudyTaskDocument.fromMap(
        'task-1',
        <String, dynamic>{'title': '  Read chapter 4  ', 'isCompleted': true},
      );

      expect(document.id, 'task-1');
      expect(document.title, 'Read chapter 4');
      expect(document.description, isNull);
      expect(document.isCompleted, isTrue);
      expect(document.createdAt, isNull);
      expect(document.updatedAt, isNull);
      expect(document.dueAt, isNull);
    });

    test('falls back when title is missing', () {
      final StudyTaskDocument document =
          StudyTaskDocument.fromMap('task-2', <String, dynamic>{
            'description': 'Review flashcards',
            'createdAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
          });

      expect(document.title, 'Untitled task');
      expect(document.createdAt, DateTime(2026, 1, 2));
    });
  });
}
