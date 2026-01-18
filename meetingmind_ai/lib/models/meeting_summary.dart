class MeetingSummary {
  final String summary;
  final List<String> actionItems;
  final List<String> keyDecisions;
  final String fullTranscript;

  MeetingSummary({
    required this.summary,
    required this.actionItems,
    required this.keyDecisions,
    required this.fullTranscript,
  });

  factory MeetingSummary.fromJson(Map<String, dynamic> json) {
    return MeetingSummary(
      summary: json['summary'] ?? '',
      actionItems: List<String>.from(json['action_items'] ?? []),
      keyDecisions: List<String>.from(json['key_decisions'] ?? []),
      fullTranscript: json['full_transcript'] ?? '',
    );
  }
}
