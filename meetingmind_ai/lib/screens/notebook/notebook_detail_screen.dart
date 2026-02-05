import 'package:flutter/material.dart';
import 'package:meetingmind_ai/screens/notebook/sources_tab.dart';
import 'package:meetingmind_ai/screens/notebook/ask_ai_tab.dart';
import 'package:meetingmind_ai/screens/notebook/studio_tab.dart';
import 'package:meetingmind_ai/services/file_service.dart';

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
    final data = await FileService.getFolder(widget.folderId);
    setState(() => _folderName = data['folder_name']);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: colorScheme.background,
        body: Column(
          children: [
            _buildHeader(context, theme, colorScheme),
            _buildTabBar(theme, colorScheme),
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

  // UI Header đẹp hơn từ code mẫu 2
  Widget _buildHeader(BuildContext context, ThemeData theme, ColorScheme cs) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
        child: Row(
          children: [
            // Nút Back tròn, tinh tế
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.surface,
                border: Border.all(color: cs.outline.withOpacity(0.2)),
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: cs.onSurface),
                onPressed: () => Navigator.of(context).pop(),
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notebook',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _folderName.isNotEmpty ? _folderName : 'Loading...',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onBackground,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI TabBar đẹp hơn với shadow
  Widget _buildTabBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      height: 50,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle:
            theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle:
            theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Sources'),
          Tab(text: 'Ask AI'),
          Tab(text: 'Studio'),
        ],
      ),
    );
  }
}
