/*
ARCHIVAL SNAPSHOT (moved from lib/app_state_working_backup.dart)

- Date archived: 2025-09-21
- Purpose: Preserve a historical working backup of AppState logic used during
  the lunch→dinner transition development. This file is NOT part of the
  production package build and may contain experimental code, print-based
  debugging, and incomplete migrations.
- Notes: Kept under tool/archive so it will not be compiled into the app.
  If you need to reference code, copy snippets manually into lib/ and adapt.
*/

// The original contents follow below, unchanged to preserve history.

/// Register a Pizookie run: counts as a run, +2 points, +1 pizookieRuns
library;

import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'models.dart';
import 'storage.dart';
import 'gamification.dart';

String _randId() {
  final r = Random();
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(16, (_) => chars[r.nextInt(chars.length)]).join();
}

class ServerProfile {
  double get avgSecondsBetweenRuns => tapIntervalsCount == 0
      ? 0
      : tapIntervalsMsSum / tapIntervalsCount / 1000.0;
  int get level => levelForPoints(points);
  int get nextLevelAt => nextLevelTarget(points);
  int allTimeRuns;
  int pizookieRuns;
  int bestShiftRuns;
  int streakBest;
  int shiftsAsMvp;
  List<String> achievements;
  List<String> repeatEarnedDates;
  int points;
  int tapIntervalsMsSum;
  int tapIntervalsCount;
  String? lastTapIso;
  String? avatarPath;
  String? bannerPath;
  List<Map<String, dynamic>> avatarHistory;
  String hireDate;
  String birthday;
  bool isArchived;
  String archiveNotes;

  ServerProfile({
    this.allTimeRuns = 0,
    this.pizookieRuns = 0,
    this.bestShiftRuns = 0,
    this.streakBest = 0,
    this.shiftsAsMvp = 0,
    List<String>? achievements,
    List<String>? repeatEarnedDates,
    this.points = 0,
    this.tapIntervalsMsSum = 0,
    this.tapIntervalsCount = 0,
    this.lastTapIso,
    this.avatarPath,
    this.bannerPath,
    this.avatarHistory = const [],
    this.hireDate = '',
    this.birthday = '',
    this.isArchived = false,
    this.archiveNotes = '',
  })  : achievements = achievements ?? [],
        repeatEarnedDates = repeatEarnedDates ?? [];

  ServerProfile copyWith({
    int? allTimeRuns,
    int? pizookieRuns,
    int? bestShiftRuns,
    int? streakBest,
    int? shiftsAsMvp,
    List<String>? achievements,
    List<String>? repeatEarnedDates,
    int? points,
    int? tapIntervalsMsSum,
    int? tapIntervalsCount,
    String? lastTapIso,
    String? avatarPath,
    String? bannerPath,
    List<Map<String, dynamic>>? avatarHistory,
    String? hireDate,
    String? birthday,
    bool? isArchived,
    String? archiveNotes,
  }) {
    return ServerProfile(
      allTimeRuns: allTimeRuns ?? this.allTimeRuns,
      pizookieRuns: pizookieRuns ?? this.pizookieRuns,
      bestShiftRuns: bestShiftRuns ?? this.bestShiftRuns,
      streakBest: streakBest ?? this.streakBest,
      shiftsAsMvp: shiftsAsMvp ?? this.shiftsAsMvp,
      achievements: achievements ?? this.achievements,
      repeatEarnedDates: repeatEarnedDates ?? this.repeatEarnedDates,
      points: points ?? this.points,
      tapIntervalsMsSum: tapIntervalsMsSum ?? this.tapIntervalsMsSum,
      tapIntervalsCount: tapIntervalsCount ?? this.tapIntervalsCount,
      lastTapIso: lastTapIso ?? this.lastTapIso,
      avatarPath: avatarPath ?? this.avatarPath,
      bannerPath: bannerPath ?? this.bannerPath,
      avatarHistory: avatarHistory ?? this.avatarHistory,
      hireDate: hireDate ?? this.hireDate,
      birthday: birthday ?? this.birthday,
      isArchived: isArchived ?? this.isArchived,
      archiveNotes: archiveNotes ?? this.archiveNotes,
    );
  }

  static ServerProfile fromMap(Map m) => ServerProfile(
        allTimeRuns: (m['allTimeRuns'] ?? 0) as int,
        pizookieRuns: (m['pizookieRuns'] ?? 0) as int,
        bestShiftRuns: (m['bestShiftRuns'] ?? 0) as int,
        streakBest: (m['streakBest'] ?? 0) as int,
        shiftsAsMvp: (m['shiftsAsMvp'] ?? 0) as int,
        achievements:
            (m['achievements'] as List?)?.cast<String>() ?? <String>[],
        repeatEarnedDates:
            (m['repeatEarnedDates'] as List?)?.cast<String>() ?? <String>[],
        points: (m['points'] ?? 0) as int,
        tapIntervalsMsSum: (m['tapIntervalsMsSum'] ?? 0) as int,
        tapIntervalsCount: (m['tapIntervalsMsCount'] ?? 0) as int,
        lastTapIso: m['lastTapIso'] as String?,
        avatarPath: m['avatarPath'] as String?,
        bannerPath: m['bannerPath'] as String?,
        avatarHistory: (m['avatarHistory'] as List?)?.map((e) {
              if (e is String) {
                return {'path': e, 'timestamp': null};
              } else if (e is Map) {
                return Map<String, dynamic>.from(
                    e.map((key, value) => MapEntry(key.toString(), value)));
              } else {
                return <String, dynamic>{};
              }
            }).toList() ??
            <Map<String, dynamic>>[],
        hireDate: (m['hireDate'] ?? '') as String,
        birthday: (m['birthday'] ?? '') as String,
        isArchived: (m['isArchived'] ?? false) as bool,
        archiveNotes: (m['archiveNotes'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {
        'allTimeRuns': allTimeRuns,
        'pizookieRuns': pizookieRuns,
        'bestShiftRuns': bestShiftRuns,
        'streakBest': streakBest,
        'shiftsAsMvp': shiftsAsMvp,
        'achievements': achievements,
        'repeatEarnedDates': repeatEarnedDates,
        'points': points,
        'tapIntervalsMsSum': tapIntervalsMsSum,
        'tapIntervalsCount': tapIntervalsCount,
        'lastTapIso': lastTapIso,
        'avatarPath': avatarPath,
        'bannerPath': bannerPath,
        'avatarHistory': avatarHistory,
        'hireDate': hireDate,
        'birthday': birthday,
        'isArchived': isArchived,
        'archiveNotes': archiveNotes,
      };
}

// ... The rest of the original file continues unchanged ...
