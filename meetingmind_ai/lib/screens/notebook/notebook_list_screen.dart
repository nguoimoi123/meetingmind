import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/services/notebook_list_service.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';

class NotebookListScreen extends StatefulWidget {
  const NotebookListScreen({super.key});

  @override
  State<NotebookListScreen> createState() => _NotebookListScreenState();
}

class _NotebookListScreenState extends State<NotebookListScreen> {
  // Danh sách màu sắc Google-esque cho icon (Blue, Red, Yellow, Green, Purple)
  final List<Color> _notebookColors = [
    const Color(0xFF4285F4), // Google Blue
    const Color(0xFFEA4335), // Google Red
    const Color(0xFFFBBC05), // Google Yellow
    const Color(0xFF34A853), // Google Green
    const Color(0xFFAA00FF), // Purple
    const Color(0xFF00ACC1), // Cyan
  ];

  final NotebookListService _notebookListService = NotebookListService();

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

    return Scaffold(
      backgroundColor: colorScheme.surface, // Nền chính
      body: CustomScrollView(
        slivers: [
          // App Bar hiện đại, trong suốt
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
              padding: const EdgeInsets.fromLTRB(
                  16, 0, 16, 100), // Padding horizontal
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final folder = _folders[index];
                    // Lấy màu dựa trên index để tạo sự đa dạng
                    final color =
                        _notebookColors[index % _notebookColors.length];
                    return _buildNotebookCard(
                        context, folder, color, colorScheme);
                  },
                  childCount: _folders.length,
                ),
              ),
            ),

          // Empty State (Optional UI polish)
          if (!_isLoading && _errorMessage == null && _folders.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.book_outlined,
                        size: 64,
                        color: colorScheme.onSurface.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Text(
                      'No notebooks yet',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a new notebook to get started',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // Floating Action Button kiểu Google (dạng tròn hoặc có nhãn)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 24.0, right: 16.0),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/create_notebook'),
          elevation: 4,
          backgroundColor: Color(0xFF2962FF),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('New Notebook',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
      ),
    );
  }

  Widget _buildNotebookCard(
    BuildContext context,
    Map<String, dynamic> folder,
    Color accentColor,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);

    final String name = folder['name'] ?? 'Untitled';
    final String description = folder['description'] ?? 'No description added.';
    final String createdAt = folder['created_at'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surfaceContainerLow, // Màu nền xám rất nhạt
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
                color: colorScheme.outline.withOpacity(0.1), // Viền rất mờ
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Notebook với màu sắc động
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        accentColor.withOpacity(0.1), // Nhấn màu nền icon nhẹ
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.description_outlined, // Icon tài liệu
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Nội dung chính
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tiêu đề
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

                      // Mô tả
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

                      // Footer: Ngày tạo và dấu chấm trỏ
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_outlined,
                            size: 13,
                            color:
                                colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Created ${_formatDate(createdAt)}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Icon mũi tên bên phải (tuỳ chọn, mang tính điều hướng)
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
    );
  }
}
