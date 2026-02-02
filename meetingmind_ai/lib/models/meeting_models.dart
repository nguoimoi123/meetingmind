class Meeting {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final String time;
  final String status; // 'Completed', 'In Progress'
  final List<String> participants;
  final List<String> tags;
  final String? contextFile; // Path to uploaded context file
  final String? contextText; // Extracted text from context file

  Meeting({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.status,
    required this.time,
    required this.participants,
    this.tags = const [],
    this.contextFile,
    this.contextText,
  });
}

class TranscriptMessage {
  final String speaker;
  final String text;
  final bool isFinal;

  TranscriptMessage({
    required this.speaker,
    required this.text,
    required this.isFinal,
  });

  factory TranscriptMessage.fromJson(Map<String, dynamic> json) {
    return TranscriptMessage(
      speaker: json['speaker'] ?? 'Unknown',
      text: json['text'] ?? '',
      isFinal: json['is_final'] ?? false,
    );
  }
}
