using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Nativa.Api.DTOs;
using Nativa.Api.Services;

namespace Nativa.Api.Controllers;

[ApiController]
[Route("api/plans")]
[Authorize]
public class PlansController : ControllerBase
{
    private readonly PlanRepository _plans;
    private readonly UserRepository _users;
    private readonly SessionRepository _sessions;

    public PlansController(PlanRepository plans, UserRepository users, SessionRepository sessions)
    {
        _plans = plans;
        _users = users;
        _sessions = sessions;
    }

    private int UserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet("dashboard")]
    public async Task<IActionResult> Dashboard()
    {
        var user = await _users.GetByIdAsync(UserId);
        if (user == null) return Unauthorized();

        var plans = (await _plans.GetByUserAsync(UserId)).ToList();
        var planResponses = new List<PlanResponse>();

        foreach (var plan in plans)
        {
            var progress = await _plans.GetProgressAsync(UserId, plan.Id);
            var todayTopic = await _plans.GetTodayTopicAsync(UserId, plan.Id, plan.Language, plan.CurrentLevel);
            var (xpNeeded, xpPerLevel) = PlanRepository.GetLevelThresholds(plan.CurrentLevel);
            var xpInLevel = (progress?.TotalXp ?? 0) % xpPerLevel;

            planResponses.Add(new PlanResponse(
                plan.Id, plan.Language, plan.CurrentLevel, plan.TargetLevel, plan.SessionsPerWeek,
                new ProgressDto(
                    progress?.TotalSessions ?? 0,
                    progress?.TotalXp ?? 0,
                    progress?.StreakDays ?? 0,
                    progress?.LastSessionDate?.ToString("yyyy-MM-dd"),
                    xpNeeded,
                    xpInLevel
                ),
                todayTopic
            ));
        }

        var recent = (await _sessions.GetRecentByUserAsync(UserId, 5))
            .Select(s => new RecentSessionDto(
                s.Id, s.Topic, s.Language, s.Level,
                s.StartedAt, s.DurationSeconds ?? 0, s.MessageCount))
            .ToList();

        var userDto = new UserDto(user.Id, user.Name, user.Email, user.CreatedAt);
        return Ok(new DashboardResponse(userDto, planResponses, recent));
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreatePlanRequest req)
    {
        var validLevels = new[] { "A1","A2","B1","B2","C1","C2" };
        if (!validLevels.Contains(req.TargetLevel))
            return BadRequest(new { error = "Invalid target level." });
        if (req.SessionsPerWeek < 1 || req.SessionsPerWeek > 7)
            return BadRequest(new { error = "Sessions per week must be 1–7." });

        var plan = await _plans.CreateAsync(UserId, req.Language, req.TargetLevel, req.SessionsPerWeek);
        var todayTopic = await _plans.GetTodayTopicAsync(UserId, plan.Id, plan.Language, plan.CurrentLevel);

        return Ok(new PlanResponse(
            plan.Id, plan.Language, plan.CurrentLevel, plan.TargetLevel, plan.SessionsPerWeek,
            new ProgressDto(0, 0, 0, null, PlanRepository.GetLevelThresholds("A1").xpNeeded, 0),
            todayTopic
        ));
    }

    [HttpGet("{id}/topic")]
    public async Task<IActionResult> GetTodayTopic(int id)
    {
        var plan = await _plans.GetAsync(id);
        if (plan == null || plan.UserId != UserId) return NotFound();

        var topic = await _plans.GetTodayTopicAsync(UserId, id, plan.Language, plan.CurrentLevel);
        return Ok(new { topic });
    }
}
