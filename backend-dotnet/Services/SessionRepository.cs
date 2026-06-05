using Dapper;
using Nativa.Api.Data;
using Nativa.Api.Models;

namespace Nativa.Api.Services;

public class SessionRepository
{
    private readonly IDbConnectionFactory _db;

    public SessionRepository(IDbConnectionFactory db) => _db = db;

    public async Task<Session> CreateAsync(int userId, int planId, string topic, string language, string level)
    {
        using var conn = await _db.CreateAsync();
        return await conn.QuerySingleAsync<Session>(
            @"INSERT INTO sessions (user_id, plan_id, topic, language, level)
              VALUES (@UserId, @PlanId, @Topic, @Language, @Level)
              RETURNING *",
            new { UserId = userId, PlanId = planId, Topic = topic, Language = language, Level = level });
    }

    public async Task<Session?> GetAsync(int sessionId)
    {
        using var conn = await _db.CreateAsync();
        return await conn.QuerySingleOrDefaultAsync<Session>(
            "SELECT * FROM sessions WHERE id = @Id", new { Id = sessionId });
    }

    public async Task EndAsync(int sessionId, int durationSeconds, int messageCount)
    {
        using var conn = await _db.CreateAsync();
        await conn.ExecuteAsync(
            @"UPDATE sessions
              SET ended_at = NOW(), duration_seconds = @Duration, message_count = @MsgCount
              WHERE id = @Id",
            new { Duration = durationSeconds, MsgCount = messageCount, Id = sessionId });
    }

    public async Task<IEnumerable<Session>> GetRecentByUserAsync(int userId, int limit = 10)
    {
        using var conn = await _db.CreateAsync();
        return await conn.QueryAsync<Session>(
            @"SELECT * FROM sessions WHERE user_id = @UserId
              ORDER BY started_at DESC LIMIT @Limit",
            new { UserId = userId, Limit = limit });
    }

    // ── Messages ──────────────────────────────────────────────────────────

    public async Task AddMessageAsync(int sessionId, string role, string content)
    {
        using var conn = await _db.CreateAsync();
        await conn.ExecuteAsync(
            "INSERT INTO messages (session_id, role, content) VALUES (@SessionId, @Role, @Content)",
            new { SessionId = sessionId, Role = role, Content = content });
    }

    public async Task<IEnumerable<Message>> GetMessagesAsync(int sessionId)
    {
        using var conn = await _db.CreateAsync();
        return await conn.QueryAsync<Message>(
            "SELECT * FROM messages WHERE session_id = @SessionId ORDER BY created_at",
            new { SessionId = sessionId });
    }

    // ── Corrections ───────────────────────────────────────────────────────

    public async Task AddCorrectionAsync(int sessionId, int userId, string original, string corrected, string explanation)
    {
        using var conn = await _db.CreateAsync();
        await conn.ExecuteAsync(
            @"INSERT INTO corrections (session_id, user_id, original_text, corrected_text, explanation)
              VALUES (@SessionId, @UserId, @Original, @Corrected, @Explanation)",
            new { SessionId = sessionId, UserId = userId, Original = original, Corrected = corrected, Explanation = explanation });
    }

    public async Task<IEnumerable<Correction>> GetCorrectionsAsync(int sessionId)
    {
        using var conn = await _db.CreateAsync();
        return await conn.QueryAsync<Correction>(
            "SELECT * FROM corrections WHERE session_id = @SessionId ORDER BY created_at",
            new { SessionId = sessionId });
    }
}
