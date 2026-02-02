import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TeamService {
  static Future<List<dynamic>> listTeams({required String userId}) async {
    final res = await http.get(Uri.parse('$apiBaseUrl/teams?user_id=$userId'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Failed to load teams');
  }

  static Future<Map<String, dynamic>> createTeam({
    required String ownerId,
    required String name,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/teams/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'owner_id': ownerId, 'name': name}),
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    throw Exception(body['error']?.toString() ?? 'Failed to create team');
  }

  static Future<List<dynamic>> listMembers({required String teamId}) async {
    final res = await http.get(Uri.parse('$apiBaseUrl/teams/$teamId/members'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Failed to load members');
  }

  static Future<void> inviteMember({
    required String teamId,
    required String ownerId,
    String? memberId,
    String? memberEmail,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/teams/$teamId/invite'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'owner_id': ownerId,
        if (memberId != null) 'member_id': memberId,
        if (memberEmail != null) 'member_email': memberEmail,
      }),
    );

    if (res.statusCode == 200) return;

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    throw Exception(body['error']?.toString() ?? 'Invite failed');
  }

  static Future<Map<String, dynamic>> acceptInvite({
    required String teamId,
    required String userId,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/teams/$teamId/accept'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    throw Exception(body['error']?.toString() ?? 'Accept failed');
  }

  static Future<List<dynamic>> listInvites({required String userId}) async {
    final res =
        await http.get(Uri.parse('$apiBaseUrl/teams/invites?user_id=$userId'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Failed to load invites');
  }

  static Future<Map<String, dynamic>> acceptInviteByToken({
    required String token,
    String? userId,
    String? email,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/teams/invites/accept'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        if (userId != null) 'user_id': userId,
        if (email != null) 'email': email,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    throw Exception(body['error']?.toString() ?? 'Accept failed');
  }

  static Future<Map<String, dynamic>> createTeamEvent({
    required String teamId,
    required String creatorId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
  }) async {
    final res = await http.post(
      Uri.parse('$apiBaseUrl/teams/$teamId/events'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'creator_id': creatorId,
        'title': title,
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'location': location,
      }),
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    throw Exception(body['error']?.toString() ?? 'Create event failed');
  }

  static Future<List<dynamic>> listTeamEvents({
    required String teamId,
  }) async {
    final res = await http.get(Uri.parse('$apiBaseUrl/teams/$teamId/events'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('Failed to load events');
  }

  static Future<void> removeMember({
    required String teamId,
    required String ownerId,
    required String memberId,
  }) async {
    final res = await http.delete(
      Uri.parse('$apiBaseUrl/teams/$teamId/members/$memberId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'owner_id': ownerId}),
    );

    if (res.statusCode == 200) return;

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    throw Exception(body['error']?.toString() ?? 'Remove member failed');
  }

  static Future<void> deleteTeam({
    required String teamId,
    required String ownerId,
  }) async {
    final res = await http.delete(
      Uri.parse('$apiBaseUrl/teams/$teamId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'owner_id': ownerId}),
    );

    if (res.statusCode == 200) return;

    final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    throw Exception(body['error']?.toString() ?? 'Delete team failed');
  }
}
