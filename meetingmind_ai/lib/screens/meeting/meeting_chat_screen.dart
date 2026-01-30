import 'package:flutter/material.dart';
import 'package:meetingmind_ai/services/chat_meeting_service.dart';

class MeetingChatScreen extends StatefulWidget {
  final String meetingSid;
  const MeetingChatScreen({super.key, required this.meetingSid});

  @override
  State<MeetingChatScreen> createState() => _MeetingChatScreenState();
}

class _MeetingChatScreenState extends State<MeetingChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // Màu sắc nổi bật cho AI và Nút gửi (Vibrant Blue)
  static const Color _aiAccentColor = Color(0xFF2962FF);

  void _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    String userQuery = _textController.text;
    setState(() {
      _messages.add({"role": "user", "content": userQuery});
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      String aiResponse =
          await _chatService.askAboutMeeting(widget.meetingSid, userQuery);

      if (mounted) {
        setState(() {
          _messages.add({"role": "ai", "content": aiResponse});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Lỗi chat: $e"),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
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
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Meeting Mind AI',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // --- DANH SÁCH TIN NHẮN ---
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Hiển thị trạng thái đang nhập liệu
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator(isDarkMode);
                }

                final msg = _messages[index];
                bool isUser = msg['role'] == 'user';
                return _buildMessageBubble(msg, isUser, isDarkMode, theme);
              },
            ),
          ),

          // --- KHUNG NHẬP LIỆU MỚI ---
          _buildInputArea(isDarkMode),
        ],
      ),
    );
  }

  // Widget hiển thị bong bóng chat
  Widget _buildMessageBubble(
      Map<String, String> msg, bool isUser, bool isDarkMode, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Avatar AI
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _aiAccentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  color: _aiAccentColor, size: 20),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.black // Nền đen cho User
                    : (isDarkMode
                        ? theme.colorScheme.surfaceContainerHighest
                        : const Color(0xFFF5F5F5)), // Nền xám cho AI
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Text(
                msg['content'] ?? '',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isUser ? Colors.white : theme.colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            // Avatar User (Chữ viết tắt hoặc Icon)
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.person,
                  size: 16, color: theme.colorScheme.onPrimaryContainer),
            ),
          ],
        ],
      ),
    );
  }

  // Widget hiệu ứng đang nhập liệu
  Widget _buildTypingIndicator(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 12),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _aiAccentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_rounded,
                color: _aiAccentColor, size: 20),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Widget khung nhập liệu
  Widget _buildInputArea(bool isDarkMode) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
          16, 16, 16, 24), // Padding bottom lớn hơn cho iPhone
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color:
                isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDarkMode ? Colors.grey[800]! : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: 5,
                  minLines: 1,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Hỏi AI về nội dung cuộc họp...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              // Nút gửi màu sống động
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: _aiAccentColor, // Màu xanh rực rỡ
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_upward_rounded,
                      color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
