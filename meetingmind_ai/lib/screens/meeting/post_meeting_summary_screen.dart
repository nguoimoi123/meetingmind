import 'package:flutter/material.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';
import 'package:meetingmind_ai/services/summary_service.dart';
import 'package:meetingmind_ai/models/meeting_summary.dart';

class PostMeetingSummaryScreen extends StatefulWidget {
  final String meetingSid;
  final List<TranscriptMessage> transcripts;
  const PostMeetingSummaryScreen(
      {super.key, required this.transcripts, required this.meetingSid});

  @override
  State<PostMeetingSummaryScreen> createState() =>
      _PostMeetingSummaryScreenState();
}

class _PostMeetingSummaryScreenState extends State<PostMeetingSummaryScreen> {
  MeetingSummary? summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await SummaryService.summarize(widget.meetingSid);
    setState(() => summary = result);
  }

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Meeting Summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile('Summary', summary!.summary),
          _tile('Action Items', summary!.actionItems.join('\n')),
          _tile('Key Decisions', summary!.keyDecisions.join('\n')),
          _tile('Full Transcript', summary!.fullTranscript),
        ],
      ),
    );
  }

  Widget _tile(String title, String content) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(content),
        )
      ],
    );
  }
}
