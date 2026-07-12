String sanitizeString(String text) {
  final buffer = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    if (unit >= 0xD800 && unit <= 0xDBFF) {
      if (i + 1 < text.length) {
        final nextUnit = text.codeUnitAt(i + 1);
        if (nextUnit >= 0xDC00 && nextUnit <= 0xDFFF) {
          buffer.writeCharCode(unit);
          buffer.writeCharCode(nextUnit);
          i++;
          continue;
        }
      }
      buffer.write('?');
    } else if (unit >= 0xDC00 && unit <= 0xDFFF) {
      buffer.write('?');
    } else {
      buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}

class StudentRow {
  final String uid;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final DateTime? joinedAt;
  final int coursesCount;
  final int completedCourses;
  final double avgProgress;
  final int completedLessons;
  final int totalLessons;
  final int watchSeconds;
  final int quizCount;
  final int passedQuizzes;
  final int failedQuizzes;
  final double avgQuizScore;
  final DateTime? lastActivity;

  const StudentRow({
    required this.uid,
    required this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    this.joinedAt,
    required this.coursesCount,
    required this.completedCourses,
    required this.avgProgress,
    required this.completedLessons,
    required this.totalLessons,
    required this.watchSeconds,
    required this.quizCount,
    required this.passedQuizzes,
    required this.failedQuizzes,
    required this.avgQuizScore,
    this.lastActivity,
  });
}

class StudentRowBuilder {
  final String uid;
  final Map<String, dynamic> profile;

  int coursesCount = 0;
  int completedCourses = 0;
  double totalProgress = 0;
  int completedLessons = 0;
  int totalLessons = 0;
  DateTime? lastActivity;

  StudentRowBuilder(this.uid, this.profile);

  void addEnrollment(Map<String, dynamic> e, Map<String, dynamic> course) {
    coursesCount++;
    final prog = (e['progress_percentage'] as num?)?.toDouble() ?? 0;
    totalProgress += prog;
    if (prog >= 100 || e['completed_at'] != null) completedCourses++;

    final tl = course['total_lessons'] as int? ?? 0;
    totalLessons += tl;
    completedLessons += (tl * prog / 100).round();

    final lastAccess = e['last_accessed_at'] != null
        ? DateTime.tryParse(e['last_accessed_at'] as String)
        : null;
    if (lastAccess != null) {
      if (lastActivity == null || lastAccess.isAfter(lastActivity!)) {
        lastActivity = lastAccess;
      }
    }
  }

  StudentRow build(List<Map<String, dynamic>> quizzes) {
    final avgProgress = coursesCount > 0 ? totalProgress / coursesCount : 0.0;
    final passed = quizzes.where((q) => q['passed'] == true).length;
    final failed = quizzes.length - passed;
    final avgScore = quizzes.isEmpty
        ? 0.0
        : quizzes
                .map((q) => (q['score'] as num?)?.toDouble() ?? 0)
                .reduce((a, b) => a + b) /
            quizzes.length;

    final rawName = profile['name'] as String? ?? 'Unknown';
    final rawEmail = profile['email'] as String?;
    final rawPhone = profile['phone'] as String?;

    return StudentRow(
      uid: uid,
      name: sanitizeString(rawName),
      email: rawEmail != null ? sanitizeString(rawEmail) : null,
      phone: rawPhone != null ? sanitizeString(rawPhone) : null,
      avatarUrl: profile['avatar_url'] as String?,
      joinedAt: profile['created_at'] != null
          ? DateTime.tryParse(profile['created_at'] as String)
          : null,
      coursesCount: coursesCount,
      completedCourses: completedCourses,
      avgProgress: avgProgress,
      completedLessons: completedLessons,
      totalLessons: totalLessons,
      watchSeconds: profile['total_watch_time'] as int? ?? 0,
      quizCount: quizzes.length,
      passedQuizzes: passed,
      failedQuizzes: failed,
      avgQuizScore: avgScore,
      lastActivity: lastActivity,
    );
  }
}
