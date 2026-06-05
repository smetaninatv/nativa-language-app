import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';

class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key});
  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  String _language = 'English';
  String _targetLevel = 'C1';
  int _sessionsPerWeek = 3;

  final _languages = ['English', 'Polish', 'German', 'French', 'Spanish', 'Italian'];
  final _levels = ['A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('New learning plan'),
        backgroundColor: const Color(0xFF130720),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Language', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _language,
              dropdownColor: const Color(0xFF1a0a30),
              decoration: InputDecoration(
                filled: true, fillColor: const Color(0xFF1a0a30),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setState(() => _language = v!),
            ),
            const SizedBox(height: 20),
            const Text('Target level', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _targetLevel,
              dropdownColor: const Color(0xFF1a0a30),
              decoration: InputDecoration(
                filled: true, fillColor: const Color(0xFF1a0a30),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: _levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setState(() => _targetLevel = v!),
            ),
            const SizedBox(height: 20),
            Text('Sessions per week: $_sessionsPerWeek', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            Slider(
              value: _sessionsPerWeek.toDouble(),
              min: 1, max: 7, divisions: 6,
              activeColor: const Color(0xFF7C3AED),
              label: _sessionsPerWeek.toString(),
              onChanged: (v) => setState(() => _sessionsPerWeek = v.round()),
            ),
            const SizedBox(height: 8),
            Text(
              _sessionsPerWeek <= 2 ? 'Casual pace — great for staying consistent'
              : _sessionsPerWeek <= 4 ? 'Steady pace — good balance'
              : 'Intensive pace — fastest progress',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 32),
            if (dash.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(dash.error!, style: const TextStyle(color: Colors.redAccent)),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: dash.isLoading ? null : () async {
                  final ok = await dash.createPlan(_language, _targetLevel, _sessionsPerWeek);
                  if (ok && context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: dash.isLoading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create plan', style: TextStyle(fontSize: 16)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
