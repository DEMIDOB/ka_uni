import 'dart:convert';
import 'dart:math';

import 'package:kit_mobile/timetable/models/timetable_appointment.dart';
import 'package:kit_mobile/timetable/models/timetable_daily.dart';
import 'package:kit_mobile/timetable/models/timetable_weekly.dart';

class Tutorial extends TimetableAppointment {
  final String tutorialId;
  final String moduleId;
  final String moduleTitle;
  final Weekday weekday;
  final int blockIndex;
  final String semesterString;
  final String? notes;

  Tutorial({
    required this.tutorialId,
    required this.moduleId,
    required this.moduleTitle,
    required this.weekday,
    required this.blockIndex,
    required this.semesterString,
    this.notes,
  }) : super(
          begin: _blockTemplate(blockIndex).begin,
          end: _blockTemplate(blockIndex).end,
          type: TimetableAppointmentType.tutorial,
        ) {
    id = moduleId;
    title = moduleTitle;
  }

  static const Object _noValue = Object();

  Tutorial copyWith({
    String? tutorialId,
    String? moduleId,
    String? moduleTitle,
    Weekday? weekday,
    int? blockIndex,
    String? semesterString,
    Object? notes = _noValue,
  }) {
    final resolvedBlockIndex = blockIndex ?? this.blockIndex;
    if (!_isValidBlockIndex(resolvedBlockIndex)) {
      throw ArgumentError('Invalid tutorial block index: $resolvedBlockIndex');
    }

    final resolvedNotes = identical(notes, _noValue)
        ? this.notes
        : _normalizeNotes(notes as String?);

    return Tutorial(
      tutorialId: tutorialId ?? this.tutorialId,
      moduleId: moduleId ?? this.moduleId,
      moduleTitle: moduleTitle ?? this.moduleTitle,
      weekday: weekday ?? this.weekday,
      blockIndex: resolvedBlockIndex,
      semesterString: semesterString ?? this.semesterString,
      notes: resolvedNotes,
    );
  }

  static String? _normalizeNotes(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> toMap() => {
        'tutorialId': tutorialId,
        'moduleId': moduleId,
        'moduleTitle': moduleTitle,
        'weekday': weekday.idx,
        'blockIndex': blockIndex,
        'semesterString': semesterString,
        'notes': notes,
      };

  String encode() => jsonEncode(toMap());

  static Tutorial? fromMap(Map<String, dynamic> map) {
    final tutorialId = map['tutorialId'];
    final moduleId = map['moduleId'];
    final moduleTitle = map['moduleTitle'];
    final weekdayIdx = map['weekday'];
    final blockIndex = map['blockIndex'];
    final semesterString = map['semesterString'];
    final notes = map['notes'];

    if (tutorialId is! String ||
        moduleId is! String ||
        moduleTitle is! String ||
        weekdayIdx is! int ||
        blockIndex is! int ||
        semesterString is! String) {
      return null;
    }

    if (!_isValidBlockIndex(blockIndex)) {
      return null;
    }

    final weekday = Weekday.monday.fromInt(weekdayIdx);

    return Tutorial(
      tutorialId: tutorialId,
      moduleId: moduleId,
      moduleTitle: moduleTitle,
      weekday: weekday,
      blockIndex: blockIndex,
      semesterString: semesterString,
      notes: notes is String && notes.trim().isNotEmpty ? notes : null,
    );
  }

  static Tutorial? tryDecode(String encoded) {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map<String, dynamic>) {
        return Tutorial.fromMap(decoded);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static Tutorial createNew({
    required String moduleId,
    required String moduleTitle,
    required Weekday weekday,
    required int blockIndex,
    required String semesterString,
    String? notes,
  }) {
    final uniqueSuffix =
        DateTime.now().microsecondsSinceEpoch.toString().padLeft(6, '0');
    final random = Random().nextInt(99999).toString().padLeft(5, '0');
    final tutorialId = 'tutorial_${moduleId}_$uniqueSuffix$random';
    final sanitizedModuleTitle =
        moduleTitle.trim().isEmpty ? moduleTitle : moduleTitle.trim();
    final sanitizedNotes = _normalizeNotes(notes);

    return Tutorial(
      tutorialId: tutorialId,
      moduleId: moduleId,
      moduleTitle: sanitizedModuleTitle,
      weekday: weekday,
      blockIndex: blockIndex,
      semesterString: semesterString,
      notes: sanitizedNotes,
    );
  }

  static TimetableAppointment _blockTemplate(int blockIndex) {
    final schedule = TimetableDaily.genericAppointmentsSchedule;
    if (!_isValidBlockIndex(blockIndex)) {
      throw ArgumentError('Invalid tutorial block index: $blockIndex');
    }
    return schedule[blockIndex];
  }

  static bool _isValidBlockIndex(int blockIndex) {
    if (blockIndex < 0 ||
        blockIndex >= TimetableDaily.genericAppointmentsSchedule.length) {
      return false;
    }

    final template = TimetableDaily.genericAppointmentsSchedule[blockIndex];
    return template.type != TimetableAppointmentType.lunchBreak;
  }
}
