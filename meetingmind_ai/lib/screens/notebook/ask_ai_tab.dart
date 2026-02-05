import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/config/plan_limits.dart';
import 'package:meetingmind_ai/widgets/upgrade_dialog.dart';
import 'package:meetingmind_ai/services/file_service.dart';
import 'package:meetingmind_ai/services/chat_service.dart';
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

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

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
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark
                ? colorScheme.surfaceContainerHighest
                : Colors.white,
            isDark
                ? colorScheme.surface
                : const Color(0xFFFAFBFC),
          ],
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
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isUser 
                  ? null 
                  : (isDark 
                      ? colorScheme.surfaceContainerHighest
                      : const Color(0xFFF8F9FA)),
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomLeft: isUser
                    ? const Radius.circular(20)
                    : const Radius.circular(6),
                bottomRight: isUser
                    ? const Radius.circular(6)
                    : const Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: isUser
                      ? const Color(0xFF6366F1).withOpacity(0.2)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: isUser
                  ? null
                  : Border.all(
                      color: colorScheme.outline.withOpacity(0.08),
                      width: 1,
                    ),
            ),
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isUser ? Colors.white : colorScheme.onSurface,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.transparent,
              child: Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputArea(ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDark 
                ? colorScheme.surfaceContainerHighest
                : Colors.white,
            isDark 
                ? colorScheme.surface
                : const Color(0xFFF8F9FA),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: (_) => _sendMessage(
                  Provider.of<AuthProvider>(context, listen: false)),
              decoration: InputDecoration(
                hintText: 'Ask AI anything...',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.4),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 16,
                ),
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading
                  ? null
                  : () => _sendMessage(
                      Provider.of<AuthProvider>(context, listen: false)),
              customBorder: const CircleBorder(),
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366F1),
                      const Color(0xFF8B5CF6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
