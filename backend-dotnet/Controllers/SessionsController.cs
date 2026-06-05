using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Nativa.Api.DTOs;
using Nativa.Api.Services;

namespace Nativa.Api.Controllers;

[ApiController]
[Route("api/sessions")]
[Authorize]
public class SessionsController : ControllerBase
{
    private readonly SessionRepository _sessions;
    private readonly PlanRepository _plans;
    private readonly ClaudeService _claude;

    public SessionsController(SessionRepository sessions, PlanRepository plans, ClaudeService claude)
    {
        _sessions = sessions;
        _plans = plans;
        _claude = claude;
    }

    private int UserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    // POST /api/sessions/start
    [HttpPost("start")]
    public async Task<IActionResult> Start([FromBody] StartSessionRequest req)
    {
        var plan = await _plans.GetAsync(req.PlanId);
        if (plan == null || plan.UserId != UserId)
            return NotFound(new { error = "Plan not found." });

        var topic = await _plans.GetTodayTopicAsync(UserId, plan.Id, plan.Language, plan.CurrentLevel);
        var session = await _sessions.CreateAsync(UserId, plan.Id, topic, plan.Language, plan.CurrentLevel);

        var opening = $"Hi! I'm Aria, your {plan.Language} tutor. Today we're talking about: {topic}. Let's go — what do you think about it?";
        await _sessions.AddMessageAsync(session.Id, "assistant", opening);

        return Ok(new StartSessionResponse(session.Id, topic, plan.Language, plan.CurrentLevel, opening));
    }

    // POST /api/sessions/{id}/message
    [HttpPost("{id}/message")]
    public async Task<IActionResult> SendMessage(int id, [FromBody] SendMessageRequest req)
    {
        var session = await _sessions.GetAsync(id);
        if (session == null || session.UserId != UserId)
            return NotFound(new { error = "Session not found." });
        if (session.EndedAt.HasValue)
            return BadRequest(new { error = "Session already ended." });
        if (string.IsNullOrWhiteSpace(req.Text))
            return BadRequest(new { error = "Message cannot be empty." });

        // Load history for context
        var msgs = (await _sessions.GetMessagesAsync(id))
            .Select(m => (m.Role, m.Content))
            .ToList();

        // Save user message
        await _sessions.AddMessageAsync(id, "user", req.Text);

        // Call Claude
        var result = await _claude.ChatAsync(
            session.Language, session.Level, session.Topic, msgs, req.Text);

        // Save assistant reply
        await _sessions.AddMessageAsync(id, "assistant", result.Reply);

        // Save correction if any
        if (result.Correction != null)
        {
            await _sessions.AddCorrectionAsync(
                id, UserId,
                result.Correction.Original,
                result.Correction.Corrected,
                result.Correction.Explanation);
        }

        return Ok(result);
    }

    // POST /api/sessions/{id}/end
    [HttpPost("{id}/end")]
    public async Task<IActionResult> End(int id, [FromBody] EndSessionRequest req)
    {
        var session = await _sessions.GetAsync(id);
        if (session == null || session.UserId != UserId)
            return NotFound(new { error = "Session not found." });

        var messages = (await _sessions.GetMessagesAsync(id)).ToList();
        var userMessages = messages.Count(m => m.Role == "user");

        await _sessions.EndAsync(id, req.DurationSeconds, messages.Count);

        // Award XP: base 50 + 5 per message + bonus for length
        var xp = 50 + (userMessages * 5) + (req.DurationSeconds > 300 ? 25 : 0);
        await _plans.AddXpAsync(UserId, session.PlanId, xp);

        // Check for level up
        var progress = await _plans.GetProgressAsync(UserId, session.PlanId);
        var plan = await _plans.GetAsync(session.PlanId);
        if (plan != null && progress != null)
        {
            var (xpNeeded, _) = PlanRepository.GetLevelThresholds(plan.CurrentLevel);
            var xpInLevel = progress.TotalXp % xpNeeded;
            var nextLevel = PlanRepository.NextLevel(plan.CurrentLevel);
            if (xpInLevel < xp && nextLevel != null && plan.CurrentLevel != plan.TargetLevel)
            {
                await _plans.UpdateLevelAsync(plan.Id, nextLevel);
            }
        }

        var corrections = (await _sessions.GetCorrectionsAsync(id))
            .Select(c => new CorrectionDto(c.OriginalText, c.CorrectedText, c.Explanation))
            .ToList();

        return Ok(new SessionSummaryResponse(id, session.Topic, req.DurationSeconds, messages.Count, xp, corrections));
    }
}
