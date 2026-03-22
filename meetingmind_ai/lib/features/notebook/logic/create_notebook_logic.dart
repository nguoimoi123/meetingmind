import 'package:meetingmind_ai/config/plan_limits.dart';
import 'package:meetingmind_ai/services/create_notebook_service.dart';
import 'package:meetingmind_ai/services/notebook_list_service.dart';

class CreateNotebookLogic {
  static bool hasRequiredText(String title) => title.trim().isNotEmpty;

  static Future<bool> canCreateNotebook({
    required String userId,
    required String plan,
    required Map<String, dynamic> limits,
  }) async {
    final folderLimit =
        PlanLimits.folderLimitFromLimits(limits) ?? PlanLimits.folderLimit(plan);

    if (folderLimit == null) {
      return true;
    }

    final folders = await NotebookListService.fetchFolders(userId);
    return folders.length < folderLimit;
  }

  static Future<void> createNotebook({
    required String userId,
    required String name,
    required String description,
  }) {
    return NotebookService.createNotebook(
      userId: userId,
      name: name.trim(),
      description: description.trim(),
    );
  }
}
