import 'package:meetingmind_ai/models/meeting_models.dart';
import 'package:meetingmind_ai/services/meeting_service.dart';
import 'package:meetingmind_ai/services/notebook_list_service.dart';

class DashboardLogic {
  static Future<DashboardData> load(String userId) async {
    final meetingService = MeetingService(userId);
    final meetings = await meetingService.getPastMeetings();
    final notebooks = await NotebookListService.fetchFolders(userId);

    final pastMeetings =
        meetings.where((meeting) => meeting.date.isBefore(DateTime.now())).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return DashboardData(
      recentMeetings: pastMeetings.take(4).toList(),
      notebooks: notebooks,
    );
  }

  static DashboardHeaderData buildHeader({
    required String? googleDisplayName,
    required String? localName,
    required bool isLoggedIn,
    required String? avatarUrl,
  }) {
    final rawName = googleDisplayName?.trim();
    final savedName = localName?.trim();

    final displayName = (rawName != null && rawName.isNotEmpty)
        ? rawName.split(RegExp(r'\s+')).first
        : (savedName != null && savedName.isNotEmpty
            ? savedName.split(RegExp(r'\s+')).first
            : (isLoggedIn ? 'User' : 'Guest'));

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : (hour < 18 ? 'Good Afternoon' : 'Good Evening');

    return DashboardHeaderData(
      greeting: greeting,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }
}

class DashboardData {
  final List<Meeting> recentMeetings;
  final List<dynamic> notebooks;

  const DashboardData({
    required this.recentMeetings,
    required this.notebooks,
  });
}

class DashboardHeaderData {
  final String greeting;
  final String displayName;
  final String? avatarUrl;

  const DashboardHeaderData({
    required this.greeting,
    required this.displayName,
    required this.avatarUrl,
  });
}
