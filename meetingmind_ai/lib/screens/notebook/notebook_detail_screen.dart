import 'dart:convert';
import 'dart:io'; // Cần để xử lý file
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Package chọn file
import 'package:http/http.dart' as http;

class FileItem {
  String id;
  String name;
  String size;
  String uploadDate;
  FileItem({
    required this.id,
    required this.name,
    required this.size,
    required this.uploadDate,
  });
  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'],
      name: json['filename'],
      size: json['size'],
      uploadDate: json['uploaded_at'],
    );
  }
}
// ==========================================
// SCREEN
// ==========================================

class NotebookDetailScreen extends StatelessWidget {
  final String folderId;

  const NotebookDetailScreen({
    super.key,
    required this.folderId,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            const Expanded(
              child: TabBarView(
                children: [
                  SourcesTab(
                      folderId: 'folder_id_placeholder'), // Truyền folderId
                  AskAITab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 16.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 5)
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Marketing Strategy',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: const Color(0xFF6366F1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [Tab(text: 'Sources'), Tab(text: 'Ask AI')],
      ),
    );
  }
}

// ==========================================
// TAB 1: SOURCES (ĐÃ CẬP NHẬT THÊM FILE)
// ==========================================
class SourcesTab extends StatefulWidget {
  final String folderId;
  const SourcesTab({super.key, required this.folderId});

  @override
  State<SourcesTab> createState() => _SourcesTabState();
}

class _SourcesTabState extends State<SourcesTab> {
  bool _isUploading = false;

  // Danh sách file (Giả lập)
  List<Map<String, dynamic>> _files = [
    {"name": "Q4 Financial Report.pdf", "size": "2.4 MB", "date": "2 days ago"},
    {"name": "Brand Guidelines.docx", "size": "1.1 MB", "date": "1 week ago"},
  ];

  Future<void> _pickAndUploadFile() async {
    try {
      // 1. Chọn file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['doc', 'docx', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String fileName = result.files.single.name;

        setState(() {
          _isUploading = true;
        });

        // 2. Giả lập Gọi API Upload (Thay bằng URL thực tế của bạn)
        // Ví dụ: POST http://127.0.0.1:5000/folder/{folderId}/upload
        await Future.delayed(const Duration(seconds: 2)); // Giả lập độ trễ mạng

        // Giả lập thành công
        setState(() {
          _files.add({"name": fileName, "size": "New", "date": "Just now"});
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('File uploaded successfully!'),
                backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to upload file: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(24.0),
            itemCount: _files.length + 1, // +1 cho phần Upload
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              // Phần tử cuối cùng là nút Upload
              if (index == _files.length) {
                return _buildUploadCard(context);
              }
              return _buildFileCard(_files[index]);
            },
          ),
        ),
      ],
    );
  }

  // Giao diện thẻ file
  Widget _buildFileCard(Map<String, dynamic> file) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.description_rounded,
                color: Color(0xFF6366F1), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${file['size']} • ${file['date']}',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Icon(Icons.more_vert, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  // Giao diện thẻ Upload (Dashed Border)
  Widget _buildUploadCard(BuildContext context) {
    return InkWell(
      onTap: _isUploading ? null : _pickAndUploadFile,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFF6366F1),
              width: 2,
              style: BorderStyle
                  .solid), // Viền nét đứt giả lập bằng màu sắc đơn giản hoặc dùng DashPattern
          // Lưu ý: Flutter cơ bản không hỗ trợ dashed border dễ dàng, ta dùng Border.all liền và giảm opacity để tạo cảm giác nhẹ
        ),
        child: _isUploading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.grey.shade400),
                  const SizedBox(width: 8),
                  Text(
                    'Add New Document',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ==========================================
// TAB 2: ASK AI
// ==========================================
class AskAITab extends StatelessWidget {
  const AskAITab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _buildMessage('AI', 'Hello! How can I help you today?', context,
                  isUser: false),
              const SizedBox(height: 20),
              _buildMessage('You', 'Give me a summary.', context, isUser: true),
              const SizedBox(height: 20),
              _buildMessage('AI', 'Here is the summary...', context,
                  isUser: false),
            ],
          ),
        ),
        _buildInputArea(context),
      ],
    );
  }

  Widget _buildMessage(String sender, String text, BuildContext context,
      {required bool isUser}) {
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFF6366F1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 8)
                ]),
            child:
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)])
                  : null,
              color: isUser ? null : Colors.white,
              borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20)),
              boxShadow: !isUser
                  ? [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5))
                    ]
                  : null,
            ),
            child: Text(text,
                style: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFF334155),
                    fontSize: 15,
                    height: 1.4)),
          ),
        ),
        if (isUser) ...[
          const SizedBox(width: 12),
          CircleAvatar(
              radius: 16,
              backgroundImage:
                  const NetworkImage('https://i.pravatar.cc/150?img=12')),
        ],
      ],
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ]),
      child: Row(
        children: [
          const Icon(Icons.add_circle_outline, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
              child: TextField(
                  decoration: InputDecoration(
                      hintText: 'Ask AI anything...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey.shade400)))),
          const SizedBox(width: 8),
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        blurRadius: 10)
                  ]),
              child: const Icon(Icons.arrow_upward_rounded,
                  color: Colors.white, size: 20)),
        ],
      ),
    );
  }
}
