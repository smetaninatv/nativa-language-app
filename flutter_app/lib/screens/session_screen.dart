import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/models.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});
  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await context.read<SessionProvider>().sendMessage(text);
    _scrollToBottom();
  }

  Future<void> _endSession() async {
    final session = context.read<SessionProvider>();
    final summary = await session.endSession();
    if (!mounted) return;

    // Show summary dialog
    if (summary != null) {
      await showDialog(
        context: context,
        builder: (_) => _SummaryDialog(summary: summary),
      );
    }

    // Reload dashboard and go back
    await context.read<DashboardProvider>().load();
    if (mounted) {
      session.reset();
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    if (session.isStarting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (session.error != null && session.sessionId == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF130720)),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(session.error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
        )),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF130720),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(session.language, style: const TextStyle(fontSize: 14, color: Colors.white)),
          Text(session.topic, style: const TextStyle(fontSize: 11, color: Colors.grey),
              overflow: TextOverflow.ellipsis),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1a0a30),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFa78bfa), width: 0.5),
            ),
            child: Text(session.level, style: const TextStyle(color: Color(0xFFa78bfa), fontSize: 12)),
          ),
          TextButton(
            onPressed: _endSession,
            child: const Text('End', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(12),
            itemCount: session.messages.length + (session.isLoading ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == session.messages.length) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(children: [
                    SizedBox(width: 8),
                    SizedBox(height: 16, width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFa78bfa))),
                    SizedBox(width: 8),
                    Text('Aria is thinking...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                );
              }
              final msg = session.messages[i];
              return _MessageBubble(message: msg);
            },
          ),
        ),

        // Error
        if (session.error != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.red.withOpacity(0.1),
            child: Text(session.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ),

        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0f0f18),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                minLines: 1,
                maxLines: 4,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type your reply...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _send(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: session.isLoading ? null : _send,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: session.isLoading ? Colors.grey : const Color(0xFF7C3AED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        // Bubble
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: message.isUser ? const Color(0xFF4c1d95) : const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(message.isUser ? 16 : 4),
              bottomRight: Radius.circular(message.isUser ? 4 : 16),
            ),
            border: Border.all(
              color: message.isUser
                  ? const Color(0xFFa78bfa).withOpacity(0.3)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
        ),

        // Correction chip
        if (message.correction != null) ...[
          const SizedBox(height: 6),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFfbbf24).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFfbbf24).withOpacity(0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.lightbulb_outline, color: Color(0xFFfbbf24), size: 14),
                const SizedBox(width: 6),
                const Text('Correction', style: TextStyle(color: Color(0xFFfbbf24), fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
              const SizedBox(height: 6),
              RichText(text: TextSpan(children: [
                const TextSpan(text: 'You said: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                TextSpan(text: message.correction!.original, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
              const SizedBox(height: 2),
              RichText(text: TextSpan(children: [
                const TextSpan(text: 'Better: ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                TextSpan(text: message.correction!.corrected,
                    style: const TextStyle(color: Color(0xFF63d2be), fontSize: 12, fontWeight: FontWeight.w500)),
              ])),
              const SizedBox(height: 4),
              Text(message.correction!.explanation,
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _SummaryDialog extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _SummaryDialog({required this.summary});

  @override
  Widget build(BuildContext context) {
    final corrections = (summary['corrections'] as List? ?? []);
    final xp = summary['xpEarned'] ?? 0;
    final mins = ((summary['durationSeconds'] ?? 0) / 60).round();
    final msgs = summary['messageCount'] ?? 0;

    return AlertDialog(
      backgroundColor: const Color(0xFF1a0a30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Session complete! 🎉', style: TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _StatChip('$xp XP', const Color(0xFFa78bfa)),
          const SizedBox(width: 8),
          _StatChip('${mins}m', const Color(0xFF63d2be)),
          const SizedBox(width: 8),
          _StatChip('$msgs msgs', Colors.orange),
        ]),
        if (corrections.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Corrections this session', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          ...corrections.take(3).map((c) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('❌  ${c['original']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('✅  ${c['corrected']}', style: const TextStyle(color: Color(0xFF63d2be), fontSize: 12)),
            ]),
          )),
        ],
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done', style: TextStyle(color: Color(0xFFa78bfa))),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
  );
}
