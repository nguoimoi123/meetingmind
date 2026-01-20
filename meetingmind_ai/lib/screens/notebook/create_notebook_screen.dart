import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/services/create_notebook_service.dart'; // Giả định đường dẫn
import 'package:meetingmind_ai/providers/auth_provider.dart'; // Giả định đường dẫn
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

  @override
  void initState() {
    super.initState();

    // Lấy UserID an toàn sau khi frame xây dựng xong
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

    // Lắng nghe thay đổi text để kích hoạt nút bấm
    _titleController.addListener(() {
      final hasText = _titleController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });

    // Lắng nghe Focus để chạy animation
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

    // Thuật bàn phím trước khi xử lý
    FocusScope.of(context).unfocus();
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
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
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
    // Xác định chế độ sáng/tối để điều chỉnh màu sắc cho phù hợp
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Màu nền tổng thể
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF5F7FA),
      body: Stack(
        children: [
          Column(
            children: [
              // --- PHẦN HEADER (FLEX 4/10) ---
              Expanded(
                flex: 4,
                child: Stack(
                  children: [
                    // 1. Background với Gradient & Decoration
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  colorScheme.primaryContainer,
                                  colorScheme.surface,
                                ]
                              : [
                                  colorScheme.primary,
                                  colorScheme.secondary,
                                ],
                        ),
                      ),
                      // Trang trí thêm các vòng tròn mờ (Bloom effect)
                      child: Opacity(
                        opacity: 0.1,
                        child: Image.asset(
                          'assets/images/pattern.png', // Bạn có thể bỏ dòng này nếu không có ảnh
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => const SizedBox.shrink(),
                        ),
                      ),
                    ),

                    // 2. Nội dung Header
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            // Nút đóng style Glassmorphism
                            InkWell(
                              onTap: () => context.pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.white.withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: isDark
                                      ? Colors.white
                                      : colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Icon & Text lớn
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.auto_stories_rounded,
                                    color: isDark
                                        ? Colors.white
                                        : colorScheme.onPrimary,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Create',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          color: isDark
                                              ? Colors.white70
                                              : colorScheme.onPrimary
                                                  .withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'New Notebook',
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                          color: isDark
                                              ? Colors.white
                                              : colorScheme.onPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- PHẦN FORM NỘI DUNG (FLEX 6/10) ---
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  // Bo góc chỉ phía trên để tạo hiệu ứng tấm bảng trượt lên
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    // Bóng đổ nhẹ để tạo độ nổi cho tấm form
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: SingleChildScrollView(
                      // Padding dưới cùng động theo bàn phím
                      padding: EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 32,
                        bottom: MediaQuery.of(context).viewInsets.bottom +
                            100, // +100 để button không bị che quá sát
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- TITLE INPUT ---
                            Text(
                              'Notebook Name',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _titleController,
                              focusNode: _titleFocusNode,
                              enabled: !_isLoading,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                              decoration: InputDecoration(
                                hintText: 'e.g. Project Alpha',
                                hintStyle:
                                    theme.textTheme.headlineMedium?.copyWith(
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
                            // Animated Line
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: AnimatedBuilder(
                                animation: _scaleAnimation,
                                builder: (context, child) {
                                  return FractionallySizedBox(
                                    widthFactor: _scaleAnimation.value,
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            colorScheme.primary,
                                            colorScheme.secondary,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 32),

                            // --- DESCRIPTION INPUT ---
                            Text(
                              'Description',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Input dạng Card nổi
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _descriptionFocusNode.hasFocus
                                    ? colorScheme.primaryContainer
                                        .withOpacity(0.3)
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _descriptionFocusNode.hasFocus
                                      ? colorScheme.primary.withOpacity(0.5)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: TextFormField(
                                controller: _descriptionController,
                                focusNode: _descriptionFocusNode,
                                enabled: !_isLoading,
                                maxLines: 5,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'What is this notebook about?',
                                  hintStyle:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // --- FLOATING ACTION BUTTON (Create Button) ---
          // Đặt vị trí tuyệt đối để nó trôi lơ lửng phía trên
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              // Gradient Background để button hòa trộn vào form
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface.withOpacity(0),
                    colorScheme.surface,
                  ],
                  stops: const [0.0, 0.1],
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
                            child: CircularProgressIndicator(
                                color: colorScheme.primary),
                          ),
                        )
                      : InkWell(
                          onTap: _hasText ? _submitForm : null,
                          borderRadius: BorderRadius.circular(32),
                          splashColor: colorScheme.onPrimary.withOpacity(0.2),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: _hasText
                                  ? LinearGradient(
                                      colors: [
                                        colorScheme.primary,
                                        colorScheme.secondary,
                                      ],
                                    )
                                  : null,
                              color: _hasText
                                  ? null
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: _hasText
                                  ? [
                                      BoxShadow(
                                        color: colorScheme.primary
                                            .withOpacity(0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Create Notebook',
                                  style: theme.textTheme.titleLarge?.copyWith(
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
                                      : colorScheme.onSurface.withOpacity(0.4),
                                )
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
