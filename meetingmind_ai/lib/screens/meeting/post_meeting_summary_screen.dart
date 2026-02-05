import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter để điều hướng
import 'package:meetingmind_ai/models/meeting_models.dart';
import 'package:meetingmind_ai/services/summary_service.dart';
import 'package:meetingmind_ai/models/meeting_summary.dart';
import 'package:meetingmind_ai/screens/meeting/meeting_chat_screen.dart'; // Import màn hình Chat
import 'package:meetingmind_ai/services/report_export_service.dart';
import 'package:meetingmind_ai/services/report_service.dart';
import 'package:meetingmind_ai/services/notebook_list_service.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/services/meeting_management_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
  bool _isExporting = false;
  bool _isCreatingTasks = false;
  bool _isLoadingMeta = false;
  bool _isSavingSpeakers = false;
  List<String> _tags = [];
  Map<String, String> _speakerNames = {};
  final Map<String, TextEditingController> _speakerControllers = {};

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
    final userId = context.read<AuthProvider>().userId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Bạn cần đăng nhập');
    }
    final result = await SummaryService.summarize(
      widget.meetingSid,
      userId: userId,
    );
    setState(() => summary = result);
    await _loadMeetingMeta();
  }

  @override
  void dispose() {
    for (final controller in _speakerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMeetingMeta() async {
    if (_isLoadingMeta) return;
    setState(() => _isLoadingMeta = true);
    try {
      final data = await MeetingManagementService.getMeetingDetail(
        sid: widget.meetingSid,
      );

      final tags = List<String>.from(data['tags'] ?? []);
      final speakerNames = Map<String, String>.from(
        (data['speaker_names'] ?? {}) as Map,
      );

      final speakerIds = _extractSpeakerIdsFromTranscript();
      final allSpeakerIds = {
        ...speakerIds,
        ...speakerNames.keys,
      };

      _speakerControllers.clear();
      for (final id in allSpeakerIds) {
        _speakerControllers[id] = TextEditingController(
          text: speakerNames[id] ?? '',
        );
      }

      if (mounted) {
        setState(() {
          _tags = tags;
          _speakerNames = speakerNames;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải thông tin meeting: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingMeta = false);
    }
  }

  Set<String> _extractSpeakerIdsFromTranscript() {
    final transcript = summary?.fullTranscript ?? '';
    if (transcript.isEmpty) return {};

    final lines = transcript.split('\n');
    final speakers = <String>{};
    for (final line in lines) {
      final match = RegExp(r'^\s*([^:]{1,40})\s*:').firstMatch(line);
      if (match != null) {
        final speaker = match.group(1)?.trim();
        if (speaker != null && speaker.isNotEmpty) {
          speakers.add(speaker);
        }
      }
    }
    return speakers;
  }

  Future<void> _editTags() async {
    final controller = TextEditingController(text: _tags.join(', '));
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit tags'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'tag1, tag2, tag3',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final tags = controller.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              Navigator.pop(context, tags);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      final updated = await MeetingManagementService.updateMeetingTags(
        sid: widget.meetingSid,
        tags: result,
      );
      if (mounted) {
        setState(() => _tags = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tags updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update tags: $e')),
        );
      }
    }
  }

  Future<void> _saveSpeakerMapping() async {
    if (_isSavingSpeakers) return;
    setState(() => _isSavingSpeakers = true);

    try {
      final payload = <String, String>{};
      _speakerControllers.forEach((key, controller) {
        final value = controller.text.trim();
        if (value.isNotEmpty) {
          payload[key] = value;
        }
      });

      await MeetingManagementService.updateSpeakerMapping(
        sid: widget.meetingSid,
        speakerNames: payload,
      );

      if (mounted) {
        setState(() => _speakerNames = payload);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speaker mapping saved'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save speakers: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingSpeakers = false);
    }
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

  bool _hasScheduleHints() {
    if (summary == null) return false;
    final items = summary!.actionItems;
    if (items.isEmpty) return false;

    final scheduleRegex = RegExp(
      r'(\b\d{1,2}[:.]\d{2}\b|\b\d{1,2}\s*(am|pm)\b|\bng\.?\s*\d{1,2}\b|\bngày\b|\bthứ\b|\btuần\b|\btháng\b|\b\d{1,2}/\d{1,2}/\d{2,4}\b)',
      caseSensitive: false,
    );

    return items.any((item) => scheduleRegex.hasMatch(item));
  }

  Map<String, dynamic> _buildScheduleSuggestion() {
    final items = summary?.actionItems ?? [];
    final scheduleRegex = RegExp(
      r'(\b\d{1,2}[:.]\d{2}\b|\b\d{1,2}\s*(am|pm)\b|\bng\.?\s*\d{1,2}\b|\bngày\b|\bthứ\b|\btuần\b|\btháng\b|\b\d{1,2}/\d{1,2}/\d{2,4}\b)',
      caseSensitive: false,
    );

    final target = items.firstWhere(
      (item) => scheduleRegex.hasMatch(item),
      orElse: () => items.isNotEmpty ? items.first : '',
    );

    final title = target.isNotEmpty ? target : 'New Task';
    final locationMatch = RegExp(r'(?:tại|ở)\s+([^,.;]+)', caseSensitive: false)
        .firstMatch(target);
    final location = locationMatch?.group(1)?.trim();

    DateTime? date;
    DateTime? timeOnly;

    final dateMatch =
        RegExp(r'(\d{1,2})/(\d{1,2})/(\d{2,4})').firstMatch(target);
    if (dateMatch != null) {
      final day = int.parse(dateMatch.group(1)!);
      final month = int.parse(dateMatch.group(2)!);
      var year = int.parse(dateMatch.group(3)!);
      if (year < 100) year += 2000;
      date = DateTime(year, month, day);
    } else {
      final shortDateMatch =
          RegExp(r'ng\.?\s*(\d{1,2})/(\d{1,2})').firstMatch(target);
      if (shortDateMatch != null) {
        final day = int.parse(shortDateMatch.group(1)!);
        final month = int.parse(shortDateMatch.group(2)!);
        final now = DateTime.now();
        date = DateTime(now.year, month, day);
      }
    }

    final timeMatch = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(target);
    if (timeMatch != null) {
      final hour = int.parse(timeMatch.group(1)!);
      final minute = int.parse(timeMatch.group(2)!);
      final now = DateTime.now();
      timeOnly = DateTime(now.year, now.month, now.day, hour, minute);
    } else {
      final ampmMatch = RegExp(r'(\d{1,2})\s*(am|pm)', caseSensitive: false)
          .firstMatch(target);
      if (ampmMatch != null) {
        var hour = int.parse(ampmMatch.group(1)!);
        final meridian = ampmMatch.group(2)!.toLowerCase();
        if (meridian == 'pm' && hour < 12) hour += 12;
        if (meridian == 'am' && hour == 12) hour = 0;
        final now = DateTime.now();
        timeOnly = DateTime(now.year, now.month, now.day, hour, 0);
      }
    }

    DateTime? startTime;
    if (date != null && timeOnly != null) {
      startTime = DateTime(
        date.year,
        date.month,
        date.day,
        timeOnly.hour,
        timeOnly.minute,
      );
    }

    DateTime? endTime;
    if (startTime != null) {
      endTime = startTime.add(const Duration(hours: 1));
    }

    return {
      'title': title,
      'location': location,
      'startTime': startTime,
      'endTime': endTime,
    };
  }

  String _buildReportContent() {
    final buffer = StringBuffer();
    buffer.writeln('Meeting Report');
    buffer.writeln('');
    buffer.writeln('Summary:');
    buffer.writeln(summary?.summary ?? '');
    buffer.writeln('');
    buffer.writeln('Action Items:');
    if (summary?.actionItems.isNotEmpty == true) {
      for (final item in summary!.actionItems) {
        buffer.writeln('- $item');
      }
    } else {
      buffer.writeln('- None');
    }
    buffer.writeln('');
    buffer.writeln('Key Decisions:');
    if (summary?.keyDecisions.isNotEmpty == true) {
      for (final item in summary!.keyDecisions) {
        buffer.writeln('- $item');
      }
    } else {
      buffer.writeln('- None');
    }
    buffer.writeln('');
    buffer.writeln('Full Transcript:');
    buffer.writeln(summary?.fullTranscript ?? '');
    return buffer.toString();
  }

  Future<void> _exportReportDocx() async {
    if (summary == null || _isExporting) return;
    setState(() => _isExporting = true);

    final userId = context.read<AuthProvider>().userId!;
    final folders = await NotebookListService.fetchFolders(userId);
    final fileName =
        'Meeting_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.docx';

    if (folders.isNotEmpty) {
      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Text(
                  'Chọn notebook để lưu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: folders.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final folder = folders[index] as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(Icons.folder_rounded),
                        title: Text(folder['name'] ?? 'Untitled'),
                        subtitle: Text(
                          folder['description'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.pop(context, folder),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      );

      if (selected != null) {
        final content = _buildReportContent();
        try {
          await ReportExportService.uploadReportToNotebook(
            userId: userId,
            folderId: selected['id'] as String,
            filename: fileName,
            content: content,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Đã lưu báo cáo vào Notebook: ${selected['name']}'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Không thể lưu vào Notebook: $e'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isExporting = false);
        }
        return;
      }
    }

    try {
      final bytes = await ReportExportService.generateDocxBytes(
        title: 'Meeting Report',
        summary: summary!.summary,
        actionItems: summary!.actionItems,
        keyDecisions: summary!.keyDecisions,
        fullTranscript: summary!.fullTranscript,
      );

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Lưu báo cáo DOCX',
        fileName: fileName,
        allowedExtensions: ['docx'],
      );

      if (savePath != null) {
        final file = File(savePath);
        await file.writeAsBytes(bytes, flush: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tải về: $savePath'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xuất DOCX thất bại: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportReportPdf() async {
    if (summary == null || _isExporting) return;
    setState(() => _isExporting = true);

    try {
      final bytes = await ReportService.exportPdf(
        title: 'Meeting Report',
        summary: summary!.summary,
        actionItems: summary!.actionItems,
        keyDecisions: summary!.keyDecisions,
        fullTranscript: summary!.fullTranscript,
      );

      final fileName =
          'Meeting_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Lưu báo cáo PDF',
        fileName: fileName,
        allowedExtensions: ['pdf'],
      );

      if (savePath != null) {
        final file = File(savePath);
        await file.writeAsBytes(bytes, flush: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tải về: $savePath'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xuất PDF thất bại: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportReportMarkdown() async {
    if (summary == null || _isExporting) return;
    setState(() => _isExporting = true);

    try {
      final content = await ReportService.exportMarkdown(
        title: 'Meeting Report',
        summary: summary!.summary,
        actionItems: summary!.actionItems,
        keyDecisions: summary!.keyDecisions,
        fullTranscript: summary!.fullTranscript,
      );

      final fileName =
          'Meeting_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.md';
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Lưu báo cáo Markdown',
        fileName: fileName,
        allowedExtensions: ['md'],
      );

      if (savePath != null) {
        final file = File(savePath);
        await file.writeAsString(content, flush: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tải về: $savePath'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xuất Markdown thất bại: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _createTasksFromActionItems() async {
    if (summary == null || _isCreatingTasks) return;
    setState(() => _isCreatingTasks = true);

    try {
      final userId = context.read<AuthProvider>().userId;
      if (userId == null || userId.isEmpty) {
        throw Exception('Bạn cần đăng nhập');
      }

      final count = await MeetingManagementService.actionItemsToTasks(
        sid: widget.meetingSid,
        userId: userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tạo $count task từ action items'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tạo task: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingTasks = false);
    }
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

            // --- TAGS SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tags',
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface)),
                Row(
                  children: [
                    if (_isLoadingMeta)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    IconButton(
                      tooltip: 'Edit tags',
                      icon: const Icon(Icons.sell_outlined),
                      onPressed: _editTags,
                    ),
                  ],
                ),
              ],
            ),
            if (_tags.isEmpty)
              Text('No tags yet',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags
                    .map((t) => Chip(
                          label: Text(t),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),

            const SizedBox(height: 24),

            // --- SPEAKER MAPPING SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Speaker mapping',
                    style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface)),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadMeetingMeta,
                ),
              ],
            ),
            if (_speakerControllers.isEmpty)
              Text('No speakers detected yet',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)))
            else
              Column(
                children: _speakerControllers.entries.map((entry) {
                  final speakerId = entry.key;
                  final controller = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            speakerId,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              hintText: 'Name',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSavingSpeakers ? null : _saveSpeakerMapping,
                icon: _isSavingSpeakers
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Save mapping'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vibrantBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

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

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    _isCreatingTasks ? null : _createTasksFromActionItems,
                icon: _isCreatingTasks
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.playlist_add_check_rounded),
                label: const Text('Tạo task từ Action Items'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vibrantGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            if (_hasScheduleHints()) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final suggestion = _buildScheduleSuggestion();
                    context.push(
                      '/app/new_task',
                      extra: suggestion,
                    );
                  },
                  icon: const Icon(Icons.calendar_month_rounded),
                  label: const Text('Đặt lịch từ việc cần làm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _vibrantGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],

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

            // --- EXPORT DOCX BUTTON ---
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isExporting ? null : _exportReportDocx,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.description_outlined),
                    label: Text(
                      _isExporting ? 'Đang xuất...' : 'Xuất báo cáo DOCX',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isExporting ? null : _exportReportPdf,
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Xuất báo cáo PDF',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width - 40,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isExporting ? null : _exportReportMarkdown,
                    icon: const Icon(Icons.code_rounded),
                    label: const Text('Xuất báo cáo Markdown',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

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
