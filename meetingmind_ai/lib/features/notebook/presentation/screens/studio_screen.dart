import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/services/studio_service.dart';
import 'package:meetingmind_ai/services/mindmap_service.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/features/notebook/presentation/widgets/studio/audio_summary_card.dart';
import 'package:meetingmind_ai/features/notebook/presentation/widgets/studio/mindmap_card.dart';
import 'package:meetingmind_ai/features/notebook/presentation/widgets/studio/quick_summary_card.dart';
import 'package:meetingmind_ai/features/notebook/presentation/widgets/studio/flashcards_card.dart';
import 'package:meetingmind_ai/features/notebook/presentation/widgets/studio/mindmap_screen.dart';

class StudioTab extends StatefulWidget {
  final String folderId;
  const StudioTab({super.key, required this.folderId});

  @override
  State<StudioTab> createState() => _StudioTabState();
}

class _StudioTabState extends State<StudioTab> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isGenerating = false;
  bool _isGeneratingMindmap = false;
  String? _currentAudioUrl;
  bool _isPlaying = false;
  String? _playingFileId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    try {
      final results = await StudioService.getResultsByFolder(widget.folderId);
      
      print('📊 Loaded ${results.length} results');
      
      setState(() {
        _generatedFiles = results.map((result) {
          print('📝 Processing result: ${result['name']} (${result['type']})');
          
          // Lấy graph data từ metadata nếu là mindmap
          Map<String, dynamic>? graphData;
          if (result['type'] == 'mindmap' && result['metadata'] != null) {
            final metadata = result['metadata'];
            print('🔍 Metadata type: ${metadata.runtimeType}');
            print('🔍 Metadata content: $metadata');
            
            if (metadata is Map && metadata['graph_data'] != null) {
              graphData = Map<String, dynamic>.from(metadata['graph_data']);
              print('✅ Graph data extracted: ${graphData.keys}');
            } else {
              print('⚠️ No graph_data in metadata');
            }
          }
          
          return {
            'id': result['id'] ?? '',
            'name': result['name'] ?? 'Unknown',
            'type': _getTypeDisplayName(result['type']),
            'icon': _getIconForType(result['type']),
            'size': '', // Có thể tính từ result['size']
            'date': _formatDate(result['created_at']),
            'color': _getColorForType(result['type']),
            'audioUrl': result['type'] == 'audio_summary' ? result['url'] : null,
            'graphData': graphData,
            'resultId': result['id'],
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getTypeDisplayName(String? type) {
    switch (type) {
      case 'audio_summary':
        return 'Audio';
      case 'mindmap':
        return 'Sơ đồ tư duy';
      case 'quick_summary':
        return 'Tóm tắt';
      case 'flashcards':
        return 'Flashcards';
      default:
        return 'Unknown';
    }
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'audio_summary':
        return Icons.audiotrack_rounded;
      case 'mindmap':
        return Icons.account_tree_rounded;
      case 'quick_summary':
        return Icons.picture_as_pdf_rounded;
      case 'flashcards':
        return Icons.style_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'audio_summary':
        return const Color(0xFF7F00FF);
      case 'mindmap':
        return const Color(0xFF00C6FF);
      case 'quick_summary':
        return const Color(0xFF6366F1);
      case 'flashcards':
        return const Color(0xFFF7971E);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'Vừa xong';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} phút trước';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} giờ trước';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} ngày trước';
      } else {
        return '${(diff.inDays / 7).floor()} tuần trước';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _generateAndPlayAudio() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Vui lòng đăng nhập để sử dụng tính năng này'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isGenerating = true;
    });

    try {
      final result = await StudioService.generateAudio(widget.folderId, userId);
      final audioUrl = result['audio_url'] as String?;
      final resultId = result['result_id'] as String?;

      if (audioUrl != null && audioUrl.isNotEmpty) {
        // Thêm file audio vào danh sách kết quả
        final newAudioFile = {
          'id': 'audio_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Tóm tắt âm thanh.mp3',
          'type': 'Audio',
          'icon': Icons.audiotrack_rounded,
          'size': '',
          'date': 'Vừa xong',
          'color': const Color(0xFF7F00FF),
          'audioUrl': audioUrl,
          'resultId': resultId,
        };

        setState(() {
          _generatedFiles.insert(0, newAudioFile);
          _currentAudioUrl = audioUrl;
          _isGenerating = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Audio đã được tạo! Nhấn vào thẻ để phát.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Không nhận được URL audio');
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      
      if (mounted) {
        // Kiểm tra nếu là lỗi 404 (không có content)
        if (e.toString().contains('No content found')) {
          final colorScheme = Theme.of(context).colorScheme;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Chưa có tài liệu'),
                  ),
                ],
              ),
              content: const Text(
                'Vui lòng tải tài liệu lên trước khi sử dụng tính năng này.',
                style: TextStyle(fontSize: 15),
              ),
              actions: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Đã hiểu',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Các lỗi khác hiển thị snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _playAudioFile(Map<String, dynamic> file) async {
    final audioUrl = file['audioUrl'] as String?;
    final fileId = file['id'] as String;

    if (audioUrl == null) return;

    // Nếu đang phát file này, thì pause
    if (_isPlaying && _playingFileId == fileId) {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
      return;
    }

    // Nếu đang phát file khác, dừng và phát file mới
    if (_isPlaying && _playingFileId != fileId) {
      await _audioPlayer.stop();
    }

    // Phát audio
    await _audioPlayer.play(UrlSource(audioUrl));
    setState(() {
      _isPlaying = true;
      _playingFileId = fileId;
    });

    // Lắng nghe khi audio kết thúc
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _playingFileId = null;
      });
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎵 Đang phát ${file['name']}...'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  Future<void> _generateMindmap() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userId;
    
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Vui lòng đăng nhập để sử dụng tính năng này'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isGeneratingMindmap = true;
    });

    try {
      final result = await MindmapService.generateMindmap(
        widget.folderId,
        userId,
        name: 'Sơ đồ tư duy ${DateTime.now().day}/${DateTime.now().month}',
      );
      
      setState(() {
        _isGeneratingMindmap = false;
      });

      if (result['success'] == true && mounted) {
        final graphData = result['graph'] as Map<String, dynamic>;
        final resultId = result['result_id'] as String;
        
        // Thêm vào danh sách results
        final newMindmapFile = {
          'id': 'mindmap_${DateTime.now().millisecondsSinceEpoch}',
          'name': result['name'] ?? 'Sơ đồ tư duy',
          'type': 'Sơ đồ tư duy',
          'icon': Icons.account_tree_rounded,
          'size': '',
          'date': 'Vừa xong',
          'color': const Color(0xFF00C6FF),
          'resultId': resultId,
          'graphData': graphData,
        };

        setState(() {
          _generatedFiles.insert(0, newMindmapFile);
        });
        
        // Navigate to mindmap screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MindmapScreen(
              graphData: graphData,
              title: result['name'] ?? 'Sơ đồ tư duy',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGeneratingMindmap = false;
      });
      
      if (mounted) {
        if (e.toString().contains('No content found')) {
          final colorScheme = Theme.of(context).colorScheme;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    color: colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Chưa có tài liệu'),
                  ),
                ],
              ),
              content: const Text(
                'Vui lòng tải tài liệu lên trước khi sử dụng tính năng này.',
                style: TextStyle(fontSize: 15),
              ),
              actions: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Đã hiểu',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }



  // Dữ liệu file kết quả (có thể thay đổi)
  List<Map<String, dynamic>> _generatedFiles = [];

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
              delegate: SliverChildListDelegate([
                AudioSummaryCard(
                  isGenerating: _isGenerating,
                  onTap: _generateAndPlayAudio,
                ),
                MindmapCard(
                  isGenerating: _isGeneratingMindmap,
                  onTap: _generateMindmap,
                ),
                QuickSummaryCard(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mở tính năng: Tóm tắt nhanh')),
                    );
                  },
                ),
                FlashcardsCard(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mở tính năng: Flashcards')),
                    );
                  },
                ),
              ]),
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
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          final resultId = file['resultId'];
          if (resultId != null) {
            try {
              await StudioService.deleteResult(resultId);
              setState(() {
                _generatedFiles.removeWhere((f) => f['id'] == file['id']);
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa ${file['name']}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi khi xóa: ${e.toString()}'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                  ),
                );
              }
              // Reload lại dữ liệu
              _loadResults();
            }
          } else {
            setState(() {
              _generatedFiles.removeWhere((f) => f['id'] == file['id']);
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa ${file['name']}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      },
      child: InkWell(
        onTap: () {
          final audioUrl = file['audioUrl'];
          final graphData = file['graphData'];
          
          print('🔍 File tapped: ${file['name']}');
          print('🔍 Has audioUrl: ${audioUrl != null}');
          print('🔍 Has graphData: ${graphData != null}');
          print('🔍 GraphData content: $graphData');
          
          if (audioUrl != null) {
            // Nếu có audioUrl, phát audio
            _playAudioFile(file);
          } else if (graphData != null) {
            // Nếu có graphData, mở màn hình mindmap
            print('✅ Opening mindmap screen...');
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MindmapScreen(
                  graphData: graphData as Map<String, dynamic>,
                  title: file['name'],
                ),
              ),
            );
          } else {
            // Các file khác
            print('⚠️ No action for this file type');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Mở file: ${file['name']}'),
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
            // Hiển thị icon play/pause nếu là file audio
            if (file['audioUrl'] != null)
              Icon(
                _isPlaying && _playingFileId == file['id']
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_filled_rounded,
                color: file['color'],
                size: 28,
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                size: 24,
              ),
          ],
        ),
        ),
      ),
    );
  }
}
