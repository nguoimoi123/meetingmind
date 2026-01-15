import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotebookListScreen extends StatefulWidget {
  const NotebookListScreen({super.key});

  @override
  State<NotebookListScreen> createState() => _NotebookListScreenState();
}

class _NotebookListScreenState extends State<NotebookListScreen> {
  // =========================
  // STATE VARIABLES
  // =========================
  List<dynamic> _folders = []; // Chứa dữ liệu từ API
  bool _isLoading = true; // Trạng thái đang tải
  String? _errorMessage; // Thông báo lỗi (nếu có)

  // User ID cố định (Lấy từ curl của bạn)
  final String _userId = "6965304ba729391015e6d079";

  // =========================
  // PALETTE MÀU
  // =========================
  final List<Color> _cardColors = const [
    Color(0xFF6366F1), // Indigo
    Color(0xFFEC4899), // Pink
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Violet
  ];

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
      // Đối với Android Emulator dùng 10.0.2.2, iOS/Máy thật dùng 127.0.0.1
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/folder/$_userId'),
      );

      if (response.statusCode == 200) {
        // Parse JSON
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

  // Hàm đơn giản để format ngày tháng (YYYY-MM-DD)
  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString; // Trả về gốc nếu lỗi
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          // --- HEADER ---
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 72,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Notebooks',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    // Nút reload nếu cần
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.grey),
                      onPressed: _fetchFolders,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- LOADING STATE ---
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),

          // --- ERROR STATE ---
          if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $_errorMessage', textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _fetchFolders,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          // --- LIST NOTEBOOKS (SUCCESS) ---
          if (!_isLoading && _errorMessage == null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final folder = _folders[index];
                    final color = _cardColors[index % _cardColors.length];

                    return _buildNotebookRow(
                      context,
                      folder,
                      color,
                    );
                  },
                  childCount: _folders.length,
                ),
              ),
            ),
        ],
      ),

      // --- FLOATING ACTION BUTTON ---
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => context.push('/create_notebook'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'New',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // =========================
  // NOTEBOOK ITEM
  // =========================
  Widget _buildNotebookRow(
    BuildContext context,
    Map<String, dynamic> folder,
    Color color,
  ) {
    // Lấy dữ liệu từ JSON response
    final String name = folder['name'] ?? 'Untitled';
    final String description = folder['description'] ?? 'No description';
    final String createdAt = folder['created_at'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Có thể truyền ID của folder vào màn hình chi tiết nếu cần
            // context.push('/notebook_detail', extra: folder['id']);
            context.push('/notebook_detail/${folder['id']}');
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            // Tự động điều chỉnh chiều cao hoặc để nội dung quyết định
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment
                  .start, // Căn trên để description dài không bị vỡ layout
              children: [
                // ICON
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Hiển thị mô tả thay vì stats (do API không trả về stats)
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Hiển thị ngày tháng
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
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
                  padding: const EdgeInsets.only(top: 20.0), // Căn với tiêu đề
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: color,
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
