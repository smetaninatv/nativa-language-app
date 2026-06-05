using Microsoft.AspNetCore.Mvc;
using Nativa.Api.DTOs;
using Nativa.Api.Services;

namespace Nativa.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly UserRepository _users;
    private readonly JwtService _jwt;

    public AuthController(UserRepository users, JwtService jwt)
    {
        _users = users;
        _jwt = jwt;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.Email) || string.IsNullOrWhiteSpace(req.Password))
            return BadRequest(new { error = "Email and password are required." });

        var existing = await _users.GetByEmailAsync(req.Email.ToLower());
        if (existing != null)
            return Conflict(new { error = "Email already registered." });

        var hash = BCrypt.Net.BCrypt.HashPassword(req.Password);
        var user = await _users.CreateAsync(req.Name.Trim(), req.Email.ToLower().Trim(), hash);
        var token = _jwt.GenerateToken(user);

        return Ok(new AuthResponse(token, new UserDto(user.Id, user.Name, user.Email, user.CreatedAt)));
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest req)
    {
        var user = await _users.GetByEmailAsync(req.Email.ToLower());
        if (user == null || !BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
            return Unauthorized(new { error = "Invalid email or password." });

        var token = _jwt.GenerateToken(user);
        return Ok(new AuthResponse(token, new UserDto(user.Id, user.Name, user.Email, user.CreatedAt)));
    }
}
