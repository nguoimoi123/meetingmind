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

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  bool _hasText = false;
  bool _isLoading = false;
  late String _userId;

  // --- PALETTE MÀU SẮC ---
  static const Color _vibrantBlue = Color(0xFF2962FF);
  static const Color _softBlue = Color(0xFF448AFF);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _userId = context.read<AuthProvider>().userId!;
      }
    });

    // Animation cho dòng gạch dưới title
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Lắng nghe thay đổi text
    _titleController.addListener(() {
      final hasText = _titleController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });

    // Lắng nghe Focus
    _titleFocusNode.addListener(() {
      if (_titleFocusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _animationController.dispose();
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
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          Column(
            children: [
              // --- HEADER SECTION (Clean & Vibrant) ---
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    // Header Background
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [_vibrantBlue, _softBlue],
                            ),
                          ),
                        ),
                        // Subtle decoration circles
                        Positioned(
                          top: -50,
                          right: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Header Content
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            // Close Button (Glassmorphism)
                            InkWell(
                              onTap: () => context.pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Title & Icon
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.description_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Create',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        'New Notebook',
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          height: 1.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- FORM CONTENT ---
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surface : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
                        blurRadius: 40,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 40,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 120,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- TITLE INPUT ---
                            Text(
                              'Notebook Name',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: _vibrantBlue,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _titleController,
                              focusNode: _titleFocusNode,
                              enabled: !_isLoading,
                              textCapitalization: TextCapitalization.words,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter notebook name',
                                hintStyle:
                                    theme.textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.2),
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              validator: (value) => value!.trim().isEmpty
                                  ? 'Please enter a name'
                                  : null,
                            ),
                            // Animated Underline
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: AnimatedBuilder(
                                animation: _scaleAnimation,
                                builder: (context, child) {
                                  return FractionallySizedBox(
                                    widthFactor: _scaleAnimation.value,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [_vibrantBlue, _softBlue],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 32),

                            // --- DESCRIPTION INPUT (Modern Card Style) ---
                            Text(
                              'Description',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: _vibrantBlue,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? colorScheme.surfaceContainerHighest
                                    : const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: _descriptionFocusNode.hasFocus
                                      ? _vibrantBlue.withOpacity(0.5)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  if (_descriptionFocusNode.hasFocus)
                                    BoxShadow(
                                      color: _vibrantBlue.withOpacity(0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 5),
                                    )
                                ],
                              ),
                              child: TextFormField(
                                controller: _descriptionController,
                                focusNode: _descriptionFocusNode,
                                enabled: !_isLoading,
                                maxLines: 5,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                  height: 1.5,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'What is this notebook about?',
                                  hintStyle:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // --- FLOATING CREATE BUTTON ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              // Gradient fade để button hòa với form
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark ? colorScheme.surface : Colors.white,
                    isDark ? colorScheme.surface : Colors.white,
                  ],
                ),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 10,
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: _isLoading
                      ? Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Center(
                            child:
                                CircularProgressIndicator(color: _vibrantBlue),
                          ),
                        )
                      : InkWell(
                          onTap: _hasText ? _submitForm : null,
                          borderRadius: BorderRadius.circular(32),
                          splashColor: Colors.white24,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: _hasText
                                  ? const LinearGradient(
                                      colors: [_vibrantBlue, _softBlue],
                                    )
                                  : null,
                              color: _hasText
                                  ? null
                                  : (isDark
                                      ? colorScheme.surfaceContainerHighest
                                      : const Color(0xFFE0E0E0)),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: _hasText
                                  ? [
                                      BoxShadow(
                                        color: _vibrantBlue.withOpacity(0.4),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Create Notebook',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _hasText
                                        ? Colors.white
                                        : colorScheme.onSurface
                                            .withOpacity(0.5),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                  color: _hasText
                                      ? Colors.white
                                      : colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
