import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class GeneratingSummaryScreen extends StatelessWidget {
  const GeneratingSummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Thay thế bằng Lottie animation của bạn
            // Lottie.asset('assets/animations/generating_summary.json'),
            // Hoặc dùng widget tạm thời
            SizedBox(
              width: 200,
              height: 200,
              child: _buildNeuralNetworkAnimation(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Generating summary...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.accentColor,
                fontWeight: FontWeight.normal,
              ),
            ),
            const SizedBox(height: 10),
            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIndicator(false),
                _buildIndicator(true),
                _buildIndicator(false),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.accentColor
            : AppTheme.accentColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // Widget tạm thời cho animation mạng nơ-ron
  Widget _buildNeuralNetworkAnimation() {
    return const Icon(Icons.psychology, size: 100, color: AppTheme.accentColor);
  }
}
