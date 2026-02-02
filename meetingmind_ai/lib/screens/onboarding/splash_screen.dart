import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Controller để điều khiển animation
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Khởi tạo AnimationController
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500), // Thời gian chạy animation
      vsync: this,
    );

    // Animation cho hiệu ứng phóng to nhẹ (Scale)
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut, // Hiệu ứng nảy nhẹ cuối cùng
    );

    // Animation cho hiệu ứng hiện ra dần (Fade In)
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve:
          Interval(0.3, 1.0, curve: Curves.easeIn), // Bắt đầu muộn hơn một chút
    );

    // Bắt đầu chạy animation
    _controller.forward();

    // Logic chuyển màn hình sau 3 giây
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      context.go('/onboarding');
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Luôn dispose controller để tránh rò rỉ bộ nhớ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          // Sử dụng LinearGradient với nhiều điểm màu để tạo chiều sâu
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
              theme.colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // --- LOGO NÂNG CẤP ---
                // Sử dụng ScaleTransition để tạo hiệu ứng phóng to
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        // Đổ bóng mềm (Soft Shadow)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: 5,
                        ),
                        // Đổ bóng phát sáng (Glow)
                        BoxShadow(
                          color: Colors.white.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Icon(
                        Icons.graphic_eq, // Icon sóng âm thanh/AI hiện đại hơn
                        size: 60,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // --- TÊN ỨNG DỤNG ---
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "MeetingMind AI",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2, // Tăng khoảng cách chữ cho sang trọng
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // --- SLOGAN ---
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    "Your Intelligent Meeting Partner",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const Spacer(),

                // --- INDICATOR TẢI (LOADING DOTS) ---
                // FadeTransition(
                //   opacity: _fadeAnimation,
                //   child: const Padding(
                //     padding: EdgeInsets.only(bottom: 40.0),
                //     child: _DotLoader(), // Widget loader tùy chỉnh bên dưới
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget nhỏ để tạo hiệu ứng 3 chấm nhảy nháy (Pulsing Dots)
class _DotLoader extends StatelessWidget {
  const _DotLoader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 400 + (index * 200)),
            curve: Curves.easeInOut,
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              // Thay đổi opacity để tạo cảm giác nhấp nháy (fake animation trong stateless widget)
              // Để animation mượt mà thật sự cần TweenAnimationBuilder,
              // ở đây dùng cách đơn giản hóa hoặc bạn có thể dùng stateful riêng.
            ),
          );
        }),
      ),
    );
  }
}
