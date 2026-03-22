import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/config/plan_limits.dart';
import 'package:meetingmind_ai/widgets/upgrade_dialog.dart';
import 'package:meetingmind_ai/services/file_service.dart';

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
    final isDark = theme.brightness == Brightness.dark;
    
    return Dismissible(
      key: Key(file.id),
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
        padding: const EdgeInsets.all(18.0),
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
            color: const Color(0xFF6366F1).withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.05),
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
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.description_rounded,
                color: Colors.white,
                size: 26,
              ),
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
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: _isUploading || !canUpload ? null : _pickAndUploadFile,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          gradient: canUpload
              ? LinearGradient(
                  colors: [
                    isDark
                        ? colorScheme.surfaceContainerHighest
                        : Colors.white,
                    isDark
                        ? colorScheme.surface
                        : const Color(0xFFFAFBFC),
                  ],
                )
              : null,
          color: canUpload ? null : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: canUpload
                ? const Color(0xFF6366F1).withOpacity(0.3)
                : colorScheme.outline.withOpacity(0.2),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: canUpload
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _isUploading
              ? Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: canUpload
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF6366F1),
                                  Color(0xFF8B5CF6),
                                ],
                              )
                            : null,
                        color: canUpload ? null : colorScheme.outline.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: canUpload
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.cloud_upload_rounded,
                        color: canUpload ? Colors.white : colorScheme.onSurface.withOpacity(0.4),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      canUpload
                          ? 'Add New Document'
                          : 'Limit reached for $_plan',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: canUpload
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withOpacity(0.5),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
