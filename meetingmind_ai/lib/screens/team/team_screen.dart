import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/services/team_service.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _teams = [];
  List<dynamic> _invites = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTeams());
  }

  Future<void> _loadTeams() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null || userId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final teams = await TeamService.listTeams(userId: userId);
      final invites = await TeamService.listInvites(userId: userId);
      if (mounted) {
        setState(() {
          _teams = teams;
          _invites = invites;
        });
      }
      await _handlePendingInvite(invites);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePendingInvite(List<dynamic> invites) async {
    final prefs = await SharedPreferences.getInstance();
    final teamId = prefs.getString('pending_team_invite');
    if (teamId == null || teamId.isEmpty) return;

    final match = invites
        .cast<Map<String, dynamic>>()
        .firstWhere((i) => i['team_id'] == teamId, orElse: () => {});

    if (match.isEmpty) return;

    if (!mounted) return;
    final accept = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept invite?'),
        content: Text('Join team ${match['team_name'] ?? ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    await prefs.remove('pending_team_invite');

    if (accept == true) {
      await _acceptInvite(teamId);
    }
  }

  Future<void> _acceptInvite(String teamId) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null || userId.isEmpty) return;

    try {
      final data =
          await TeamService.acceptInvite(teamId: teamId, userId: userId);
      final plan = data['plan']?.toString();
      final planChanged = data['plan_changed'] == true;
      if (planChanged && plan != null && plan.isNotEmpty) {
        await context.read<AuthProvider>().setPlan(plan);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  planChanged ? 'Joined team • Plan upgraded' : 'Joined team')),
        );
        _loadTeams();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _createTeam() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null || userId.isEmpty) return;

    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create team'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Team name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      await TeamService.createTeam(ownerId: userId, name: result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team created')),
        );
        _loadTeams();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTeams,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  children: [
                    if (_invites.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Invites',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ..._invites.map((invite) {
                        final teamId = invite['team_id'] as String? ?? '';
                        return ListTile(
                          leading: const Icon(Icons.mail_outline_rounded),
                          title: Text(invite['team_name'] ?? 'Team'),
                          subtitle: Text('Owner: ${invite['owner_id'] ?? ''}'),
                          trailing: FilledButton(
                            onPressed: teamId.isEmpty
                                ? null
                                : () => _acceptInvite(teamId),
                            child: const Text('Accept'),
                          ),
                        );
                      }),
                      const Divider(height: 24),
                    ],
                    if (_teams.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Text(
                            'No teams yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      )
                    else
                      ..._teams.map((team) {
                        final t = team as Map<String, dynamic>;
                        return ListTile(
                          leading: const Icon(Icons.group_rounded),
                          title: Text(t['name'] ?? 'Untitled'),
                          subtitle: Text('Owner: ${t['owner_id']}'),
                          onTap: () => context.push('/app/team/${t['id']}'),
                        );
                      }),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createTeam,
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }
}
