import 'package:flutter/material.dart';
import 'package:meetingmind_ai/features/notebook/logic/notebook_detail_logic.dart';
import 'package:meetingmind_ai/features/notebook/presentation/widgets/notebook_detail_header.dart';
import 'package:meetingmind_ai/features/notebook/presentation/widgets/notebook_detail_tab_bar.dart';
import 'package:meetingmind_ai/features/notebook/presentation/screens/ask_ai_screen.dart';
import 'package:meetingmind_ai/features/notebook/presentation/screens/sources_screen.dart';
import 'package:meetingmind_ai/features/notebook/presentation/screens/studio_screen.dart';

class NotebookDetailScreen extends StatefulWidget {
  final String folderId;

  const NotebookDetailScreen({super.key, required this.folderId});

  @override
  State<NotebookDetailScreen> createState() => _NotebookDetailScreenState();
}

class _NotebookDetailScreenState extends State<NotebookDetailScreen> {
  String _folderName = '';

  @override
  void initState() {
    super.initState();
    _fetchFolderInfo();
  }

  Future<void> _fetchFolderInfo() async {
    final folderName = await NotebookDetailLogic.fetchFolderName(widget.folderId);
    if (mounted) {
      setState(() => _folderName = folderName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Column(
          children: [
            NotebookDetailHeader(
              folderName: _folderName,
              onBack: () => Navigator.of(context).pop(),
            ),
            const NotebookDetailTabBar(),
            Expanded(
              child: TabBarView(
                children: [
                  SourcesTab(folderId: widget.folderId),
                  AskAITab(folderId: widget.folderId),
                  StudioTab(folderId: widget.folderId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
