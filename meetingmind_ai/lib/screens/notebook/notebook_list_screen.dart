import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/services/notebook_list_service.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/config/plan_limits.dart';
import 'package:meetingmind_ai/widgets/upgrade_dialog.dart';

class NotebookListScreen extends StatefulWidget {
  const NotebookListScreen({super.key});

  @override
  State<NotebookListScreen> createState() => _NotebookListScreenState();
}

class _NotebookListScreenState extends State<NotebookListScreen> {
  // Danh sách màu sắc được giữ nguyên từ mẫu Flutter (Google-esque)
  final List<Color> _notebookColors = [
    const Color(0xFF4285F4), // Google Blue
    const Color(0xFFEA4335), // Google Red
    const Color(0xFFFBBC05), // Google Yellow
    const Color(0xFF34A853), // Google Green
    const Color(0xFFAA00FF), // Purple
    const Color(0xFF00ACC1), // Cyan
  ];

  List<dynamic> _folders = [];
  bool _isLoading = true;
  String? _errorMessage;

  late String _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userId = context.read<AuthProvider>().userId!;
      _fetchFolders();
    });
  }

  Future<void> _fetchFolders() async {
    try {
      final data = await NotebookListService.fetchFolders(_userId);
      setState(() {
        _folders = data;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<bool> _showDeleteConfirm(BuildContext context, String name) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete notebook', style: theme.textTheme.titleLarge),
        content: Text(
            'Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: colorScheme.onSurface)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    return confirm ?? false;
  }

  Future<void> _deleteFolder(String folderId) async {
    try {
      await NotebookListService.deleteFolder(folderId);
      // Refresh list after delete
      await _fetchFolders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notebook deleted successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete notebook: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Format ngày tháng đơn giản
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = context.watch<AuthProvider>();
    final plan = auth.plan;
    final folderLimit = PlanLimits.folderLimitFromLimits(auth.limits) ??
        PlanLimits.folderLimit(plan);
    final canCreateFolder =
        folderLimit == null || _folders.length < folderLimit;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar giữ nguyên từ mẫu
          SliverAppBar(
            floating: true,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 80,
            title: Text(
              'Notebooks',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                  onPressed: _fetchFolders,
                ),
              ),
            ],
          ),

          // Loading State
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Error State
          if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: colorScheme.error),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.tonal(
                      onPressed: _fetchFolders,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ),

          // List State
          if (!_isLoading && _errorMessage == null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final folder = _folders[index];
                    final color =
                        _notebookColors[index % _notebookColors.length];
                    // Sử dụng Card được cập nhật theo phong cách React
                    return _buildProjectCard(
                        context, folder, color, colorScheme);
                  },
                  childCount: _folders.length,
                ),
              ),
            ),

          // Empty State (Được cập nhật nội dung theo React)
          if (!_isLoading && _errorMessage == null && _folders.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon hình tròn gradient mô phỏng React
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4DD0E1), Color(0xFF2979FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.create_new_folder_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Create Your First Project',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Organize documents by topic. Upload multiple sources per project and chat with them using AI.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            if (!canCreateFolder) {
              showUpgradeDialog(
                context,
                message: 'You have reached the notebook limit for $plan plan.',
              );
              return;
            }
            context.push('/create_notebook');
          },
          elevation: 4,
          backgroundColor: const Color(0xFF2962FF), // Vibrant Blue
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('New',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
      ),
    );
  }

  // Widget Card được cập nhật để giống ProjectCard trong React
  Widget _buildProjectCard(
    BuildContext context,
    Map<String, dynamic> folder,
    Color accentColor,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);

    final String name = folder['name'] ?? 'Untitled';
    final String description = folder['description'] ?? 'No description added.';
    // Giả sử API trả về 'updated_at' hoặc dùng 'created_at' làm fallback
    final String dateStr = folder['updated_at'] ?? folder['created_at'] ?? '';
    // Giả sử API trả về 'source_count' hoặc tính từ mảng sources nếu có
    final int sourceCount = folder['source_count'] ?? 0;

    return Dismissible(
      key: Key(folder['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirm(context, name);
      },
      onDismissed: (direction) {
        _deleteFolder(folder['id']);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: InkWell(
            onTap: () {
              context.push('/notebook_detail/${folder['id']}');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon màu sắc (Tương ứng color tag trong React)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Nội dung
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Description
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Footer: Sources count & Date (Giống layout React)
                        Row(
                          children: [
                            // Source Count Icon
                            Icon(
                              Icons.attach_file_rounded,
                              size: 13,
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$sourceCount sources',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Date Icon
                            Icon(
                              Icons.schedule_outlined,
                              size: 13,
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(dateStr),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant
                                    .withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Mũi tên điều hướng
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}