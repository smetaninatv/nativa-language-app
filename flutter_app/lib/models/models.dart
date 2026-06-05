class UserModel {
  final int id;
  final String name;
  final String email;

  UserModel({required this.id, required this.name, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> j) =>
      UserModel(id: j['id'], name: j['name'], email: j['email']);
}

class ProgressModel {
  final int totalSessions;
  final int totalXp;
  final int streakDays;
  final String? lastSessionDate;
  final int xpToNextLevel;
  final int xpCurrentLevel;

  ProgressModel({
    required this.totalSessions,
    required this.totalXp,
    required this.streakDays,
    required this.lastSessionDate,
    required this.xpToNextLevel,
    required this.xpCurrentLevel,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> j) => ProgressModel(
        totalSessions: j['totalSessions'],
        totalXp: j['totalXp'],
        streakDays: j['streakDays'],
        lastSessionDate: j['lastSessionDate'],
        xpToNextLevel: j['xpToNextLevel'],
        xpCurrentLevel: j['xpCurrentLevel'],
      );

  double get xpPercent =>
      xpToNextLevel == 0 ? 0 : (xpCurrentLevel / xpToNextLevel).clamp(0.0, 1.0);
}

class PlanModel {
  final int id;
  final String language;
  final String currentLevel;
  final String targetLevel;
  final int sessionsPerWeek;
  final ProgressModel progress;
  final String todayTopic;

  PlanModel({
    required this.id,
    required this.language,
    required this.currentLevel,
    required this.targetLevel,
    required this.sessionsPerWeek,
    required this.progress,
    required this.todayTopic,
  });

  factory PlanModel.fromJson(Map<String, dynamic> j) => PlanModel(
        id: j['id'],
        language: j['language'],
        currentLevel: j['currentLevel'],
        targetLevel: j['targetLevel'],
        sessionsPerWeek: j['sessionsPerWeek'],
        progress: ProgressModel.fromJson(j['progress']),
        todayTopic: j['todayTopic'],
      );
}

class ChatMessage {
  final String text;
  final bool isUser;
  final CorrectionModel? correction;

  ChatMessage({required this.text, required this.isUser, this.correction});
}

class CorrectionModel {
  final String original;
  final String corrected;
  final String explanation;

  CorrectionModel({required this.original, required this.corrected, required this.explanation});

  factory CorrectionModel.fromJson(Map<String, dynamic> j) => CorrectionModel(
        original: j['original'],
        corrected: j['corrected'],
        explanation: j['explanation'],
      );
}

class RecentSession {
  final int id;
  final String topic;
  final String language;
  final String level;
  final int durationSeconds;
  final int messageCount;

  RecentSession({
    required this.id,
    required this.topic,
    required this.language,
    required this.level,
    required this.durationSeconds,
    required this.messageCount,
  });

  factory RecentSession.fromJson(Map<String, dynamic> j) => RecentSession(
        id: j['id'],
        topic: j['topic'],
        language: j['language'],
        level: j['level'],
        durationSeconds: j['durationSeconds'],
        messageCount: j['messageCount'],
      );
}
