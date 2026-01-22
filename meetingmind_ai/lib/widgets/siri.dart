import 'dart:math' as math;
import 'package:flutter/material.dart';

class SiriNewButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const SiriNewButton({super.key, this.onPressed});

  @override
  State<SiriNewButton> createState() => _SiriNewButtonState();
}

class _SiriNewButtonState extends State<SiriNewButton>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(); // Lặp lại vô tận
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        return Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Gradient dạng quét tròn (Sweep) giống Siri
            gradient: SweepGradient(
              colors: const [
                Color(0xFFFF2D55), // Hồng
                Color(0xFF2962FF), // Xanh dương
                Color(0xFF00C853), // Xanh lá
                Color(0xFFFF2D55), // Vòng lại màu đầu
              ],
              transform: GradientRotation(
                _gradientController.value * 2 * math.pi,
              ),
            ),
            // Viền trắng dày đặc trưng
            border: Border.all(
              color: Colors.white,
              width: 3.5,
            ),
            // Bóng đổ nổi
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2962FF).withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: widget.onPressed,
              customBorder: const CircleBorder(),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }
}
