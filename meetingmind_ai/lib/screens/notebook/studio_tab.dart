import 'package:flutter/material.dart';

class StudioTab extends StatefulWidget {
  final String folderId;
  const StudioTab({super.key, required this.folderId});

  @override
  State<StudioTab> createState() => _StudioTabState();
}

class _StudioTabState extends State<StudioTab> {
  // Dữ liệu các tính năng
  final List<Map<String, dynamic>> _features = [
    {
      'title': 'Tóm tắt âm thanh',
      'description': 'Chuyển văn bản thành giọng đọc tự nhiên.',
      'icon': Icons.headphones_rounded,
      'colors': [const Color(0xFF7F00FF), const Color(0xFFE100FF)], // Purple Gradient
    },
    {
      'title': 'Bảng đồ tư duy',
      'description': 'Trực quan hóa ý tưởng và mối liên hệ.',
      'icon': Icons.account_tree_rounded,
      'colors': [const Color(0xFF00C6FF), const Color(0xFF0072FF)], // Blue Gradient
    },
    {
      'title': 'Tóm tắt nhanh',
      'description': 'Trích xuất ý chính chỉ trong vài giây.',
      'icon': Icons.auto_awesome_rounded,
      'colors': [const Color(0xFF56AB2F), const Color(0xFFA8E063)], // Green Gradient
    },
    {
      'title': 'Flashcards',
      'description': 'Tạo thẻ ghi nhớ ôn tập hiệu quả.',
      'icon': Icons.style_rounded,
      'colors': [const Color(0xFFF7971E), const Color(0xFFFFD200)], // Yellow Gradient
    },
  ];

  // Dữ liệu file kết quả (mock data)
  final List<Map<String, dynamic>> _generatedFiles = [
    {
      'id': '1',
      'name': 'Summary_Q4_Report.pdf',
      'type': 'Tóm tắt',
      'icon': Icons.picture_as_pdf_rounded,
      'size': '2.4 MB',
      'date': '2 giờ trước',
      'color': const Color(0xFF6366F1),
    },
    {
      'id': '2',
      'name': 'Mindmap_Strategy.png',
      'type': 'Bảng đồ tư duy',
      'icon': Icons.image_rounded,
      'size': '1.8 MB',
      'date': '5 giờ trước',
      'color': const Color(0xFF00C6FF),
    },
    {
      'id': '3',
      'name': 'Flashcards_Marketing.pdf',
      'type': 'Flashcards',
      'icon': Icons.picture_as_pdf_rounded,
      'size': '856 KB',
      'date': '1 ngày trước',
      'color': const Color(0xFFF7971E),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      // Header đơn giản
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Studio',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Chọn công cụ để biến đổi tài liệu của bạn',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Grid chứa các thẻ chức năng
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 cột
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85, // Tỷ lệ khung hình thẻ
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final feature = _features[index];
                  return _buildFeatureCard(feature, colorScheme);
                },
                childCount: _features.length,
              ),
            ),
          ),
          
          // Section: Generated Files
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.folder_special_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Kết quả đã tạo',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_generatedFiles.length}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // List các file kết quả
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final file = _generatedFiles[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildGeneratedFileCard(file, theme, colorScheme),
                  );
                },
                childCount: _generatedFiles.length,
              ),
            ),
          ),
          
          // Padding底部 để không bị FAB che (nếu có)
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature, ColorScheme colorScheme) {
    final List<Color> colors = feature['colors'];
    
    return InkWell(
      onTap: () {
        // Xử lý khi click vào thẻ
        // Ví dụ: Navigator.push(...);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mở tính năng: ${feature['title']}')),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          // Nền Gradient
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon nền trắng trong suốt
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  feature['icon'],
                  color: Colors.white,
                  size: 28,
                ),
              ),
              
              const Spacer(),

              // Tiêu đề và mô tả
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature['title'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    feature['description'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratedFileCard(
    Map<String, dynamic> file,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Dismissible(
      key: Key(file['id']),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.download_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Download action
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đang tải xuống ${file['name']}...'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return false;
        }
        // Delete confirmation
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text('Xóa file', style: theme.textTheme.titleLarge),
            content: Text('Bạn có chắc muốn xóa "${file['name']}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Hủy',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Xóa',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa ${file['name']}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isDark ? colorScheme.surfaceContainerHighest : Colors.white,
              isDark ? colorScheme.surface : const Color(0xFFFAFBFC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: (file['color'] as Color).withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (file['color'] as Color).withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: (file['color'] as Color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (file['color'] as Color).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                file['icon'],
                color: file['color'],
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file['name'],
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (file['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          file['type'],
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: file['color'],
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${file['size']} • ${file['date']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}