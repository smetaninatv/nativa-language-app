using Dapper;
using Npgsql;

namespace Nativa.Api.Data;

public class DatabaseMigrator
{
    private readonly string _connectionString;
    private readonly ILogger<DatabaseMigrator> _logger;

    public DatabaseMigrator(string connectionString, ILogger<DatabaseMigrator> logger)
    {
        _connectionString = connectionString;
        _logger = logger;
    }

    public async Task MigrateAsync()
    {
        var schemaPath = Path.Combine(AppContext.BaseDirectory, "Migrations", "schema.sql");
        if (!File.Exists(schemaPath))
        {
            _logger.LogWarning("schema.sql not found at {Path}", schemaPath);
            return;
        }

        var sql = await File.ReadAllTextAsync(schemaPath);

        await using var conn = new NpgsqlConnection(_connectionString);
        await conn.OpenAsync();
        await conn.ExecuteAsync(sql);
        _logger.LogInformation("Database schema applied successfully.");
    }
}
