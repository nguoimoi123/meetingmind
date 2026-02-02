class PlanLimits {
  static const Map<String, Map<String, int?>> _limits = {
    'free': {
      'meeting_limit': 10,
      'meeting_duration_minutes': 30,
      'folder_limit': 5,
      'files_per_folder_limit': 5,
      'qa_limit': 30,
      'ai_agent': 0,
      'in_meeting_ai': 0,
    },
    'plus': {
      'meeting_limit': 50,
      'meeting_duration_minutes': 240,
      'folder_limit': 50,
      'files_per_folder_limit': 50,
      'qa_limit': 500,
      'ai_agent': 1,
      'in_meeting_ai': 0,
    },
    'premium': {
      'meeting_limit': null,
      'meeting_duration_minutes': null,
      'folder_limit': null,
      'files_per_folder_limit': null,
      'qa_limit': null,
      'ai_agent': 1,
      'in_meeting_ai': 1,
    },
  };

  static int? _get(String plan, String key) =>
      _limits[plan]?[key] ?? _limits['free']![key];

  static int? fromLimits(Map<String, dynamic>? limits, String key) {
    final value = limits?[key];
    if (value == null) return _limits['free']![key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return _limits['free']![key];
  }

  static int? meetingDurationMinutes(String plan) =>
      _get(plan, 'meeting_duration_minutes');

  static int? folderLimit(String plan) => _get(plan, 'folder_limit');

  static int? filesPerFolderLimit(String plan) =>
      _get(plan, 'files_per_folder_limit');

  static int? qaLimit(String plan) => _get(plan, 'qa_limit');

  static bool aiAgentAllowed(String plan) => (_get(plan, 'ai_agent') ?? 0) > 0;

  static bool inMeetingAiAllowed(String plan) =>
      (_get(plan, 'in_meeting_ai') ?? 0) > 0;

  static int? meetingDurationMinutesFromLimits(Map<String, dynamic>? limits) =>
      fromLimits(limits, 'meeting_duration_minutes');

  static int? folderLimitFromLimits(Map<String, dynamic>? limits) =>
      fromLimits(limits, 'folder_limit');

  static int? filesPerFolderLimitFromLimits(Map<String, dynamic>? limits) =>
      fromLimits(limits, 'files_per_folder_limit');

  static int? qaLimitFromLimits(Map<String, dynamic>? limits) =>
      fromLimits(limits, 'qa_limit');

  static bool aiAgentAllowedFromLimits(Map<String, dynamic>? limits) =>
      (fromLimits(limits, 'ai_agent') ?? 0) > 0;

  static bool inMeetingAiAllowedFromLimits(Map<String, dynamic>? limits) =>
      (fromLimits(limits, 'in_meeting_ai') ?? 0) > 0;
}
