import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Giả sử bạn đã import file AppTheme ở đây hoặc nó được áp dụng qua main.dart
// import 'app_theme.dart';

class NotebookListScreen extends StatefulWidget {
  const NotebookListScreen({super.key});

  @override
  State<NotebookListScreen> createState() => _NotebookListScreenState();
}

class _NotebookListScreenState extends State<NotebookListScreen> {
  // =========================
  // STATE VARIABLES
  // =========================
  List<dynamic> _folders = [];
  bool _isLoading = true;
  String? _errorMessage;

  final String _userId = "6965304ba729391015e6d079";

  @override
  void initState() {
    super.initState();
    _fetchFolders();
  }

  // =========================
  // API CALL
  // =========================
  Future<void> _fetchFolders() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/folder/$_userId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _folders = data;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load folders: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Lấy theme hiện tại (Light hoặc Dark)
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Sử dụng màu background từ theme
      backgroundColor: colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // --- HEADER ---
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 80, // Tăng nhẹ chiều cao cho thoáng
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Notebooks',
                      // Sử dụng headlineMedium từ theme AppTheme
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onBackground, // Màu chữ thích ứng
                        letterSpacing: -0.5,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh,
                          color: colorScheme.onSurface.withOpacity(0.7)),
                      onPressed: _fetchFolders,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- LOADING STATE ---
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                  child: CircularProgressIndicator(color: colorScheme.primary)),
            ),

          // --- ERROR STATE ---
          if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: $_errorMessage',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.error),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _fetchFolders,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          // --- LIST NOTEBOOKS ---
          if (!_isLoading && _errorMessage == null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final folder = _folders[index];
                    // Truyền màu PrimaryColor của theme cho icon để đồng bộ
                    return _buildNotebookRow(
                      context,
                      folder,
                      colorScheme.primary,
                    );
                  },
                  childCount: _folders.length,
                ),
              ),
            ),
        ],
      ),

      // --- FLOATING ACTION BUTTON ---
      // Sử dụng FloatingActionButton.extended nhưng chỉnh style theo theme
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(16.0), // Padding để cách méo
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/create_notebook'),
          backgroundColor: colorScheme.secondary, // AccentColor trong AppTheme
          foregroundColor: colorScheme.onSecondary, // Màu chữ trắng
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'New',
            style: theme.textTheme.labelLarge, // Font chữ bold từ AppTheme
          ),
        ),
      ),
    );
  }

  Widget _buildNotebookRow(
    BuildContext context,
    Map<String, dynamic> folder,
    Color color,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final String name = folder['name'] ?? 'Untitled';
    final String description = folder['description'] ?? 'No description';
    final String createdAt = folder['created_at'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/notebook_detail/${folder['id']}');
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            // Sử dụng CardTheme color, nếu cần tùy biến thêm thì dùng surface
            decoration: BoxDecoration(
              color:
                  colorScheme.surface, // Màu nền card (White hoặc Dark Surface)
              borderRadius: BorderRadius.circular(20),
              // Viền mỏng nhẹ theo màu chủ đạo nhưng trong suốt
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.1),
                width: 1,
              ),
              // Đổ bóng nhẹ giống CardTheme
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ICON
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1), // Màu nền icon nhạt hơn
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.folder_rounded,
                    color: color, // Màu icon theo màu primary
                    size: 32,
                  ),
                ),

                const SizedBox(width: 20),

                // TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 12,
                              color: colorScheme.onSurface.withOpacity(0.4)),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ARROW
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.3),
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
