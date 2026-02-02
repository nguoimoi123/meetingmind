import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:docx_to_text/docx_to_text.dart';

// Import services và providers từ project của bạn
import 'package:meetingmind_ai/services/file_service.dart';
import 'package:meetingmind_ai/services/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/config/plan_limits.dart';
import 'package:meetingmind_ai/widgets/upgrade_dialog.dart';
import 'package:meetingmind_ai/services/usage_service.dart';

class FileItem {
  String id;
  String name;
  int size;
  String uploadDate;
  String fileType;

  FileItem({
    required this.id,
    required this.name,
    required this.size,
    required this.uploadDate,
    required this.fileType,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'],
      name: json['filename'],
      size: json['size'],
      uploadDate: json['uploaded_at'],
      fileType: json['file_type'] ?? 'txt',
    );
  }
}

// ======================= MAIN SCREEN =========================

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
    // Sử dụng FileService thay vì gọi http trực tiếp
    final data = await FileService.getFolder(widget.folderId);
    setState(() => _folderName = data['folder_name']);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 2,
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
        tabs: const [Tab(text: 'Sources'), Tab(text: 'Ask AI')],
      ),
    );
  }
}

// ======================= TAB SOURCES (Giao diện mới + Logic Service) =========================

class SourcesTab extends StatefulWidget {
  final String folderId;
  const SourcesTab({super.key, required this.folderId});

  @override
  State<SourcesTab> createState() => _SourcesTabState();
}

