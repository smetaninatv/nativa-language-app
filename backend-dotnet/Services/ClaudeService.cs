using System.Text.Json;
using Anthropic.SDK;
using Anthropic.SDK.Messaging;
using Nativa.Api.DTOs;

namespace Nativa.Api.Services;

public class ClaudeService
{
    private readonly AnthropicClient _client;
    private readonly ILogger<ClaudeService> _logger;

    public ClaudeService(IConfiguration config, ILogger<ClaudeService> logger)
    {
        _client = new AnthropicClient(config["Anthropic:ApiKey"]!);
        _logger = logger;
    }

    public async Task<SendMessageResponse> ChatAsync(
        string language,
        string level,
        string topic,
        List<(string role, string content)> history,
        string userMessage)
    {
        var systemPrompt = BuildSystemPrompt(language, level, topic);

        var messages = history
            .Select(m => new Message
            {
                Role = m.role == "user" ? RoleType.User : RoleType.Assistant,
                Content = new List<ContentBase> { new TextContent { Text = m.content } }
            })
            .ToList();

        messages.Add(new Message
        {
            Role = RoleType.User,
            Content = new List<ContentBase> { new TextContent { Text = userMessage } }
        });

        var request = new MessageParameters
        {
            Model = AnthropicModels.Claude35Sonnet,
            MaxTokens = 512,
            System = new List<SystemMessage> { new SystemMessage(systemPrompt) },
            Messages = messages
        };

        var response = await _client.Messages.GetClaudeMessageAsync(request);
        var raw = response.Content.OfType<TextBlock>().FirstOrDefault()?.Text ?? "";

        return ParseResponse(raw);
    }

    private static SendMessageResponse ParseResponse(string raw)
    {
        try
        {
            // Strip markdown code fences if present
            var json = raw.Trim();
            if (json.StartsWith("```")) json = string.Join('\n', json.Split('\n').Skip(1).SkipLast(1));

            using var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            var reply = root.GetProperty("reply").GetString() ?? raw;
            CorrectionDto? correction = null;

            if (root.TryGetProperty("correction", out var c) &&
                c.TryGetProperty("hasError", out var hasError) &&
                hasError.GetBoolean())
            {
                correction = new CorrectionDto(
                    c.GetProperty("original").GetString() ?? "",
                    c.GetProperty("corrected").GetString() ?? "",
                    c.GetProperty("explanation").GetString() ?? ""
                );
            }

            return new SendMessageResponse(reply, correction);
        }
        catch
        {
            return new SendMessageResponse(raw, null);
        }
    }

    private static string BuildSystemPrompt(string language, string level, string topic) => $"""
        You are Aria, a warm and encouraging AI language tutor helping someone learn {language}.
        The learner's current level is {level} (CEFR scale A1-C2).
        Today's conversation topic is: "{topic}".

        Your job:
        1. Have a natural, friendly conversation on the topic. Keep replies to 1-2 sentences.
        2. After EVERY learner message, check for grammar, vocabulary, or phrasing mistakes.
        3. Always reply in this EXACT JSON format with no text outside it:

        {{
          "reply": "Your conversational response here.",
          "correction": {{
            "hasError": true or false,
            "original": "what the learner said (only if hasError true)",
            "corrected": "improved version (only if hasError true)",
            "explanation": "brief friendly explanation (only if hasError true)"
          }}
        }}

        Rules:
        - Keep replies encouraging and natural.
        - Only correct real mistakes, never nitpick perfect sentences.
        - Use vocabulary appropriate for {level} level.
        - Never break out of JSON format.
        """;
}
