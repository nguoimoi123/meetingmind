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

  // Dữ liệu onboarding (Đã loại bỏ imageAsset để dùng Code-generated Art)
  final List<Map<String, dynamic>> _onboardingPages = [
    {
      'title': 'Chào mừng đến với\nMeetingMind AI',
      'subtitle':
          'Tóm tắt cuộc họp thông minh, không bỏ lỡ khoảnh khắc quan trọng nào.',
      'icon': Icons.rocket_launch, // Icon chủ đạo
      'bgColorStart': const Color(0xFF4facfe),
      'bgColorEnd': const Color(0xFF00f2fe),
    },
    {
      'title': 'Trợ lý cuộc họp\nthông minh',
      'subtitle':
          'Ghi âm, phiên âm tự động và trích xuất các ý chính. Bạn chỉ việc tập trung thảo luận.',
      'icon': Icons.mic_none_rounded,
      'bgColorStart': const Color(0xFFa18cd1),
      'bgColorEnd': const Color(0xFFfbc2eb),
    },
    {
      'title': 'Sổ tay AI\ncá nhân',
      'subtitle':
          'Tổ chức tài liệu, tìm kiếm thông tin nhanh chóng nhờ trí tuệ nhân tạo tích hợp.',
      'icon': Icons.auto_stories_rounded,
      'bgColorStart': const Color(0xFF84fab0),
      'bgColorEnd': const Color(0xFF8fd3f4),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Nền sáng sủa, hiện đại
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // --- Nút "Bỏ qua" ---
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  child: const Text('Bỏ qua'),
                ),
              ),
            ),

            // --- PageView (Nội dung chính) ---
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) =>
                    setState(() => _currentPageIndex = index),
                itemCount: _onboardingPages.length,
                itemBuilder: (context, index) {
                  final data = _onboardingPages[index];
                  // Sử dụng TweenAnimationBuilder để tạo hiệu ứng mỗi khi chuyển trang
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(
                            0, 50 * (1 - value)), // Hiệu ứng trượt từ dưới lên
                        child: Opacity(
                          opacity: value,
                          child: _buildOnboardingPage(
                            context,
                            data['title'],
                            data['subtitle'],
                            data['icon'],
                            data['bgColorStart'],
                            data['bgColorEnd'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // --- Phần điều khiển dưới cùng ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                children: [
                  // Indicators (Chấm tròn)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingPages.length,
                      (index) => _buildPageIndicator(
                        isActive: index == _currentPageIndex,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Nút Tiếp tục / Bắt đầu
                  SizedBox(
                    width: double.infinity,
                    height: 56, // Chiều cao cố định cho nút
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPageIndex < _onboardingPages.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          context.go('/login');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30), // Bo tròn đầy
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPageIndex == _onboardingPages.length - 1
                                ? 'Bắt đầu ngay'
                                : 'Tiếp tục',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (_currentPageIndex < _onboardingPages.length - 1)
                            const SizedBox(width: 8),
                          if (_currentPageIndex < _onboardingPages.length - 1)
                            const Icon(Icons.arrow_forward_rounded, size: 20),
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

  // Widget xây dựng nội dung từng trang
  Widget _buildOnboardingPage(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color colorStart,
    Color colorEnd,
  ) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- 1. Hình minh họa trừu tượng (Abstract Illustration) ---
          SizedBox(
            height: size.height * 0.35, // Chiếm 35% chiều cao màn hình
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Hình tròn nền mờ (Decorative Blob)
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorStart.withOpacity(0.2),
                        colorEnd.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),

                // Khung chứa Icon chính (Card nổi)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: colorStart.withOpacity(0.3),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 80,
                    color: colorStart, // Dùng màu gradient đầu cho icon
                  ),
                ),

                // Các điểm trang trí xung quanh (Floating Bubbles)
                Positioned(
                  top: 20,
                  right: 40,
                  child: _buildFloatingDot(colorEnd),
                ),
                Positioned(
                  bottom: 30,
                  left: 30,
                  child: _buildFloatingDot(colorStart),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // --- 2. Tiêu đề ---
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              height: 1.2, // Giảm chiều cao dòng để title gọn hơn
            ),
          ),

          const SizedBox(height: 24),

          // --- 3. Mô tả ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                height: 1.5, // Tăng chiều cao dòng để dễ đọc
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget tạo chấm trang trí nhỏ
  Widget _buildFloatingDot(Color color) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
    );
  }

  // Widget vẽ chấm tròn điều hướng (Indicator) hiện đại
  Widget _buildPageIndicator({
    required bool isActive,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      height: isActive ? 8 : 8,
      width: isActive ? 32 : 8, // Kéo dài ra khi active
      decoration: BoxDecoration(
        color: isActive ? color : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
