import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/services/create_notebook_service.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
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

  late AnimationController _animationController;
  late Animation<double> _widthAnimation;

  bool _hasText = false;
  bool _isLoading = false;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _titleFocusNode.requestFocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _userId = context.read<AuthProvider>().userId!;
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _widthAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _titleController.addListener(() {
      final hasText = _titleController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });

    _titleFocusNode.addListener(() {
      _titleFocusNode.hasFocus
          ? _animationController.forward()
          : _animationController.reverse();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await NotebookService.createNotebook(
        userId: _userId,
        name: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e',
                style: TextStyle(color: theme.colorScheme.onError)),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- build(...) giữ nguyên UI bạn gửi ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Giữ true để scaffold tự động điều chỉnh, nhưng chúng ta sẽ xử lý padding chi tiết hơn ở bên trong
      resizeToAvoidBottomInset: true,
      backgroundColor: colorScheme.background,
      body: SafeArea(
        // SafeArea bao bên ngoài để tránh lỗi tính toán padding lồng nhau
        top: true,
        bottom: false,
        child: Column(
          children: [
            // --- 1. HEADER (Sử dụng Flexible thay vì Expanded) ---
            // Flexible cho phép header co lại khi cần thiết thay vì cố định tỷ lệ
            Flexible(
              child: Container(
                // Giữ chiều cao tối đa khoảng 35% màn hình, nhưng có thể co lại
                height: MediaQuery.of(context).size.height * 0.35,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            colorScheme.primary,
                            const Color(0xFF0F172A),
                          ]
                        : [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nút đóng
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(Icons.close_rounded,
                            color: colorScheme.onPrimary),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              colorScheme.onPrimary.withOpacity(0.1),
                        ),
                      ),
                      const Spacer(),
                      // Tiêu đề
                      Text(
                        'New Collection',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Organize your thoughts in style.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimary.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // --- 2. FORM NỘI DUNG ---
            // Expanded chiếm phần không gian còn lại
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colorScheme.background,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  // QUAN TRỌNG: Thêm padding dưới cùng bằng chiều cao bàn phím
                  // để nội dung không bị che khuất khi bàn phím hiện ra
                  padding: EdgeInsets.only(
                    left: 32,
                    right: 32,
                    top: 40,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- LABEL ---
                        Text(
                          'Notebook Name',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- TITLE INPUT ---
                        TextFormField(
                          controller: _titleController,
                          focusNode: _titleFocusNode,
                          enabled: !_isLoading,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. Project Alpha',
                            hintStyle: theme.textTheme.headlineMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.2),
                              fontWeight: FontWeight.w300,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (value) => value!.trim().isEmpty
                              ? 'Please enter a name'
                              : null,
                        ),

                        // Animated Indicator Line
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: AnimatedBuilder(
                            animation: _widthAnimation,
                            builder: (context, child) {
                              return FractionallySizedBox(
                                widthFactor: _widthAnimation.value,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 40),

                        // --- LABEL ---
                        Text(
                          'Description',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // --- DESCRIPTION INPUT ---
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: TextFormField(
                            controller: _descriptionController,
                            enabled: !_isLoading,
                            maxLines: 5,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'What is this notebook about?',
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // --- CREATE BUTTON ---
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: _isLoading
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                        color: colorScheme.primary),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: _hasText ? _submitForm : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    elevation: _hasText ? 8 : 0,
                                    shadowColor:
                                        colorScheme.primary.withOpacity(0.4),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Create Notebook',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _hasText
                                              ? Colors.white
                                              : colorScheme.onSurface
                                                  .withOpacity(0.4),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: _hasText
                                            ? Colors.white
                                            : colorScheme.onSurface
                                                .withOpacity(0.4),
                                      )
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
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
