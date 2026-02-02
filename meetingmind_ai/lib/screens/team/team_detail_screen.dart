import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/services/team_service.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _members = [];
  List<dynamic> _events = [];
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final members = await TeamService.listMembers(teamId: widget.teamId);
      final events = await TeamService.listTeamEvents(teamId: widget.teamId);
      if (mounted) {
        final userId = context.read<AuthProvider>().userId;
        final owner = members
            .cast<Map<String, dynamic>>()
            .firstWhere((m) => m['role'] == 'owner', orElse: () => {});
        final isOwner = owner.isNotEmpty &&
            owner['user_id'] != null &&
            owner['user_id'] == userId;
        setState(() {
          _members = members;
          _events = events;
          _isOwner = isOwner;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeMember(String memberId) async {
    final ownerId = context.read<AuthProvider>().userId;
    if (ownerId == null || ownerId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member?'),
        content: const Text('This user will be removed from the team.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await TeamService.removeMember(
        teamId: widget.teamId,
        ownerId: ownerId,
        memberId: memberId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _deleteTeam() async {
    final ownerId = context.read<AuthProvider>().userId;
    if (ownerId == null || ownerId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete team?'),
        content: const Text('This will remove the team and all its data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await TeamService.deleteTeam(teamId: widget.teamId, ownerId: ownerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team deleted')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _inviteMember() async {
    final ownerId = context.read<AuthProvider>().userId;
    if (ownerId == null || ownerId.isEmpty) return;

    final controller = TextEditingController();
    final memberEmail = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite member'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Member email',
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
            child: const Text('Invite'),
          ),
        ],
      ),
    );

    if (memberEmail == null || memberEmail.isEmpty) return;

    try {
      await TeamService.inviteMember(
        teamId: widget.teamId,
        ownerId: ownerId,
        memberEmail: memberEmail,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite sent')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _createEvent() async {
    final creatorId = context.read<AuthProvider>().userId;
    if (creatorId == null || creatorId.isEmpty) return;

    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    DateTime? start;
    DateTime? end;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create team event'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: locationCtrl,
              decoration: const InputDecoration(
                hintText: 'Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDate: DateTime.now(),
                );
                if (picked == null) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time == null) return;
                start = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  time.hour,
                  time.minute,
                );
                end = start!.add(const Duration(hours: 1));
              },
              icon: const Icon(Icons.schedule),
              label: const Text('Pick time'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != true) return;
    if (titleCtrl.text.trim().isEmpty || start == null || end == null) return;

    try {
      await TeamService.createTeamEvent(
        teamId: widget.teamId,
        creatorId: creatorId,
        title: titleCtrl.text.trim(),
        startTime: start!,
        endTime: end!,
        location:
            locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created')),
        );
        _load();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
          if (_isOwner)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteTeam,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('Members',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ..._members.map((m) {
                      final memberId = m['user_id']?.toString() ?? '';
                      final role = m['role']?.toString() ?? '';
                      final status = m['status']?.toString() ?? '';
                      return ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: Text(memberId),
                        subtitle: Text('$role • $status'),
                        trailing: _isOwner && role != 'owner'
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _removeMember(memberId),
                              )
                            : null,
                      );
                    }),
                    const SizedBox(height: 20),
                    Text('Events',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_events.isEmpty)
                      const Text('No events yet')
                    else
                      ..._events.map((e) => ListTile(
                            leading: const Icon(Icons.event),
                            title: Text(e['title'] ?? ''),
                            subtitle: Text(
                                '${e['start_time'] ?? ''} → ${e['end_time'] ?? ''}'),
                          )),
                  ],
                ),
      floatingActionButton: _isOwner
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'invite',
                  onPressed: _inviteMember,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Invite'),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'event',
                  onPressed: _createEvent,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Create event'),
                ),
              ],
            )
          : null,
    );
  }
}
