import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/session_provider.dart';
import '../models/models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF130720),
        title: const Text('Nativa', style: TextStyle(color: Color(0xFFa78bfa), fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'New learning plan',
            onPressed: () => Navigator.pushNamed(context, '/create-plan').then((_) => dash.load()),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: dash.isLoading
          ? const Center(child: CircularProgressIndicator())
          : dash.error != null
              ? Center(child: Text(dash.error!, style: const TextStyle(color: Colors.redAccent)))
              : RefreshIndicator(
                  onRefresh: dash.load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Greeting
                      if (dash.user != null)
                        Text('Hello, ${dash.user!.name} 👋',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                      const SizedBox(height: 20),

                      // Plans
                      if (dash.plans.isEmpty)
                        _EmptyPlans(onTap: () => Navigator.pushNamed(context, '/create-plan').then((_) => dash.load()))
                      else
                        ...dash.plans.map((plan) => _PlanCard(plan: plan)),

                      // Recent sessions
                      if (dash.recentSessions.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Recent sessions',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70)),
                        const SizedBox(height: 8),
                        ...dash.recentSessions.map((s) => _RecentSessionTile(session: s)),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PlanModel plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final p = plan.progress;
    return Card(
      color: const Color(0xFF1a0a30),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4c1d95),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(plan.language, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0f6e56),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(plan.currentLevel, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            const Spacer(),
            Text('→ ${plan.targetLevel}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
          const SizedBox(height: 12),

          // XP bar
          Text('XP to ${_nextLevel(plan.currentLevel)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p.xpPercent,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFa78bfa)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text('${p.xpCurrentLevel} / ${p.xpToNextLevel} XP',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),

          // Stats row
          Row(children: [
            _Stat('${p.totalSessions}', 'sessions'),
            const SizedBox(width: 20),
            _Stat('${p.streakDays}', 'day streak'),
            const SizedBox(width: 20),
            _Stat('${p.totalXp}', 'total XP'),
          ]),
          const SizedBox(height: 16),

          // Today's topic
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(children: [
              const Icon(Icons.today, color: Color(0xFFa78bfa), size: 18),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Today's topic", style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(plan.todayTopic, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ])),
            ]),
          ),
          const SizedBox(height: 12),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final session = context.read<SessionProvider>();
                session.reset();
                await session.startSession(plan.id);
                if (context.mounted) Navigator.pushNamed(context, '/session');
              },
            ),
          ),
        ]),
      ),
    );
  }

  String _nextLevel(String level) {
    const map = {'A1':'A2','A2':'B1','B1':'B2','B2':'C1','C1':'C2','C2':'C2'};
    return map[level] ?? level;
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
  ]);
}

class _EmptyPlans extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyPlans({required this.onTap});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(children: [
      const SizedBox(height: 40),
      const Icon(Icons.school_outlined, color: Colors.grey, size: 64),
      const SizedBox(height: 16),
      const Text('No learning plans yet', style: TextStyle(color: Colors.white70, fontSize: 16)),
      const SizedBox(height: 8),
      const Text('Create your first plan to get started', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
        child: const Text('Create a plan'),
      ),
    ]),
  );
}

class _RecentSessionTile extends StatelessWidget {
  final RecentSession session;
  const _RecentSessionTile({required this.session});
  @override
  Widget build(BuildContext context) {
    final mins = (session.durationSeconds / 60).round();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF1e0e35),
        child: Text(session.level, style: const TextStyle(color: Color(0xFFa78bfa), fontSize: 12)),
      ),
      title: Text(session.topic, style: const TextStyle(color: Colors.white, fontSize: 13)),
      subtitle: Text('${session.language} · ${mins}m · ${session.messageCount} messages',
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}
