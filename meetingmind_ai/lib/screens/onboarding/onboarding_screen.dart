import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  // Dữ liệu onboarding
  final List<Map<String, String>> _onboardingPages = [
    {
      'title': 'Chào mừng đến với MeetingMind AI',
      'subtitle': 'Tóm tắt cuộc họp thông minh, không bỏ lỡ khoảnh khắc nào.',
      'imageAsset': 'assets/images/onboarding_welcome.png',
    },
    {
      'title': 'Trợ lý cuộc họp thông minh của bạn',
      'subtitle':
          'MeetingMind AI ghi âm, phiên âm và trích xuất các mục hành động và quyết định chính, giúp bạn tập trung vào cuộc trò chuyện.',
      'imageAsset': 'assets/images/onboarding_assistant.png',
    },
    {
      'title': 'Sổ tay AI cá nhân',
      'subtitle':
          'Tổ chức tài liệu, tóm tắt thông tin và đặt câu hỏi trực tiếp về nội dung để tìm thông tin nhanh chóng.',
      'imageAsset': 'assets/images/onboarding_notebook.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Nút "Bỏ qua"
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Bỏ qua',
                    style: TextStyle(color: colorScheme.onBackground),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) =>
                    setState(() => _currentPageIndex = index),
                itemCount: _onboardingPages.length,
                itemBuilder: (context, index) {
                  final data = _onboardingPages[index];
                  return _buildOnboardingPage(
                    context,
                    data['title']!,
                    data['subtitle']!,
                    data['imageAsset']!,
                    theme,
                    colorScheme,
                  );
                },
              ),
            ),

            // Chỉ mục + Nút tiếp tục / bắt đầu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingPages.length,
                      (index) => _buildPageIndicator(
                        context,
                        index == _currentPageIndex,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Nút
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPageIndex < _onboardingPages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          context.go('/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentPageIndex == _onboardingPages.length - 1
                            ? 'Bắt đầu'
                            : 'Tiếp tục',
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

  Widget _buildOnboardingPage(
      BuildContext context,
      String title,
      String subtitle,
      String imageAsset,
      ThemeData theme,
      ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder image (thay bằng Image.asset nếu bạn có)
          Container(
            height: 300,
            width: 300,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.psychology,
              size: 100,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: theme.textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onBackground.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Page indicator
Widget _buildPageIndicator(BuildContext context, bool isActive) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    margin: const EdgeInsets.symmetric(horizontal: 6),
    height: 8,
    width: isActive ? 24 : 8,
    decoration: BoxDecoration(
      color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
