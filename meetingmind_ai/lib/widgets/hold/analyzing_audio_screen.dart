import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AnalyzingAudioScreen extends StatelessWidget {
  const AnalyzingAudioScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Bạn cần có file animation này trong assets
    // Ví dụ: assets/animations/analyzing_audio.json
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Thay thế bằng Lottie animation của bạn
            // Lottie.asset('assets/animations/analyzing_audio.json'),
            // Hoặc dùng một widget tạm thời nếu chưa có file
            SizedBox(
              width: 200,
              height: 100,
              child: _buildSoundWaveAnimation(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Analyzing audio...',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.accentColor,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget tạm thời để tạo hiệu ứng sóng âm
  Widget _buildSoundWaveAnimation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(5, (index) {
        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          width: 4,
          height: 20.0 + (index * 8.0) + (index.isEven ? 10.0 : 0.0),
          margin: const EdgeInsets.symmetric(horizontal: 2.0),
          decoration: BoxDecoration(
            color: AppTheme.accentColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
