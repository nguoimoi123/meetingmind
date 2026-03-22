import 'package:meetingmind_ai/services/file_service.dart';

class NotebookDetailLogic {
  static Future<String> fetchFolderName(String folderId) async {
    final data = await FileService.getFolder(folderId);
    return data['folder_name']?.toString() ?? '';
  }
}