class _SourcesTabState extends State<SourcesTab> {
  bool _isLoading = true;
  bool _isUploading = false;
  List<FileItem> _files = [];
  late String _userId;
  String _plan = 'free';
  Map<String, dynamic> _limits = {};

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _userId = auth.userId!;
    _plan = auth.plan;
    _limits = auth.limits;
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    final data = await FileService.getFolder(widget.folderId);
    final List list = data['files'] ?? [];
    setState(() {
      _files = list.map((e) => FileItem.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  // Helper functions định dạng
  String getTimeAgo(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    Duration diff = DateTime.now().difference(dateTime);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  String formatFileSize(int sizeInBytes) {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1048576) {
      double sizeInKB = sizeInBytes / 1024;
      return '${sizeInKB.toStringAsFixed(1)} KB';
    }
    double sizeInMB = sizeInBytes / 1048576;
    return '${sizeInMB.toStringAsFixed(1)} MB';
  }

  // Logic đọc file (giống code gốc 1 nhưng được cải tổ)
  Future<String?> readFileContent(PlatformFile file) async {
    if (file.path == null) return null;
    final ext = file.extension?.toLowerCase();

    try {
      if (ext == 'docx') {
        final bytes = await File(file.path!).readAsBytes();
        return docxToText(bytes);
      } else if (ext == 'txt' || ext == 'md') {
        return await File(file.path!).readAsString(encoding: utf8);
      }
    } catch (e) {
      print('Error reading file: $e');
    }
    return null;
  }

  Future<void> _pickAndUploadFile() async {
    final limit = PlanLimits.filesPerFolderLimitFromLimits(_limits) ??
        PlanLimits.filesPerFolderLimit(_plan);
    if (limit != null && _files.length >= limit) {
      if (mounted) {
        await showUpgradeDialog(
          context,
          message: 'File limit reached for $_plan plan. Please upgrade.',
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx', 'txt', 'md'],
    );
    if (result == null) return;

    final file = result.files.single;

    // 1. Validate
    const allowedExtensions = ['docx', 'txt', 'md'];
    final ext = file.extension?.toLowerCase();
    if (ext == null || !allowedExtensions.contains(ext)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invalid file type'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    // 2. Đọc nội dung
    final content = await readFileContent(file);
    if (content == null || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Cannot read file or file is empty'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isUploading = true);

    // 3. Upload qua Service (Logic code 1)
    try {
      await FileService.uploadFile(
        userId: _userId,
        folderId: widget.folderId,
        file: file,
        content: content,
      );
      await _fetchFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload failed: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // Xử lý xóa file (Sử dụng FileService)
  Future<void> deleteFile(String fileId) async {
    try {
      await FileService.deleteFile(fileId);
      await _fetchFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Delete failed: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _downloadFile(FileItem file) async {
    try {
      final bytes = await FileService.downloadFile(file.id);
      final isMobile = Platform.isAndroid || Platform.isIOS;
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Lưu file',
        fileName: file.name,
        allowedExtensions: [file.fileType],
        bytes: isMobile ? bytes : null,
      );

      if (savePath != null && !isMobile) {
        final outFile = File(savePath);
        await outFile.writeAsBytes(bytes, flush: true);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              savePath != null ? 'Đã tải về: $savePath' : 'Đã lưu file',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tải file thất bại: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<bool> showDeleteConfirm(FileItem file) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete file', style: theme.textTheme.titleLarge),
        content: Text('Are you sure you want to delete "${file.name}"?'),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Center(
          child: CircularProgressIndicator(color: colorScheme.primary));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
      itemCount: _files.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _files.length) {
          return _buildUploadCard(theme, colorScheme);
        }
        return _buildFileCard(theme, colorScheme, _files[index]);
      },
    );
  }

  Widget _buildFileCard(
      ThemeData theme, ColorScheme colorScheme, FileItem file) {
    return Dismissible(
      key: Key(file.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.green.shade500,
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
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _downloadFile(file);
          return false;
        }
        return await showDeleteConfirm(file);
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          deleteFile(file.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.description_rounded,
                  color: colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${formatFileSize(file.size)} • ${getTimeAgo(file.uploadDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(ThemeData theme, ColorScheme colorScheme) {
    final limit = PlanLimits.filesPerFolderLimitFromLimits(_limits) ??
        PlanLimits.filesPerFolderLimit(_plan);
    final canUpload = limit == null || _files.length < limit;

    return InkWell(
      onTap: _isUploading || !canUpload ? null : _pickAndUploadFile,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: canUpload
              ? colorScheme.surface
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Center(
          child: _isUploading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: colorScheme.primary),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_rounded,
                        color: colorScheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      canUpload
                          ? 'Add New Document'
                          : 'Limit reached for $_plan',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ======================= TAB ASK AI (Giao diện mới + Logic Service) =========================

class AskAITab extends StatefulWidget {
  final String folderId;
  const AskAITab({super.key, required this.folderId});

  @override
  State<AskAITab> createState() => _AskAITabState();
}

class _AskAITabState extends State<AskAITab> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isLoadingFiles = true;
  bool _isLoadingUsage = true;
  List<FileItem> _files = [];
  final Set<String> _selectedFileIds = {};
  String _plan = 'free';
  String _userId = '';
  Map<String, dynamic> _limits = {};
  int? _qaRemaining;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _plan = auth.plan;
    _userId = auth.userId ?? '';
    _limits = auth.limits;
    _fetchFiles();
    _fetchUsage();
  }

  Future<void> _fetchUsage() async {
    if (_userId.isEmpty) return;
    setState(() => _isLoadingUsage = true);
    try {
      final usage = await UsageService.getUsage(userId: _userId);
      if (mounted) {
        setState(() {
          _qaRemaining = usage['qa_remaining'] as int?;
          _isLoadingUsage = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUsage = false);
    }
  }

  Future<void> _fetchFiles() async {
    final data = await FileService.getFolder(widget.folderId);
    final List list = data['files'] ?? [];
    if (mounted) {
      setState(() {
        _files = list.map((e) => FileItem.fromJson(e)).toList();
        _isLoadingFiles = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(dynamic auth) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final limit =
        PlanLimits.qaLimitFromLimits(_limits) ?? PlanLimits.qaLimit(_plan);
    if (limit != null && _qaRemaining != null) {
      if (_qaRemaining! <= 0) {
        if (mounted) {
          await showUpgradeDialog(
            context,
            message: 'Q&A limit reached for $_plan plan. Please upgrade.',
          );
        }
        return;
      }
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _textController.clear();
    });
    _scrollToBottom();

    // Sử dụng ChatService từ code gốc 1
    try {
      final answer = await ChatService.ask(
        folderId: widget.folderId,
        question: text,
        userId: auth.userId!,
        fileIds: _selectedFileIds.isEmpty ? null : _selectedFileIds.toList(),
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: answer, isUser: false));
          _isLoading = false;
        });
      }
      await _fetchUsage();
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: 'Error: $e', isUser: false));
          _isLoading = false;
        });
      }
      await _fetchUsage();
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        if (_isLoadingUsage)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Loading usage...', style: theme.textTheme.bodySmall),
              ],
            ),
          )
        else if (_qaRemaining != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Q&A remaining: $_qaRemaining',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        if (_isLoadingFiles)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Đang tải danh sách file...',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          )
        else
          _buildFileSelector(theme, colorScheme),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(24.0),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (_isLoading && index == _messages.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildTypingIndicator(colorScheme),
                  ),
                );
              }

              final message = _messages[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildMessage(
                    theme, colorScheme, message.text, message.isUser),
              );
            },
          ),
        ),
        _buildInputArea(theme, colorScheme),
      ],
    );
  }

  Widget _buildFileSelector(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn file để hỏi AI',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Tất cả'),
                selected: _selectedFileIds.isEmpty,
                onSelected: (_) {
                  setState(() => _selectedFileIds.clear());
                },
                selectedColor: colorScheme.primary.withOpacity(0.15),
              ),
              ..._files.map((file) {
                final selected = _selectedFileIds.contains(file.id);
                return FilterChip(
                  label: Text(file.name,
                      overflow: TextOverflow.ellipsis, maxLines: 1),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedFileIds.add(file.id);
                      } else {
                        _selectedFileIds.remove(file.id);
                      }
                    });
                  },
                  selectedColor: colorScheme.primary.withOpacity(0.15),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMessage(
      ThemeData theme, ColorScheme colorScheme, String text, bool isUser) {
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              gradient: isUser
                  ? LinearGradient(
                      colors: [colorScheme.secondary, colorScheme.primary],
                    )
                  : null,
              color: isUser ? null : colorScheme.surface,
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomLeft: isUser
                    ? const Radius.circular(20)
                    : const Radius.circular(4),
                bottomRight: isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
              border: isUser
                  ? null
                  : Border.all(color: colorScheme.outline.withOpacity(0.1)),
            ),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isUser ? colorScheme.onSecondary : colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage:
                const NetworkImage('https://i.pravatar.cc/150?img=12'),
          ),
        ],
      ],
    );
  }

  Widget _buildInputArea(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colorScheme.outline.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.add_circle_outline_rounded,
                color: colorScheme.onSurface.withOpacity(0.6)),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: (_) => _sendMessage(
                  Provider.of<AuthProvider>(context, listen: false)),
              decoration: InputDecoration(
                hintText: 'Ask AI anything...',
                hintStyle:
                    TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              style: theme.textTheme.bodyLarge,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading
                  ? null
                  : () => _sendMessage(
                      Provider.of<AuthProvider>(context, listen: false)),
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [colorScheme.secondary, colorScheme.primary]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: colorScheme.onSecondary),
                      )
                    : Icon(Icons.arrow_upward_rounded,
                        color: colorScheme.onSecondary, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}
