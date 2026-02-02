import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:meetingmind_ai/config/ai_keys.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/config/plan_limits.dart';
import 'package:meetingmind_ai/widgets/upgrade_dialog.dart';

class MeetingSetupScreen extends StatefulWidget {
  const MeetingSetupScreen({super.key});

  @override
  State<MeetingSetupScreen> createState() => _MeetingSetupScreenState();
}

class _MeetingSetupScreenState extends State<MeetingSetupScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _openAiKeyController = TextEditingController();
  File? _selectedFile;
  bool _isLoading = false;
  bool _aiAgentEnabled = false;

  static const Color _vibrantBlue = Color(0xFF2962FF);
  static const Color _vibrantGreen = Color(0xFF00C853);
  static const Color _warningOrange = Color(0xFFFF6D00);

  @override
  void initState() {
    super.initState();
    // Prefill OpenAI key from code config to avoid typing each time
    if (openAiApiKey.isNotEmpty && openAiApiKey != 'YOUR_OPENAI_API_KEY_HERE') {
      _openAiKeyController.text = openAiApiKey;
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path ?? '');
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text("File selected: ${_selectedFile!.path.split('/').last}"),
              backgroundColor: _vibrantGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error picking file: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startMeeting() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a meeting title"),
          backgroundColor: _warningOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final effectiveKey = _openAiKeyController.text.trim().isNotEmpty
        ? _openAiKeyController.text.trim()
        : openAiApiKey;

    if (_aiAgentEnabled && effectiveKey.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your OpenAI API key or disable AI Agent"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate upload delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // Pass meeting title and file path to in_meeting_screen
        context.push('/in_meeting', extra: {
          'title': _titleController.text.trim(),
          'filePath': _selectedFile?.path,
          'aiAgentEnabled': _aiAgentEnabled,
          'openAiKey': effectiveKey.trim().isEmpty ? null : effectiveKey.trim(),
        });
      }
    });
  }

  void _clearFile() {
    setState(() => _selectedFile = null);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _openAiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = context.watch<AuthProvider>();
    final plan = auth.plan;
    final canUseAiAgent = PlanLimits.aiAgentAllowedFromLimits(auth.limits) ||
        PlanLimits.aiAgentAllowed(plan);

    if (!canUseAiAgent && _aiAgentEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _aiAgentEnabled = false);
        }
      });
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'New Meeting',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: MEETING TITLE ---
            Text(
              'Meeting Title',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'e.g., Product Planning Q1 2026',
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                prefixIcon: Icon(Icons.title_rounded,
                    color: _vibrantBlue.withOpacity(0.6)),
              ),
              maxLines: 1,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 32),

            // --- SECTION 2: UPLOAD CONTEXT FILE ---
            Text(
              'Upload Context (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload documents or notes related to this meeting. AI will use this context to better understand and answer questions.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // --- FILE PICKER CARD ---
            if (_selectedFile == null)
              GestureDetector(
                onTap: _isLoading ? null : _pickFile,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  decoration: BoxDecoration(
                    color: _vibrantBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _vibrantBlue.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _vibrantBlue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.cloud_upload_outlined,
                            size: 40,
                            color: _vibrantBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tap to Upload',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _vibrantBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PDF, DOC, DOCX, TXT',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              // --- SELECTED FILE CARD ---
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _vibrantGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _vibrantGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _vibrantGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.insert_drive_file_rounded,
                        color: _vibrantGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile!.path.split('/').last,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(2)} MB',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoading ? null : _clearFile,
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.red,
                      iconSize: 20,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 40),

            if (canUseAiAgent) ...[
              // --- SECTION 3: AI AGENT ---
              Row(
                children: [
                  Switch(
                    value: _aiAgentEnabled,
                    activeColor: _vibrantBlue,
                    onChanged: (v) => setState(() => _aiAgentEnabled = v),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Agent (optional)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AI will answer questions using the uploaded file only.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (_aiAgentEnabled) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _openAiKeyController,
                  decoration: InputDecoration(
                    hintText: 'Enter OpenAI API Key (sk-...)',
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    prefixIcon: Icon(Icons.vpn_key_rounded,
                        color: _vibrantBlue.withOpacity(0.7)),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _vibrantBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: _vibrantBlue, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Key is used locally to call OpenAI. Make sure it has access to your uploaded doc context only.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
            if (!canUseAiAgent) ...[
              Row(
                children: [
                  Switch(
                    value: false,
                    activeColor: _vibrantBlue,
                    onChanged: (_) async {
                      await showUpgradeDialog(
                        context,
                        message:
                            'AI Agent is available on Plus and Premium plans.',
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Agent (locked)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Upgrade to Plus or Premium to enable AI Agent.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            // --- START BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _startMeeting,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _vibrantBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: Text(
                  _isLoading ? 'Starting...' : 'Start Meeting',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- SKIP BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        context.push('/in_meeting');
                      },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  'Skip & Start Empty',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
