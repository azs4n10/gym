import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/database.dart';
import 'google_auth_stub.dart' if (dart.library.js_interop) 'google_auth_web.dart' as auth;

/// One entry from the user's Google Calendar.
class CalEvent {
  const CalEvent({required this.id, required this.title, required this.start, required this.end, required this.allDay});
  final String id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
}

/// The user's own Google Calendar, read for the month on screen and written
/// to when a workout ends. The app talks to Google directly from the device
/// with a token Google hands the page; nothing goes through any other server.
class GoogleCalendar {
  /// Public identifier of this app's OAuth client (not a secret).
  static const clientId = '658780441236-aolni7ecpl2nsrgkn7uo250rqpb2f4ae.apps.googleusercontent.com';
  static const scope = 'https://www.googleapis.com/auth/calendar.events https://www.googleapis.com/auth/calendar.readonly';

  static bool get available => auth.available;

  String? _token;
  DateTime? _expires;

  bool get hasToken => _token != null && _expires != null && DateTime.now().isBefore(_expires!);

  Future<void> restore() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString('gcalToken');
    final ms = p.getInt('gcalExpires');
    _expires = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> _store() async {
    final p = await SharedPreferences.getInstance();
    if (_token == null) {
      await p.remove('gcalToken');
      await p.remove('gcalExpires');
    } else {
      await p.setString('gcalToken', _token!);
      await p.setInt('gcalExpires', _expires!.millisecondsSinceEpoch);
    }
  }

  /// Asks Google for a token; with [silent] only if consent was given before.
  Future<bool> connect({bool silent = false}) async {
    final r = await auth.requestToken(clientId, scope, silent: silent);
    if (r == null) return false;
    _token = r.$1;
    // A minute early, so a call never starts on a token about to lapse.
    _expires = DateTime.now().add(Duration(seconds: r.$2 - 60));
    await _store();
    return true;
  }

  Future<void> forget() async {
    _token = null;
    _expires = null;
    await _store();
  }

  Future<bool> _ensureToken() async {
    if (hasToken) return true;
    if (_token == null) return false;
    return connect(silent: true);
  }

  static String _stamp(DateTime t) => t.toUtc().toIso8601String();

  /// Events between [from] and [to] on the primary calendar, or null when
  /// Google could not be reached or the token is gone.
  Future<List<CalEvent>?> events(DateTime from, DateTime to) async {
    if (!await _ensureToken()) return null;
    final uri = Uri.https('www.googleapis.com', '/calendar/v3/calendars/primary/events', {
      'timeMin': _stamp(from),
      'timeMax': _stamp(to),
      'singleEvents': 'true',
      'orderBy': 'startTime',
      'maxResults': '250',
    });
    try {
      final res = await http.get(uri, headers: {'Authorization': 'Bearer $_token'}).timeout(const Duration(seconds: 15));
      if (res.statusCode == 401) {
        await forget();
        return null;
      }
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final items = (json['items'] as List? ?? []).cast<Map<String, dynamic>>();
      return [for (final i in items) if (_parse(i) case final e?) e];
    } catch (_) {
      return null;
    }
  }

  CalEvent? _parse(Map<String, dynamic> i) {
    if (i['status'] == 'cancelled') return null;
    final start = i['start'] as Map<String, dynamic>?;
    final end = i['end'] as Map<String, dynamic>?;
    if (start == null) return null;
    final allDay = start['date'] != null;
    DateTime? at(Map<String, dynamic>? m) {
      if (m == null) return null;
      final s = (m['dateTime'] ?? m['date']) as String?;
      return s == null ? null : DateTime.tryParse(s)?.toLocal();
    }

    final s = at(start);
    if (s == null) return null;
    return CalEvent(
      id: i['id'] as String? ?? '',
      title: (i['summary'] as String?)?.trim().isNotEmpty == true ? i['summary'] as String : '(untitled)',
      start: s,
      end: at(end),
      allDay: allDay,
    );
  }

  Future<bool> insert({required String title, required String description, required DateTime start, required DateTime end}) async {
    if (!await _ensureToken()) return false;
    final uri = Uri.https('www.googleapis.com', '/calendar/v3/calendars/primary/events');
    final body = jsonEncode({
      'summary': title,
      'description': description,
      'start': {'dateTime': _stamp(start)},
      'end': {'dateTime': _stamp(end)},
    });
    try {
      final res = await http
          .post(uri, headers: {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 401) await forget();
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}

/// What the screens watch: whether the calendar is connected, the events of
/// the months looked at, and the setting to write workouts automatically.
class CalendarState extends ChangeNotifier {
  final GoogleCalendar api = GoogleCalendar();
  final Map<String, List<CalEvent>> _months = {};
  final Set<String> _loading = {};
  bool _autoWrite = false;
  bool _busy = false;

  bool get available => GoogleCalendar.available;
  bool get connected => api.hasToken || api._token != null;
  bool get autoWrite => _autoWrite;
  bool get busy => _busy;

  Future<void> init() async {
    await api.restore();
    final p = await SharedPreferences.getInstance();
    _autoWrite = p.getBool('gcalAutoWrite') ?? false;
  }

  Future<bool> connect() async {
    _busy = true;
    notifyListeners();
    final ok = await api.connect();
    _busy = false;
    _months.clear();
    notifyListeners();
    return ok;
  }

  Future<void> disconnect() async {
    await api.forget();
    _months.clear();
    notifyListeners();
  }

  Future<void> setAutoWrite(bool v) async {
    _autoWrite = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('gcalAutoWrite', v);
    notifyListeners();
  }

  static String _key(DateTime month) => '${month.year}-${month.month}';

  /// Fetches the month (with a week either side) once; later calls for the
  /// same month are free until the connection changes.
  Future<void> loadMonth(DateTime month) async {
    final key = _key(month);
    if (!connected || _months.containsKey(key) || _loading.contains(key)) return;
    _loading.add(key);
    final from = DateTime(month.year, month.month, 1).subtract(const Duration(days: 7));
    final to = DateTime(month.year, month.month + 1, 1).add(const Duration(days: 7));
    final list = await api.events(from, to);
    _loading.remove(key);
    if (list != null) _months[key] = list;
    notifyListeners();
  }

  Set<DateTime> get eventDays => {
        for (final list in _months.values)
          for (final e in list) dayOf(e.start),
      };

  List<CalEvent> on(DateTime day) {
    final d = dayOf(day);
    final seen = <String>{};
    return [
      for (final list in _months.values)
        for (final e in list)
          if (dayOf(e.start) == d && seen.add(e.id)) e,
    ]..sort((a, b) => a.start.compareTo(b.start));
  }

  Future<bool> writeSession({required String title, required String description, required DateTime start, required DateTime end}) async {
    if (!connected) return false;
    final ok = await api.insert(title: title, description: description, start: start, end: end);
    if (ok) _months.clear();
    notifyListeners();
    return ok;
  }
}
