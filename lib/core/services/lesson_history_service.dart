import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// Model for storing lesson history
class LessonHistoryItem {
  final String lessonId;
  final String lessonTitle;
  final String courseId;
  final String courseTitle;
  final String enrollmentId;
  final DateTime lastWatched;
  final int? lastPosition;
  final String? thumbnailUrl;
  final String? instructorId;
  final String? instructorName;
  final String? instructorAvatar;

  LessonHistoryItem({
    required this.lessonId,
    required this.lessonTitle,
    required this.courseId,
    required this.courseTitle,
    required this.enrollmentId,
    required this.lastWatched,
    this.lastPosition,
    this.thumbnailUrl,
    this.instructorId,
    this.instructorName,
    this.instructorAvatar,
  });

  Map<String, dynamic> toJson() => {
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
        'courseId': courseId,
        'courseTitle': courseTitle,
        'enrollmentId': enrollmentId,
        'lastWatched': lastWatched.toIso8601String(),
        'lastPosition': lastPosition,
        'thumbnailUrl': thumbnailUrl,
        'instructorId': instructorId,
        'instructorName': instructorName,
        'instructorAvatar': instructorAvatar,
      };

  factory LessonHistoryItem.fromJson(Map<String, dynamic> json) =>
      LessonHistoryItem(
        lessonId: json['lessonId'] as String,
        lessonTitle: json['lessonTitle'] as String,
        courseId: json['courseId'] as String,
        courseTitle: json['courseTitle'] as String,
        enrollmentId: json['enrollmentId'] as String,
        lastWatched: DateTime.parse(json['lastWatched'] as String),
        lastPosition: json['lastPosition'] as int?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        instructorId: json['instructorId'] as String?,
        instructorName: json['instructorName'] as String?,
        instructorAvatar: json['instructorAvatar'] as String?,
      );
}

/// Service for managing lesson watch history
class LessonHistoryService {
  final SharedPreferences _prefs;
  static const String _historyKey = 'lesson_history';
  static const int _maxHistoryItems =
      5; // Keep only last 5 lessons like browser history

  LessonHistoryService(this._prefs);

  /// Add or update a lesson in history
  Future<void> addToHistory(LessonHistoryItem item) async {
    try {
      debugPrint('📚 [History Service] Adding to history: ${item.lessonTitle}');
      final history = await getHistory();
      debugPrint(
          '📚 [History Service] Current history count: ${history.length}');

      // Remove existing entry for this lesson if it exists
      history.removeWhere((h) => h.lessonId == item.lessonId);

      // Add new entry at the beginning
      history.insert(0, item);

      // Keep only the most recent items
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      // Save to SharedPreferences
      final jsonList = history.map((h) => h.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      debugPrint(
          '📚 [History Service] Saving ${history.length} items to SharedPreferences');
      debugPrint('📚 [History Service] JSON: $jsonString');

      final success = await _prefs.setString(_historyKey, jsonString);
      debugPrint('📚 [History Service] Save result: $success');

      // Verify it was saved
      final saved = _prefs.getString(_historyKey);
      debugPrint(
          '📚 [History Service] Verification - Saved data exists: ${saved != null}');
    } catch (e, stackTrace) {
      debugPrint('❌ [History Service] Error adding to history: $e');
      debugPrint('❌ [History Service] Stack trace: $stackTrace');
    }
  }

  /// Get all history items sorted by most recent
  Future<List<LessonHistoryItem>> getHistory() async {
    try {
      final jsonString = _prefs.getString(_historyKey);
      debugPrint(
          '📚 [History Service] Getting history - Data exists: ${jsonString != null}');

      if (jsonString == null) {
        debugPrint(
            '📚 [History Service] No history found in SharedPreferences');
        return [];
      }

      debugPrint('📚 [History Service] Raw JSON: $jsonString');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final items = jsonList
          .map((json) =>
              LessonHistoryItem.fromJson(json as Map<String, dynamic>))
          .toList();
      debugPrint('📚 [History Service] Parsed ${items.length} history items');
      return items;
    } catch (e, stackTrace) {
      debugPrint('❌ [History Service] Error getting history: $e');
      debugPrint('❌ [History Service] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get the most recent lesson
  Future<LessonHistoryItem?> getLastWatchedLesson() async {
    final history = await getHistory();
    return history.isEmpty ? null : history.first;
  }

  /// Remove a specific lesson from history
  Future<void> removeFromHistory(String lessonId) async {
    try {
      final history = await getHistory();
      history.removeWhere((h) => h.lessonId == lessonId);

      final jsonList = history.map((h) => h.toJson()).toList();
      await _prefs.setString(_historyKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error removing from history: $e');
    }
  }

  /// Clear all history
  Future<void> clearHistory() async {
    try {
      await _prefs.remove(_historyKey);
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  /// Get history for a specific course
  Future<List<LessonHistoryItem>> getHistoryForCourse(String courseId) async {
    final history = await getHistory();
    return history.where((h) => h.courseId == courseId).toList();
  }
}
