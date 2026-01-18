class Meeting {
  final String id;
  final String title;
  final String subtitle;
  final String date;
  final String status; // 'Completed', 'In Progress'

  Meeting({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.status,
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
