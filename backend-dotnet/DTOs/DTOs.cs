namespace Nativa.Api.DTOs;

// ── Auth ──────────────────────────────────────────────────────────────────

public record RegisterRequest(string Name, string Email, string Password);
public record LoginRequest(string Email, string Password);
public record AuthResponse(string Token, UserDto User);

public record UserDto(int Id, string Name, string Email, DateTime CreatedAt);

// ── Learning Plan ─────────────────────────────────────────────────────────

public record CreatePlanRequest(
    string Language,
    string TargetLevel,
    int SessionsPerWeek
);

public record PlanResponse(
    int Id,
    string Language,
    string CurrentLevel,
    string TargetLevel,
    int SessionsPerWeek,
    ProgressDto Progress,
    string TodayTopic
);

public record ProgressDto(
    int TotalSessions,
    int TotalXp,
    int StreakDays,
    string? LastSessionDate,
    int XpToNextLevel,
    int XpCurrentLevel
);

// ── Session ───────────────────────────────────────────────────────────────

public record StartSessionRequest(int PlanId);

public record StartSessionResponse(
    int SessionId,
    string Topic,
    string Language,
    string Level,
    string OpeningMessage
);

public record SendMessageRequest(string Text);

public record SendMessageResponse(
    string Reply,
    CorrectionDto? Correction
);

public record CorrectionDto(
    string Original,
    string Corrected,
    string Explanation
);

public record EndSessionRequest(int DurationSeconds);

public record SessionSummaryResponse(
    int SessionId,
    string Topic,
    int DurationSeconds,
    int MessageCount,
    int XpEarned,
    List<CorrectionDto> Corrections
);

// ── Progress / Dashboard ─────────────────────────────────────────────────

public record DashboardResponse(
    UserDto User,
    List<PlanResponse> Plans,
    List<RecentSessionDto> RecentSessions
);

public record RecentSessionDto(
    int Id,
    string Topic,
    string Language,
    string Level,
    DateTime StartedAt,
    int DurationSeconds,
    int MessageCount
);
