import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../l10n/strings.dart';
import '../models/enums.dart';

class HealthSync {
  HealthSync._();
  static final HealthSync instance = HealthSync._();

  Health? _health;
  bool _configured = false;

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  String platformName(L l) => isIOS ? l.appleHealth : l.healthConnect;

  static const _types = [
    HealthDataType.WORKOUT,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.NUTRITION,
    HealthDataType.STEPS,
  ];

  static const _access = [
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ_WRITE,
    HealthDataAccess.READ,
  ];

  Future<Health?> _ready() async {
    if (!isSupported) return null;
    if (!_configured) {
      _health = Health();
      await _health!.configure();
      _configured = true;
    }
    return _health;
  }

  Future<bool> requestPermissions() async {
    final h = await _ready();
    if (h == null) return false;
    try {
      return await h.requestAuthorization(_types, permissions: _access);
    } catch (e) {
      debugPrint('health permission error: $e');
      return false;
    }
  }

  Future<bool> writeWorkout({
    required DateTime start,
    required DateTime end,
    required bool hasStrength,
    CardioType? cardio,
    double? distanceKm,
    int? kcal,
  }) async {
    final h = await _ready();
    if (h == null) return false;
    final type = cardio == null
        ? HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING
        : _activity(cardio);
    try {
      return await h.writeWorkoutData(
        activityType: type,
        start: start,
        end: end.isAfter(start) ? end : start.add(const Duration(minutes: 30)),
        totalDistance: distanceKm == null ? null : (distanceKm * 1000).round(),
        totalEnergyBurned: kcal,
        title: hasStrength ? 'Strength training' : cardio?.en,
        recordingMethod: RecordingMethod.manual,
      );
    } catch (e) {
      debugPrint('health workout error: $e');
      return false;
    }
  }

  Future<bool> writeBody({
    required DateTime at,
    required double weightKg,
    double? bodyFatPct,
  }) async {
    final h = await _ready();
    if (h == null) return false;
    try {
      var ok = await h.writeHealthData(
        value: weightKg,
        type: HealthDataType.WEIGHT,
        startTime: at,
        recordingMethod: RecordingMethod.manual,
      );
      if (bodyFatPct != null) {
        ok &= await h.writeHealthData(
          value: bodyFatPct,
          type: HealthDataType.BODY_FAT_PERCENTAGE,
          startTime: at,
          recordingMethod: RecordingMethod.manual,
        );
      }
      return ok;
    } catch (e) {
      debugPrint('health body error: $e');
      return false;
    }
  }

  Future<bool> writeMeal({
    required DateTime at,
    required MealSlot slot,
    required double kcal,
    required double protein,
    required double fat,
    required double carbs,
    String? name,
  }) async {
    final h = await _ready();
    if (h == null) return false;
    try {
      return await h.writeMeal(
        mealType: switch (slot) {
          MealSlot.breakfast => MealType.BREAKFAST,
          MealSlot.lunch => MealType.LUNCH,
          MealSlot.dinner => MealType.DINNER,
          MealSlot.snack => MealType.SNACK,
        },
        startTime: at,
        endTime: at.add(const Duration(minutes: 20)),
        caloriesConsumed: kcal,
        protein: protein,
        fatTotal: fat,
        carbohydrates: carbs,
        name: name,
        recordingMethod: RecordingMethod.manual,
      );
    } catch (e) {
      debugPrint('health meal error: $e');
      return false;
    }
  }

  Future<int?> todaySteps() async {
    final h = await _ready();
    if (h == null) return null;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    try {
      return await h.getTotalStepsInInterval(start, now);
    } catch (e) {
      debugPrint('health steps error: $e');
      return null;
    }
  }

  HealthWorkoutActivityType _activity(CardioType c) => switch (c) {
        CardioType.running => HealthWorkoutActivityType.RUNNING,
        CardioType.walking => HealthWorkoutActivityType.WALKING,
        CardioType.cycling => HealthWorkoutActivityType.BIKING,
        CardioType.elliptical => HealthWorkoutActivityType.ELLIPTICAL,
        CardioType.stairs => HealthWorkoutActivityType.STAIR_CLIMBING,
        CardioType.rowing => HealthWorkoutActivityType.ROWING,
        CardioType.swimming => HealthWorkoutActivityType.SWIMMING,
        CardioType.hiit => HealthWorkoutActivityType.HIGH_INTENSITY_INTERVAL_TRAINING,
        CardioType.yoga => HealthWorkoutActivityType.YOGA,
        CardioType.other => HealthWorkoutActivityType.OTHER,
      };
}
