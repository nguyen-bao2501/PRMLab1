import 'package:flutter_test/flutter_test.dart';
import 'package:prm/screens/teaching_schedule.dart';

void main() {
  test('Attendance is available only inside the scheduled slot', () {
    final start = DateTime(2026, 9, 23, 7);
    final lesson = {
      'status': 'SCHEDULED',
      'startTime': start.toIso8601String(),
    };
    expect(
      canOpenLesson(lesson, start.subtract(const Duration(seconds: 1))),
      false,
    );
    expect(canOpenLesson(lesson, start), true);
    expect(
      canOpenLesson(lesson, start.add(const Duration(minutes: 135))),
      false,
    );
    expect(canOpenLesson({...lesson, 'status': 'CLOSED'}, start), false);
    expect(lessonSlot(lesson), 0);
    expect(
      lessonSlot({'startTime': DateTime(2026, 9, 23, 9, 30).toIso8601String()}),
      1,
    );
  });
  test(
    'Absence ranking includes present records in each student denominator',
    () {
      final ranked = rankAbsences([
        {'studentId': 1, 'status': 'ABSENT'},
        {'studentId': 1, 'status': 'PRESENT'},
        {'studentId': 2, 'status': 'ABSENT'},
        {'studentId': 2, 'status': 'ABSENT'},
        {'studentId': 3, 'status': 'LATE'},
      ]);
      expect(ranked.first['studentId'], 2);
      expect(ranked.first['absences'], 2);
      expect(ranked[1]['recorded'], 2);
      expect(ranked.last['absences'], 0);
    },
  );
}
