import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/providers/auth_provider.dart';
import 'package:meetingmind_ai/services/search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _result;

  Future<void> _search(String query) async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null || userId.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await SearchService.searchAll(userId: userId, query: query);
      if (mounted) {
        setState(() => _result = data);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSection(
      String title, List items, Widget Function(dynamic) tile) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...items.map(tile),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final meetings = (_result?['meetings'] as List?) ?? [];
    final notebooks = (_result?['notebooks'] as List?) ?? [];
    final files = (_result?['files'] as List?) ?? [];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              onSubmitted: (value) => _search(value.trim()),
              decoration: InputDecoration(
                hintText: 'Search meetings, notebooks, files...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _result = null);
                        },
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),
          Expanded(
            child: _error != null
                ? Center(child: Text(_error!))
                : _result == null
                    ? Center(
                        child: Text(
                          'Type a keyword to search',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      )
                    : ListView(
                        children: [
                          _buildSection(
                            'Meetings',
                            meetings,
                            (m) => ListTile(
                              leading: const Icon(Icons.videocam_rounded),
                              title: Text(m['title'] ?? 'Untitled'),
                              subtitle: Text(m['summary'] ?? ''),
                              onTap: () =>
                                  context.push('/post_summary/${m['id']}'),
                            ),
                          ),
                          _buildSection(
                            'Notebooks',
                            notebooks,
                            (n) => ListTile(
                              leading: const Icon(Icons.book_rounded),
                              title: Text(n['title'] ?? 'Untitled'),
                              subtitle: Text(n['description'] ?? ''),
                              onTap: () =>
                                  context.push('/notebook_detail/${n['id']}'),
                            ),
                          ),
                          _buildSection(
                            'Files',
                            files,
                            (f) => ListTile(
                              leading: const Icon(Icons.description_outlined),
                              title: Text(f['title'] ?? 'Untitled'),
                              subtitle:
                                  Text('Notebook: ${f['folder_id'] ?? ''}'),
                              onTap: () => context
                                  .push('/notebook_detail/${f['folder_id']}'),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
