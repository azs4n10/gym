import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../services/health_sync.dart';

class BodyState extends ChangeNotifier {
  BodyState(this.db);

  final AppDatabase db;
  List<BodyLog> _logs = [];

  List<BodyLog> get logs => _logs;
  BodyLog? get latest => _logs.isEmpty ? null : _logs.first;
  double? get latestWeight => latest?.weightKg;

  BodyLog? logOn(DateTime day) {
    final d = dayOf(day);
    for (final l in _logs) {
      if (dayOf(l.date) == d) return l;
    }
    return null;
  }

  Future<void> load() async {
    _logs = await (db.select(db.bodyLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    notifyListeners();
  }

  Future<bool?> upsert({
    required DateTime day,
    required double weightKg,
    double? bodyFatPct,
    String note = '',
    bool syncHealth = false,
  }) async {
    final d = dayOf(day);
    var synced = false;
    if (syncHealth && HealthSync.instance.isSupported) {
      synced = await HealthSync.instance.writeBody(
        at: d.add(const Duration(hours: 7)),
        weightKg: weightKg,
        bodyFatPct: bodyFatPct,
      );
    }
    final existing = logOn(d);
    if (existing != null) {
      await db.update(db.bodyLogs).replace(existing.copyWith(
            weightKg: weightKg,
            bodyFatPct: Value(bodyFatPct),
            note: note,
            healthSynced: synced,
          ));
    } else {
      await db.into(db.bodyLogs).insert(BodyLogsCompanion.insert(
            date: d,
            weightKg: weightKg,
            bodyFatPct: Value(bodyFatPct),
            note: Value(note),
            healthSynced: Value(synced),
          ));
    }
    await load();
    return syncHealth ? synced : null;
  }

  Future<void> delete(BodyLog log) async {
    await (db.delete(db.bodyLogs)..where((t) => t.id.equals(log.id))).go();
    await load();
  }

  List<BodyLog> lastDays(int days) {
    final from = dayOf(DateTime.now()).subtract(Duration(days: days - 1));
    return _logs.where((l) => !l.date.isBefore(from)).toList().reversed.toList();
  }

  double? averageOver(int days) {
    final xs = lastDays(days);
    if (xs.isEmpty) return null;
    return xs.fold<double>(0, (s, l) => s + l.weightKg) / xs.length;
  }
}
