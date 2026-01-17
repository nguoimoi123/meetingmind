import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:docx_to_text/docx_to_text.dart';

import 'package:meetingmind_ai/services/file_service.dart';
import 'package:meetingmind_ai/services/chat_service.dart';
import 'package:provider/provider.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';

class FileItem {
  String id;
  String name;
  int size;
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

// ======================= MAIN =========================

class NotebookDetailScreen extends StatefulWidget {
  final String folderId;
  const NotebookDetailScreen({super.key, required this.folderId});

  @override
  State<NotebookDetailScreen> createState() => _NotebookDetailScreenState();
}

class _NotebookDetailScreenState extends State<NotebookDetailScreen> {
  String _folderName = '';

  @override
  void initState() {
    super.initState();
    _fetchFolderInfo();
  }

  Future<void> _fetchFolderInfo() async {
    final data = await FileService.getFolder(widget.folderId);
    setState(() => _folderName = data['folder_name']);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.background,
        body: Column(
          children: [
            _buildHeader(context, theme, colorScheme),
            _buildTabBar(theme, colorScheme),
            Expanded(
              child: TabBarView(
                children: [
                  SourcesTab(folderId: widget.folderId),
                  AskAITab(folderId: widget.folderId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, ColorScheme cs) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Notebook',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.bold)),
              Text(_folderName.isNotEmpty ? _folderName : 'Loading...',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ])
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 50,
      decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(25)),
      child: const TabBar(tabs: [
        Tab(text: 'Sources'),
        Tab(text: 'Ask AI'),
      ]),
    );
  }
}

// ======================= TAB SOURCES =========================

class SourcesTab extends StatefulWidget {
  final String folderId;
  const SourcesTab({super.key, required this.folderId});

  @override
  State<SourcesTab> createState() => _SourcesTabState();
}

class _SourcesTabState extends State<SourcesTab> {
  bool _isLoading = true;
  bool _isUploading = false;
  List<FileItem> _files = [];
  late String _userId;
  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _userId = auth.userId!;
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    final data = await FileService.getFolder(widget.folderId);
    final List list = data['files'] ?? [];
    setState(() {
      _files = list.map((e) => FileItem.fromJson(e)).toList();
      _isLoading = false;
    });
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx', 'txt', 'md'],
    );
    if (result == null) return;

    final file = result.files.single;
    final content = await _readFile(file);
    if (content == null || content.isEmpty) return;

    setState(() => _isUploading = true);

    await FileService.uploadFile(
      userId: _userId,
      folderId: widget.folderId,
      file: file,
      content: content,
    );

    await _fetchFiles();
    setState(() => _isUploading = false);
  }

  Future<String?> _readFile(PlatformFile file) async {
    if (file.path == null) return null;
    if (file.extension == 'docx') {
      final bytes = await File(file.path!).readAsBytes();
      return docxToText(bytes);
    }
    return await File(file.path!).readAsString();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
      itemCount: _files.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _files.length) {
          return ElevatedButton(
            onPressed: _isUploading ? null : _pickAndUploadFile,
            child: const Text('Add New Document'),
          );
        }
        return ListTile(title: Text(_files[index].name));
      },
    );
  }
}

// ======================= TAB ASK AI =========================

class AskAITab extends StatefulWidget {
  final String folderId;
  const AskAITab({super.key, required this.folderId});

  @override
  State<AskAITab> createState() => _AskAITabState();
}

class _AskAITabState extends State<AskAITab> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendMessage(dynamic auth) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _textController.clear();
    });

    final answer = await ChatService.ask(
      folderId: widget.folderId,
      question: text,
      userId: auth.userId!,
    );

    setState(() {
      _messages.add(ChatMessage(text: answer, isUser: false));
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: ListView.builder(
          itemCount: _messages.length,
          itemBuilder: (_, i) => ListTile(title: Text(_messages[i].text)),
        ),
      ),
      Row(children: [
        Expanded(child: TextField(controller: _textController)),
        Consumer<AuthProvider>(
          builder: (context, auth, _) => IconButton(
            onPressed: () => _sendMessage(auth),
            icon: const Icon(Icons.send),
          ),
        )
      ])
    ]);
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}
