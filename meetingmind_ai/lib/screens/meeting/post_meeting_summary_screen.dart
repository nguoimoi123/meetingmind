import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter để điều hướng
import 'package:meetingmind_ai/models/meeting_models.dart';
import 'package:meetingmind_ai/services/summary_service.dart';
import 'package:meetingmind_ai/models/meeting_summary.dart';
import 'package:meetingmind_ai/screens/meeting/meeting_chat_screen.dart'; // Import màn hình Chat

class PostMeetingSummaryScreen extends StatefulWidget {
  final String meetingSid;
  const PostMeetingSummaryScreen({super.key, required this.meetingSid});

  @override
  State<PostMeetingSummaryScreen> createState() =>
      _PostMeetingSummaryScreenState();
}

class _PostMeetingSummaryScreenState extends State<PostMeetingSummaryScreen> {
  MeetingSummary? summary;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await SummaryService.summarize(widget.meetingSid);
    setState(() => summary = result);
  }

  Future<void> _saveToDatabase() async {
    setState(() => _isSaving = true);

    // API này thực tế đã lưu khi summarize_sid được gọi
    // Hàm này chủ yếu để tạo hiệu ứng UI "Lưu lại"
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Đã lưu thành công! Đang quay về trang chủ..."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() => _isSaving = false);

      // Tự động quay lại Dashboard sau 1 giây
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.pop(); // Quay lại màn hình trước đó (Dashboard)
        }
      });
    }
  }

  void _navigateToChat() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                MeetingChatScreen(meetingSid: widget.meetingSid)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (summary == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Meeting Summary')),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("AI đang tổng kết cuộc họp...")
          ],
        )),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Summary'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // Nút quay lại mặc định
        ),
        actions: [
          // Nút Home để quay về Dashboard trực tiếp
          IconButton(
            tooltip: 'Về Dashboard',
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/app/home'),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Icon(Icons.insights_rounded,
                        size: 40, color: colorScheme.onPrimaryContainer),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tóm tắt cuộc họp',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Được tạo bởi MeetingMind AI',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer
                                      .withOpacity(0.8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Summary Section
            Text('Tóm tắt',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _buildSectionCard(summary!.summary, Icons.summarize,
                colorScheme.secondaryContainer),

            SizedBox(height: 24),

            // Action Items Section
            Text('Việc cần làm (Action Items)',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _buildListCard(summary!.actionItems, Icons.check_circle_outline,
                colorScheme.tertiaryContainer),

            SizedBox(height: 24),

            // Key Decisions Section
            Text('Quyết định quan trọng',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _buildListCard(summary!.keyDecisions, Icons.lightbulb_outline,
                colorScheme.primaryContainer),

            SizedBox(height: 24),

            // Transcript Section
            Text('Bản chép đầy đủ',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                tilePadding: EdgeInsets.all(16),
                childrenPadding: EdgeInsets.all(16),
                title: Text("Xem toàn bộ văn bản",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Text(summary!.fullTranscript,
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            ),

            SizedBox(height: 16),

            // --- NÚT CHAT RAG (MỚI) ---
            Center(
              child: ElevatedButton.icon(
                onPressed: _navigateToChat,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Hỏi đáp thông minh về cuộc họp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                  elevation: 2,
                ),
              ),
            ),

            SizedBox(height: 90), // Space for bottom button
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveToDatabase,
            icon: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(Icons.save_rounded),
            label: Text(_isSaving ? "Đang lưu..." : "Lưu và Về Dashboard"),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              elevation: 4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String content, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 12),
            Expanded(
                child: Text(content,
                    style: Theme.of(context).textTheme.bodyLarge)),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(List<String> items, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (ctx, index) => Divider(height: 1, indent: 48),
        itemBuilder: (ctx, index) {
          return ListTile(
            leading: Icon(icon,
                size: 20, color: Theme.of(context).colorScheme.secondary),
            title: Text(items[index]),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          );
        },
      ),
    );
  }
}
