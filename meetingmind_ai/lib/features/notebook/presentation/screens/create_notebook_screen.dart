import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/features/notebook/logic/create_notebook_logic.dart';
import 'package:meetingmind_ai/features/notebook/presentation/widgets/create_notebook_form.dart';
import 'package:meetingmind_ai/features/notebook/presentation/widgets/create_notebook_submit_button.dart';
import 'package:meetingmind_ai/features/notebook/presentation/widgets/create_notebook_tip.dart';
import 'package:meetingmind_ai/l10n/app_localizations.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/widgets/upgrade_dialog.dart';
import 'package:provider/provider.dart';

class CreateNotebookScreen extends StatefulWidget {
  const CreateNotebookScreen({super.key});

  @override
  State<CreateNotebookScreen> createState() => _CreateNotebookScreenState();
}

class _CreateNotebookScreenState extends State<CreateNotebookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  bool _hasText = false;
  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userId = context.read<AuthProvider>().userId;
    });

    _titleController.addListener(() {
      final hasText = CreateNotebookLogic.hasRequiredText(_titleController.text);
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _userId == null) return;
    final l10n = context.l10n;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final plan = auth.plan;

    try {
      final canCreate = await CreateNotebookLogic.canCreateNotebook(
        userId: _userId!,
        plan: plan,
        limits: auth.limits,
      );

      if (!canCreate) {
        if (mounted) {
          await showUpgradeDialog(
            context,
            message: l10n.tr(
              'notebookLimitUpgrade',
              params: {'plan': plan},
            ),
          );
        }
        return;
      }

      await CreateNotebookLogic.createNotebook(
        userId: _userId!,
        name: _titleController.text,
        description: _descriptionController.text,
      );

      if (mounted) {
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.tr('errorPrefix', params: {'error': '$e'})),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
          l10n.tr('newProject'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ),
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
                    colorScheme.primary.withOpacity(0.15),
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
                    colorScheme.secondary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tr('createWorkspace'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.tr('workspaceDescription'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color:
                        isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: CreateNotebookForm(
                    formKey: _formKey,
                    titleController: _titleController,
                    descriptionController: _descriptionController,
                    titleFocusNode: _titleFocusNode,
                    descriptionFocusNode: _descriptionFocusNode,
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(height: 24),
                const CreateNotebookTip(),
                const SizedBox(height: 32),
                CreateNotebookSubmitButton(
                  isLoading: _isLoading,
                  enabled: _hasText,
                  onPressed: _submitForm,
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
