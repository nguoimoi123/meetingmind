import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  var _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _pages(BuildContext context) {
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    return [
      {
        'title': isVi
            ? 'Chao mung den voi\nMeetingMind AI'
            : 'Welcome to\nMeetingMind AI',
        'subtitle': isVi
            ? 'Tom tat cuoc hop thong minh, khong bo lo khoanh khac quan trong nao.'
            : 'Smart meeting summaries without missing the moments that matter.',
        'icon': Icons.rocket_launch_rounded,
        'start': const Color(0xFF4FACFE),
        'end': const Color(0xFF00F2FE),
      },
      {
        'title': isVi
            ? 'Tro ly cuoc hop\nthong minh'
            : 'A smarter\nmeeting assistant',
        'subtitle': isVi
            ? 'Ghi am, phien am tu dong va trich xuat y chinh de ban tap trung thao luan.'
            : 'Record, transcribe and extract key ideas so you can stay focused on the discussion.',
        'icon': Icons.mic_none_rounded,
        'start': const Color(0xFFA18CD1),
        'end': const Color(0xFFFBC2EB),
      },
      {
        'title': isVi ? 'So tay AI\nca nhan' : 'Your personal\nAI notebook',
        'subtitle': isVi
            ? 'To chuc tai lieu, tim kiem nhanh va tro chuyen voi AI trong cung mot noi.'
            : 'Organize documents, search faster and chat with AI in one place.',
        'icon': Icons.auto_stories_rounded,
        'start': const Color(0xFF84FAB0),
        'end': const Color(0xFF8FD3F4),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    final pages = _pages(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(l10n.tr('skip')),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPageIndex = index);
                },
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return _OnboardingPage(
                    title: page['title'] as String,
                    subtitle: page['subtitle'] as String,
                    icon: page['icon'] as IconData,
                    start: page['start'] as Color,
                    end: page['end'] as Color,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentPageIndex ? 28 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: index == _currentPageIndex
                              ? colorScheme.primary
                              : colorScheme.outline.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPageIndex < pages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          context.go('/login');
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPageIndex == pages.length - 1
                                ? l10n.tr('getStartedNow')
                                : l10n.tr('continue'),
                          ),
                          if (_currentPageIndex < pages.length - 1) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.start,
    required this.end,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color start;
  final Color end;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: size.height * 0.35,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        start.withOpacity(0.2),
                        end.withOpacity(0.08),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [start, end]),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: start.withOpacity(0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 72),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
