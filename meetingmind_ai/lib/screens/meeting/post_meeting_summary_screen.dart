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

  // --- BẢNG MÀU SẮC VIBRANT (Vibrant Palette) ---
  static const Color _vibrantBlue = Color(0xFF2962FF);
  static const Color _vibrantGreen = Color(0xFF00C853);
  static const Color _vibrantOrange = Color(0xFFFF6D00);
  static const Color _vibrantPurple = Color(0xFF6200EA);

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
        SnackBar(
          content: const Text("Đã lưu thành công!"),
          backgroundColor: _vibrantGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Processing', style: theme.textTheme.titleLarge),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                  color: _vibrantBlue, strokeWidth: 3),
            ),
            SizedBox(height: 16),
            Text("MeetingMind AI đang phân tích cuộc họp...",
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
          ],
        )),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Summary',
            style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Về Dashboard',
            icon: const Icon(Icons.home_rounded),
            onPressed: () => context.go('/app/home'),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER CARD ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _vibrantBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _vibrantBlue.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _vibrantBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        size: 28, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Meeting Summary',
                            style: theme.textTheme.titleLarge?.copyWith(
                                color: _vibrantBlue,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Powered by MeetingMind AI',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- SUMMARY SECTION (Blue Theme) ---
            Text('Tóm tắt nội dung',
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            _buildContentCard(
              content: summary!.summary,
              icon: Icons.summarize_rounded,
              iconColor: _vibrantBlue,
              bgColor: _vibrantBlue.withOpacity(0.05),
            ),

            const SizedBox(height: 24),

            // --- ACTION ITEMS SECTION (Green Theme) ---
            Text('Việc cần làm',
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            _buildActionListCard(
              items: summary!.actionItems,
              icon: Icons.check_circle_rounded,
              iconColor: _vibrantGreen,
              bgColor: _vibrantGreen.withOpacity(0.05),
            ),

            const SizedBox(height: 24),

            // --- KEY DECISIONS SECTION (Orange Theme) ---
            Text('Quyết định quan trọng',
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            _buildActionListCard(
              items: summary!.keyDecisions,
              icon: Icons.lightbulb_rounded,
              iconColor: _vibrantOrange,
              bgColor: _vibrantOrange.withOpacity(0.05),
            ),

            const SizedBox(height: 24),

            // --- TRANSCRIPT SECTION ---
            Text('Bản chép đầy đủ',
                style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.all(20),
                  childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.description_rounded,
                            size: 20, color: colorScheme.onSurface),
                      ),
                      const SizedBox(width: 12),
                      Text("Xem toàn bộ văn bản",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  children: [
                    Text(summary!.fullTranscript,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: colorScheme.onSurface.withOpacity(0.8))),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- NÚT CHAT AI (Gradient Vibrant) ---
            Center(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_vibrantPurple, _vibrantBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: _vibrantPurple.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _navigateToChat,
                  icon: const Icon(Icons.question_answer_rounded, size: 24),
                  label: const Text('Hỏi đáp AI về cuộc họp',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FloatingActionButton.extended(
            onPressed: _isSaving ? null : _saveToDatabase,
            elevation: 2,
            backgroundColor: colorScheme.primary,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.check_rounded),
            label: Text(_isSaving ? "Đang lưu..." : "Xác nhận lưu lại",
                style: const TextStyle(fontWeight: FontWeight.w600)),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
      ),
    );
  }

  // Widget thẻ nội dung với màu sắc theo chủ đề
  Widget _buildContentCard({
    required String content,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
              child: Text(content,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(height: 1.5, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // Widget danh sách hành động
  Widget _buildActionListCard({
    required List<String> items,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withOpacity(0.1)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (ctx, index) => Divider(
            height: 24, color: theme.colorScheme.onSurface.withOpacity(0.1)),
        itemBuilder: (ctx, index) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  items[index],
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withOpacity(0.9)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
