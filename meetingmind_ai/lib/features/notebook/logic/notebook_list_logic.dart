import 'package:meetingmind_ai/config/plan_limits.dart';
import 'package:meetingmind_ai/services/notebook_list_service.dart';

class NotebookListLogic {
  static const List<int> notebookColorValues = [
    0xFF4285F4,
    0xFFEA4335,
    0xFFFBBC05,
    0xFF34A853,
    0xFFAA00FF,
    0xFF00ACC1,
  ];

  static Future<List<dynamic>> fetchFolders(String userId) {
    return NotebookListService.fetchFolders(userId);
  }

  static Future<void> deleteFolder(String folderId) {
    return NotebookListService.deleteFolder(folderId);
  }

  static bool canCreateFolder({
    required String plan,
    required Map<String, dynamic> limits,
    required int currentCount,
  }) {
    final folderLimit =
        PlanLimits.folderLimitFromLimits(limits) ?? PlanLimits.folderLimit(plan);
    return folderLimit == null || currentCount < folderLimit;
  }

  static String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }
}
