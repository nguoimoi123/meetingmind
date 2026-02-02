import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class MeetingManagementService {
  static Future<Map<String, dynamic>> getMeetingDetail({
    required String sid,
  }) async {
    final res = await http.get(Uri.parse('$apiBaseUrl/meetings/$sid'));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to load meeting detail');
  }

  static Future<List<String>> updateMeetingTags({
    required String sid,
    required List<String> tags,
  }) async {
    final res = await http.put(
      Uri.parse('$apiBaseUrl/meetings/$sid/tags'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tags': tags}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<String>.from(data['tags'] ?? []);
    }

    throw Exception('Failed to update tags');
  }

  static Future<void> updateSpeakerMapping({
    required String sid,
    Map<String, String>? speakerNames,
    String? speakerId,
    String? name,
  }) async {
    final body = <String, dynamic>{};
    if (speakerNames != null) {
      body['speaker_names'] = speakerNames;
    }
    if (speakerId != null && name != null) {
      body['speaker_id'] = speakerId;
      body['name'] = name;
    }

    final res = await http.put(
      Uri.parse('$apiBaseUrl/meetings/$sid/speakers'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to update speaker mapping');
    }
  }

  static Future<int> actionItemsToTasks({
    required String sid,
    required String userId,
    List<Map<String, dynamic>>? items,
    DateTime? defaultStart,
  }) async {
    final body = <String, dynamic>{'user_id': userId};
    if (items != null) body['items'] = items;
    if (defaultStart != null) {
      body['default_start'] = defaultStart.toUtc().toIso8601String();
    }

    final res = await http.post(
      Uri.parse('$apiBaseUrl/meetings/$sid/action-items/to-tasks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return (data['count'] ?? 0) as int;
    }

    throw Exception('Failed to create tasks');
  }

  static Future<Map<String, dynamic>> getNextAgenda({
    required String userId,
    int limit = 5,
  }) async {
    final uri = Uri.parse(
        '$apiBaseUrl/meetings/agenda/next?user_id=$userId&limit=$limit');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to load agenda suggestions');
  }
}
