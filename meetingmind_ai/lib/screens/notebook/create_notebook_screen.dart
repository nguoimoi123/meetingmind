import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  final FocusNode _focusNode = FocusNode();

  // Gradient màu chủ đạo (Indigo đến Purple)
  final LinearGradient _primaryGradient = const LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  );

  bool _hasText = false;
  bool _isLoading = false;
  final String _userId = "6965304ba729391015e6d079";

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _titleController.addListener(() {
      final hasText = _titleController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() {
          _hasText = hasText;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final String notebookName = _titleController.text.trim();
      final String description = _descriptionController.text.trim();

      try {
        final String apiUrl = '${dotenv.env['API_BASE_URL']}/folder/add';

        final response = await http.post(
          Uri.parse(apiUrl),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            "user_id": _userId,
            "name": notebookName,
            "description": description,
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (mounted) context.pop(true);
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- BACKGROUND DECORATION (Tạo chiều sâu) ---
          _buildBackgroundDecoration(),

          // --- MAIN CONTENT ---
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 40.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Header nhỏ phía trên
                      Text(
                        'Create New',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 2.0,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w700,
                          textBaseline: TextBaseline.alphabetic,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // CARD CHÍNH
                      _buildMainCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
          ),
        ),
        child: Stack(
          children: [
            // Vòng tròn mờ phía trên bên trái
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                ),
              ),
            ),
            // Vòng tròn mờ phía dưới bên phải
            Positioned(
              bottom: -80,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 5,
                    spreadRadius: -5, // Tạo viền sáng nội bộ
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- ICON ---
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: _primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- TITLE INPUT ---
                    TextFormField(
                      controller: _titleController,
                      focusNode: _focusNode,
                      autofocus: true,
                      enabled: !_isLoading,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Notebook Name',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade300,
                          fontWeight: FontWeight.w800,
                          fontSize: 32,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (value) => value!.trim().isEmpty ? ' ' : null,
                    ),

                    const SizedBox(height: 12),

                    // Thanh gạch chân (Indicator)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      width: _focusNode.hasFocus ? 60 : 0, // Thay đổi chiều dài
                      decoration: BoxDecoration(
                        gradient: _primaryGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- DESCRIPTION INPUT (Styled Box) ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC), // Xanh xám rất nhạt
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade100,
                          width: 1,
                        ),
                      ),
                      child: TextFormField(
                        controller: _descriptionController,
                        enabled: !_isLoading,
                        maxLines: 3,
                        minLines: 1,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add a description...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // --- ACTION BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: _isLoading
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3, color: Color(0xFF6366F1)),
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: (_hasText && !_isLoading)
                                  ? _submitForm
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: BoxDecoration(
                                  gradient: _hasText ? _primaryGradient : null,
                                  color: _hasText ? null : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: _hasText
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF6366F1)
                                                .withOpacity(0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Create Notebook',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: _hasText
                                              ? Colors.white
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                        color: _hasText
                                            ? Colors.white
                                            : Colors.grey.shade400,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
