import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/features/notebook/logic/notebook_list_logic.dart';
import 'package:meetingmind_ai/features/notebook/presentation/widgets/notebook_delete_dialog.dart';
import 'package:meetingmind_ai/features/notebook/presentation/widgets/notebook_empty_state.dart';
import 'package:meetingmind_ai/features/notebook/presentation/widgets/notebook_error_state.dart';
import 'package:meetingmind_ai/features/notebook/presentation/widgets/notebook_list_app_bar.dart';
import 'package:meetingmind_ai/features/notebook/presentation/widgets/notebook_list_item.dart';
import 'package:meetingmind_ai/l10n/app_localizations.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/widgets/upgrade_dialog.dart';
import 'package:provider/provider.dart';

class NotebookListScreen extends StatefulWidget {
  const NotebookListScreen({super.key});

  @override
  State<NotebookListScreen> createState() => _NotebookListScreenState();
}

class _NotebookListScreenState extends State<NotebookListScreen> {
  final List<Color> _notebookColors = NotebookListLogic.notebookColorValues
      .map((value) => Color(value))
      .toList();

  List<dynamic> _folders = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userId = context.read<AuthProvider>().userId;
      if (_userId != null) {
        _fetchFolders();
      }
    });
  }

  Future<void> _fetchFolders() async {
    if (_userId == null) return;

    try {
      final data = await NotebookListLogic.fetchFolders(_userId!);
      if (!mounted) return;
      setState(() {
        _folders = data;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _deleteFolder(String folderId) async {
    try {
      await NotebookListLogic.deleteFolder(folderId);
      await _fetchFolders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.tr('notebookDeletedSuccessfully')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.tr('failedDeleteNotebook', params: {'error': '$e'}),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final l10n = context.l10n;
    final plan = auth.plan;
    final canCreateFolder = NotebookListLogic.canCreateFolder(
      plan: plan,
      limits: auth.limits,
      currentCount: _folders.length,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          NotebookListAppBar(onRefresh: _fetchFolders),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_errorMessage != null)
            SliverFillRemaining(
              child: NotebookErrorState(
                message: _errorMessage!,
                onRetry: _fetchFolders,
              ),
            ),
          if (!_isLoading && _errorMessage == null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final folder = _folders[index] as Map<String, dynamic>;
                    final color =
                        _notebookColors[index % _notebookColors.length];
                    return NotebookListItem(
                      folder: folder,
                      accentColor: color,
                      onConfirmDismiss: () => showNotebookDeleteDialog(
                        context,
                        name: folder['name'] ?? l10n.tr('untitled'),
                      ),
                      onDismissed: () => _deleteFolder(folder['id']),
                    );
                  },
                  childCount: _folders.length,
                ),
              ),
            ),
          if (!_isLoading && _errorMessage == null && _folders.isEmpty)
            const SliverFillRemaining(child: NotebookEmptyState()),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            if (!canCreateFolder) {
              showUpgradeDialog(
                context,
                message: l10n.tr(
                  'notebookLimitReached',
                  params: {'plan': plan},
                ),
              );
              return;
            }
            context.push('/app/notebooks/create');
          },
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            l10n.tr('newLabel'),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
    );
  }
}
