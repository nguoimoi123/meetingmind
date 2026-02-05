import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/services/create_notebook_service.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/config/plan_limits.dart';
import 'package:meetingmind_ai/services/notebook_list_service.dart';
import 'package:meetingmind_ai/widgets/upgrade_dialog.dart';
import 'package:provider/provider.dart';

class CreateNotebookScreen extends StatefulWidget {
  const CreateNotebookScreen({super.key});

  @override
  State<CreateNotebookScreen> createState() => _CreateNotebookScreenState();
}

class _CreateNotebookScreenState extends State<CreateNotebookScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  late AnimationController _buttonAnimationController;
  late Animation<double> _buttonScaleAnimation;

  bool _hasText = false;
  bool _isLoading = false;
  late String _userId;

  // Palette màu sắc hiện đại
  static const Color _primaryColor = Color(0xFF2962FF);
  static const Color _bgColor = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _userId = context.read<AuthProvider>().userId!;
      }
    });

    // Animation cho nút bấm khi có nội dung
    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.easeOut),
    );

    _titleController.addListener(() {
      final hasText = _titleController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
        if (hasText) {
          _buttonAnimationController.forward();
        } else {
          _buttonAnimationController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final plan = auth.plan;
    final folderLimit = PlanLimits.folderLimitFromLimits(auth.limits) ??
        PlanLimits.folderLimit(plan);
    
    if (folderLimit != null) {
      try {
        final folders = await NotebookListService.fetchFolders(_userId);
        if (folders.length >= folderLimit) {
          if (mounted) {
            await showUpgradeDialog(
              context,
              message: 'Notebook limit reached for $plan plan. Please upgrade.',
            );
          }
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }

    try {
      await NotebookService.createNotebook(
        userId: _userId,
        name: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : _bgColor,
      // App Bar trong suốt, gọn nhẹ
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Icon(Icons.close_rounded, color: colorScheme.onSurface),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'New Project',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      // Decor nền trang trí (Gradient Blob)
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primaryColor.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purple.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Nội dung chính
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Intro
                Text(
                  'Create a new workspace',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Organize your documents and start chatting with AI.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),

                // Main Card Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- TITLE INPUT ---
                        Text(
                          'Project Name',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: _primaryColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _titleController,
                          focusNode: _titleFocusNode,
                          enabled: !_isLoading,
                          textCapitalization: TextCapitalization.words,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Q4 Marketing Plan',
                            filled: true,
                            fillColor: isDark ? colorScheme.surface : _bgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) => value!.trim().isEmpty
                              ? 'Please enter a name'
                              : null,
                        ),

                        const SizedBox(height: 24),

                        // --- DESCRIPTION INPUT ---
                        Text(
                          'Description (Optional)',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: _primaryColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionController,
                          focusNode: _descriptionFocusNode,
                          enabled: !_isLoading,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurface,
                            height: 1.5,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Briefly describe this project...',
                            filled: true,
                            fillColor: isDark ? colorScheme.surface : _bgColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- TIP BOX ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryColor.withOpacity(0.08),
                        _primaryColor.withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.lightbulb_rounded,
                          color: _primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pro Tip: Uploading related documents together improves AI accuracy significantly.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.8),
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // --- CREATE BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _isLoading
                      ? Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          ),
                        )
                      : AnimatedScale(
                          scale: _hasText ? 1.0 : 0.98,
                          duration: const Duration(milliseconds: 200),
                          child: ElevatedButton(
                            onPressed: _hasText ? _submitForm : null,
                            style: ElevatedButton.styleFrom(
                              elevation: _hasText ? 2 : 0,
                              backgroundColor: _hasText
                                  ? _primaryColor
                                  : colorScheme.surfaceContainerHighest,
                              foregroundColor: _hasText
                                  ? Colors.white
                                  : colorScheme.onSurface.withOpacity(0.4),
                              disabledBackgroundColor: colorScheme.surfaceContainerHighest,
                              disabledForegroundColor: colorScheme.onSurface.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Create Project',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                ),

                SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}