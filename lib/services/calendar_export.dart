import 'package:intl/intl.dart';

import '../l10n/strings.dart';
import '../models/enums.dart';
import '../state/workout_state.dart';
import 'calendar_bridge_stub.dart' if (dart.library.js_interop) 'calendar_bridge_web.dart' as bridge;

/// Puts a finished session on the user's own calendar: as a Google Calendar
/// event through its template link, or as an .ics file any calendar app
/// imports. Nothing is sent anywhere; the data stays in the link or the file.
class CalendarExport {
  const CalendarExport(this.detail, this.l, this.exerciseName);

  final SessionDetail detail;
  final L l;
  final String Function(int exerciseId) exerciseName;

  /// The .ics download is only offered where the file can be handed to the
  /// browser directly.
  static bool get canSaveFile => bridge.canSaveFile;

  DateTime get _start => detail.session.startedAt;
  DateTime get _end => detail.session.endedAt ?? _start.add(const Duration(minutes: 45));

  String get title {
    final names = detail.exerciseOrder.map(exerciseName).take(3).join(', ');
    final cardio = detail.cardio.map((c) => CardioType.parse(c.kind).label(l)).join(', ');
    final what = [if (names.isNotEmpty) names, if (cardio.isNotEmpty) cardio].join(' / ');
    final minutes = _end.difference(_start).inMinutes;
    return '${l.workoutLabel}: $what (${l.minutes(minutes)})';
  }

  String get description {
    final lines = <String>[];
    for (final id in detail.exerciseOrder) {
      final sets = detail.setsFor(id).map((s) => '${fmtKg(s.weightKg)}kg x ${s.reps}').join(', ');
      lines.add('${exerciseName(id)}: $sets');
    }
    for (final c in detail.cardio) {
      lines.add([
        CardioType.parse(c.kind).label(l),
        l.minutes(c.durationMin.round()),
        if (c.distanceKm != null) '${c.distanceKm}km',
        if (c.kcal != null) '${c.kcal}kcal',
      ].join(' '));
    }
    if (detail.session.note.isNotEmpty) lines.add(detail.session.note);
    return lines.join('\n');
  }

  static final _utc = DateFormat("yyyyMMdd'T'HHmmss'Z'");
  static String _stamp(DateTime t) => _utc.format(t.toUtc());

  Uri get googleUrl => Uri.https('calendar.google.com', '/calendar/render', {
        'action': 'TEMPLATE',
        'text': title,
        'dates': '${_stamp(_start)}/${_stamp(_end)}',
        'details': description,
      });

  String get ics {
    String esc(String v) =>
        v.replaceAll('\\', '\\\\').replaceAll(';', '\\;').replaceAll(',', '\\,').replaceAll('\n', '\\n');
    return [
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//gym//workout log//EN',
      'BEGIN:VEVENT',
      'UID:gym-session-${detail.session.id}@azs4n10.github.io',
      'DTSTAMP:${_stamp(DateTime.now())}',
      'DTSTART:${_stamp(_start)}',
      'DTEND:${_stamp(_end)}',
      'SUMMARY:${esc(title)}',
      'DESCRIPTION:${esc(description)}',
      'END:VEVENT',
      'END:VCALENDAR',
      '',
    ].join('\r\n');
  }

  Future<void> openGoogle() => bridge.openUrl(googleUrl.toString());

  Future<void> saveFile() {
    final day = DateFormat('yyyy-MM-dd').format(_start);
    return bridge.saveTextFile('gym-$day.ics', 'text/calendar', ics);
  }
}
