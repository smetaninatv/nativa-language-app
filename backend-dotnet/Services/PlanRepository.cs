using Dapper;
using Nativa.Api.Data;
using Nativa.Api.Models;

namespace Nativa.Api.Services;

public class PlanRepository
{
    private readonly IDbConnectionFactory _db;

    public PlanRepository(IDbConnectionFactory db) => _db = db;

    public async Task<LearningPlan?> GetAsync(int id)
    {
        using var conn = await _db.CreateAsync();
        return await conn.QuerySingleOrDefaultAsync<LearningPlan>(
            "SELECT * FROM learning_plans WHERE id = @Id", new { Id = id });
    }

    public async Task<IEnumerable<LearningPlan>> GetByUserAsync(int userId)
    {
        using var conn = await _db.CreateAsync();
        return await conn.QueryAsync<LearningPlan>(
            "SELECT * FROM learning_plans WHERE user_id = @UserId ORDER BY created_at",
            new { UserId = userId });
    }

    public async Task<LearningPlan> CreateAsync(int userId, string language, string targetLevel, int sessionsPerWeek)
    {
        using var conn = await _db.CreateAsync();

        var plan = await conn.QuerySingleAsync<LearningPlan>(
            @"INSERT INTO learning_plans (user_id, language, current_level, target_level, sessions_per_week)
              VALUES (@UserId, @Language, 'A1', @TargetLevel, @SessionsPerWeek)
              RETURNING *",
            new { UserId = userId, Language = language, TargetLevel = targetLevel, SessionsPerWeek = sessionsPerWeek });

        // Create matching progress row
        await conn.ExecuteAsync(
            @"INSERT INTO progress (user_id, plan_id) VALUES (@UserId, @PlanId)
              ON CONFLICT DO NOTHING",
            new { UserId = userId, PlanId = plan.Id });

        return plan;
    }

    public async Task UpdateLevelAsync(int planId, string newLevel)
    {
        using var conn = await _db.CreateAsync();
        await conn.ExecuteAsync(
            "UPDATE learning_plans SET current_level = @Level, updated_at = NOW() WHERE id = @Id",
            new { Level = newLevel, Id = planId });
    }

    // ── Progress ─────────────────────────────────────────────────────────

    public async Task<Progress?> GetProgressAsync(int userId, int planId)
    {
        using var conn = await _db.CreateAsync();
        return await conn.QuerySingleOrDefaultAsync<Progress>(
            "SELECT * FROM progress WHERE user_id = @UserId AND plan_id = @PlanId",
            new { UserId = userId, PlanId = planId });
    }

    public async Task AddXpAsync(int userId, int planId, int xp)
    {
        using var conn = await _db.CreateAsync();
        var today = DateOnly.FromDateTime(DateTime.UtcNow);

        await conn.ExecuteAsync(
            @"UPDATE progress
              SET total_sessions  = total_sessions + 1,
                  total_xp        = total_xp + @Xp,
                  streak_days     = CASE
                      WHEN last_session_date = @Yesterday THEN streak_days + 1
                      WHEN last_session_date = @Today     THEN streak_days
                      ELSE 1
                  END,
                  last_session_date = @Today,
                  updated_at = NOW()
              WHERE user_id = @UserId AND plan_id = @PlanId",
            new {
                Xp = xp,
                Today = today,
                Yesterday = today.AddDays(-1),
                UserId = userId,
                PlanId = planId
            });
    }

    // ── Topics ────────────────────────────────────────────────────────────

    public async Task<string> GetTodayTopicAsync(int userId, int planId, string language, string level)
    {
        using var conn = await _db.CreateAsync();

        // Pick a topic not used in the last 10 sessions for this plan
        var topic = await conn.QueryFirstOrDefaultAsync<string>(
            @"SELECT t.title FROM topics t
              WHERE t.language = @Language AND t.level = @Level
              AND t.title NOT IN (
                  SELECT s.topic FROM sessions s
                  WHERE s.plan_id = @PlanId
                  ORDER BY s.started_at DESC LIMIT 10
              )
              ORDER BY RANDOM() LIMIT 1",
            new { Language = language, Level = level, PlanId = planId });

        // Fallback: any topic at this level
        if (topic == null)
        {
            topic = await conn.QueryFirstOrDefaultAsync<string>(
                @"SELECT title FROM topics WHERE language = @Language AND level = @Level
                  ORDER BY RANDOM() LIMIT 1",
                new { Language = language, Level = level });
        }

        return topic ?? "Your favourite hobby";
    }

    // XP thresholds per level (sessions needed to advance)
    public static (int xpNeeded, int xpPerLevel) GetLevelThresholds(string level) => level switch
    {
        "A1" => (300, 300),
        "A2" => (400, 400),
        "B1" => (500, 500),
        "B2" => (600, 600),
        "C1" => (700, 700),
        _    => (999, 999),
    };

    public static string? NextLevel(string current) => current switch
    {
        "A1" => "A2",
        "A2" => "B1",
        "B1" => "B2",
        "B2" => "C1",
        "C1" => "C2",
        _    => null,
    };
}
