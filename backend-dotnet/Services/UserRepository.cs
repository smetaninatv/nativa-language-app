using Dapper;
using Nativa.Api.Data;
using Nativa.Api.Models;

namespace Nativa.Api.Services;

public class UserRepository
{
    private readonly IDbConnectionFactory _db;

    public UserRepository(IDbConnectionFactory db) => _db = db;

    public async Task<User?> GetByEmailAsync(string email)
    {
        using var conn = await _db.CreateAsync();
        return await conn.QuerySingleOrDefaultAsync<User>(
            "SELECT * FROM users WHERE email = @Email", new { Email = email });
    }

    public async Task<User?> GetByIdAsync(int id)
    {
        using var conn = await _db.CreateAsync();
        return await conn.QuerySingleOrDefaultAsync<User>(
            "SELECT * FROM users WHERE id = @Id", new { Id = id });
    }

    public async Task<User> CreateAsync(string name, string email, string passwordHash)
    {
        using var conn = await _db.CreateAsync();
        return await conn.QuerySingleAsync<User>(
            @"INSERT INTO users (name, email, password_hash)
              VALUES (@Name, @Email, @PasswordHash)
              RETURNING *",
            new { Name = name, Email = email, PasswordHash = passwordHash });
    }
}
