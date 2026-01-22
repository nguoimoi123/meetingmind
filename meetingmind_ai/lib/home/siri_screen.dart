import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: VoiceSelectionScreen(),
  ));
}

// --- 1. MODEL DỮ LIỆU ---
class Voice {
  final String name;
  final String description;
  final List<Color> colors; // [Primary, Secondary, Accent]

  Voice(this.name, this.description, this.colors);
}

final List<Voice> VOICES = [
  Voice('Clover', 'Warm and grounded', [
    const Color(0xFF60A5FA),
    const Color(0xFF3B82F6),
    const Color(0xFF93C5FD),
  ]),
  Voice('Breeze', 'Light and airy', [
    const Color(0xFF22D3EE),
    const Color(0xFF06B6D4),
    const Color(0xFFA5F3FC),
  ]),
  Voice('Ember', 'Bold and confident', [
    const Color(0xFFF97316),
    const Color(0xFFEA580C),
    const Color(0xFFFDBA74),
  ]),
  Voice('Echo', 'Clear and resonant', [
    const Color(0xFFA855F7),
    const Color(0xFF9333EA),
    const Color(0xFFD8B4FE),
  ]),
  Voice('Sage', 'Wise and calm', [
    const Color(0xFF10B981),
    const Color(0xFF059669),
    const Color(0xFF6EE7B7),
  ]),
  Voice('Nova', 'Bright and energetic', [
    const Color(0xFFEAB308),
    const Color(0xFFCA8A04),
    const Color(0xFFFDE047),
  ]),
  Voice('River', 'Smooth and flowing', [
    const Color(0xFF14B8A6),
    const Color(0xFF0D9488),
    const Color(0xFF5EEAD4),
  ]),
  Voice('Storm', 'Powerful and dynamic', [
    const Color(0xFF64748B),
    const Color(0xFF475569),
    const Color(0xFF94A3B8),
  ]),
  Voice('Dawn', 'Fresh and optimistic', [
    const Color(0xFFF472B6),
    const Color(0xFFDB2777),
    const Color(0xFFFBCFE8),
  ]),
  Voice('Frost', 'Cool and precise', [
    const Color(0xFF38BDF8),
    const Color(0xFF0EA5E9),
    const Color(0xFFBAE6FD),
  ]),
  Voice('Harmony', 'Balanced and melodic', [
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF6366F1),
  ]),
];

// --- 2. VOICE ORB WIDGET (Hiệu ứng cầu năng lượng) ---
class VoiceOrb extends StatefulWidget {
  final ValueChanged<List<Color>>? onColorChanged;

  const VoiceOrb({super.key, this.onColorChanged});

  @override
  State<VoiceOrb> createState() => _VoiceOrbState();
}

class _VoiceOrbState extends State<VoiceOrb> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _colorController;
  int _currentColorIndex = 0;
  List<Color> _currentColors = [];
  List<Color> _targetColors = [];

  @override
  void initState() {
    super.initState();

    // Khởi tạo màu ban đầu từ VOICES
    _currentColors = VOICES[0].colors;
    _targetColors = VOICES[1].colors;

    // Animation xoay và hiệu ứng
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Animation chuyển màu
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Tự động chuyển màu mỗi 3 giây
    _startColorTransition();
  }

  void _startColorTransition() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;

      setState(() {
        _currentColorIndex = (_currentColorIndex + 1) % VOICES.length;
        _targetColors = VOICES[(_currentColorIndex + 1) % VOICES.length].colors;
      });

      // Thông báo cho parent về màu mới
      widget.onColorChanged?.call(_targetColors);

      _colorController.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 2000));

      if (mounted) {
        setState(() {
          _currentColors = VOICES[_currentColorIndex].colors;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Color _lerpColor(Color a, Color b) {
    return Color.lerp(a, b, _colorController.value) ?? a;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _colorController]),
      builder: (context, child) {
        final rotation = _controller.value * 2 * math.pi;
        // Hiệu ứng thở (scale)
        final scale = 1.0 + (math.sin(_controller.value * math.pi * 2) * 0.05);

        // Tính màu hiện tại với hiệu ứng chuyển màu mượt
        final color0 = _lerpColor(_currentColors[0], _targetColors[0]);
        final color1 = _lerpColor(_currentColors[1], _targetColors[1]);
        final color2 = _lerpColor(_currentColors[2], _targetColors[2]);

        return Container(
          width: 320, // md:w-80 approx
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // Glow phía sau
              BoxShadow(
                color: color0.withOpacity(0.3),
                blurRadius: 60,
                spreadRadius: 20,
              ),
            ],
          ),
          child: Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Base Gradient Layer (Conic gradient simulation)
                Transform.rotate(
                  angle: rotation,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          color0,
                          color1,
                          color2,
                          color0,
                        ],
                      ),
                    ),
                  ),
                ),

                // Fluid Overlay 2 (Moving Blob simulation)
                Transform.rotate(
                  angle: -rotation * 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment(_controller.value * 0.5 - 0.25,
                            _controller.value * 0.5 - 0.25),
                        radius: 1.5,
                        colors: [
                          color2.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Highlight / Reflection (3D effect)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      center: Alignment(-0.3, -0.3),
                      radius: 1.0,
                      colors: [
                        Color.fromRGBO(255, 255, 255, 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Border subtle
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black.withOpacity(0.05),
                      width: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- 3. MAIN SCREEN ---
class VoiceSelectionScreen extends StatefulWidget {
  const VoiceSelectionScreen({super.key});

  @override
  State<VoiceSelectionScreen> createState() => _VoiceSelectionScreenState();
}

class _VoiceSelectionScreenState extends State<VoiceSelectionScreen> {
  List<Color> _currentBackgroundColors = VOICES[0].colors;

  void _onColorChanged(List<Color> newColors) {
    setState(() {
      _currentBackgroundColors = newColors;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Animated Background - Tự động đổi màu theo quả cầu
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 2000),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, 0),
            radius: 1.2,
            colors: [
              _currentBackgroundColors[0].withOpacity(0.15),
              _currentBackgroundColors[1].withOpacity(0.08),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // --- HEADER ---
              Positioned(
                top: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "Voice with AI",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),

              // --- VOICE ORB - CENTER ---
              Center(
                child: VoiceOrb(
                  onColorChanged: _onColorChanged,
                ),
              ),

              // --- CLOSE BUTTON (Top-Left) ---
              Positioned(
                top: 16,
                left: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white.withOpacity(0.9),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
