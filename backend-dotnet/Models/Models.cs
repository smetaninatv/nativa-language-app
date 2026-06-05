namespace Nativa.Api.Models;

public class User
{
    public int Id { get; set; }
    public string Email { get; set; } = "";
    public string Name { get; set; } = "";
    public string PasswordHash { get; set; } = "";
    public DateTime CreatedAt { get; set; }
}

public class LearningPlan
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string Language { get; set; } = "";
    public string CurrentLevel { get; set; } = "A1";
    public string TargetLevel { get; set; } = "C2";
    public int SessionsPerWeek { get; set; } = 3;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class Session
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int PlanId { get; set; }
    public string Topic { get; set; } = "";
    public string Language { get; set; } = "";
    public string Level { get; set; } = "";
    public DateTime StartedAt { get; set; }
    public DateTime? EndedAt { get; set; }
    public int? DurationSeconds { get; set; }
    public int MessageCount { get; set; }
}

public class Message
{
    public int Id { get; set; }
    public int SessionId { get; set; }
    public string Role { get; set; } = "";
    public string Content { get; set; } = "";
    public DateTime CreatedAt { get; set; }
}

public class Correction
{
    public int Id { get; set; }
    public int SessionId { get; set; }
    public int UserId { get; set; }
    public string OriginalText { get; set; } = "";
    public string CorrectedText { get; set; } = "";
    public string Explanation { get; set; } = "";
    public DateTime CreatedAt { get; set; }
}

public class Progress
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int PlanId { get; set; }
    public int TotalSessions { get; set; }
    public int TotalXp { get; set; }
    public int StreakDays { get; set; }
    public DateOnly? LastSessionDate { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class Topic
{
    public int Id { get; set; }
    public string Language { get; set; } = "";
    public string Level { get; set; } = "";
    public string Title { get; set; } = "";
}
