import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:meetingmind_ai/models/meeting_models.dart';
import 'dart:math' as math;
import 'dart:ui';

// =================================================================
// PALETTE MÀU SẮC SỐNG ĐỘNG (Vibrant Palette)
// =================================================================
class DashboardColors {
  static const List<Color> notebookColors = [
    Color(0xFF4285F4), // Google Blue
    Color(0xFF34A853), // Google Green
    Color(0xFFFBBC05), // Google Yellow
    Color(0xFFEA4335), // Google Red
    Color(0xFFAA00FF), // Deep Purple
    Color(0xFF00BCD4), // Cyan
  ];
}

// =================================================================
// MEETING CARD WIDGET
// =================================================================
class MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final DateFormat dateFormat;

  const MeetingCard({
    super.key,
    required this.meeting,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2962FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.videocam,
                    color: Color(0xFF2962FF), size: 18),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  meeting.time,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            meeting.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              height: 1.2,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.event_outlined,
                  size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text(
                dateFormat.format(meeting.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
                meeting.participants.length > 3
                    ? 3
                    : meeting.participants.length, (index) {
              return Transform.translate(
                offset: Offset(-12.0 * index, 0),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?u=${meeting.participants[index]}'),
                ),
              );
            }),
          )
        ],
      ),
    );
  }
}

// =================================================================
// NOTEBOOK CARD WIDGET
// =================================================================
class NotebookCard extends StatelessWidget {
  final dynamic folder;
  final int index;

  const NotebookCard({
    super.key,
    required this.folder,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final folderColor = DashboardColors
        .notebookColors[index % DashboardColors.notebookColors.length];

    return InkWell(
      onTap: () => context.push('/notebook_detail/${folder['id']}'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: folderColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child:
                  Icon(Icons.description_rounded, size: 28, color: folderColor),
            ),
            const SizedBox(height: 16),
            Text(
              folder['name'] ?? 'Untitled',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              folder['description'] ?? 'No description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// ANIMATED GRADIENT FAB (SIRI MODERN STYLE)
// =================================================================
class AnimatedGradientFAB extends StatefulWidget {
  final AnimationController animationController;
  final Animation<double> rotationAnimation;
  final Animation<double> pulseAnimation;
  final VoidCallback onTap;
  final double bottomPadding;

  const AnimatedGradientFAB({
    super.key,
    required this.animationController,
    required this.rotationAnimation,
    required this.pulseAnimation,
    required this.onTap,
    this.bottomPadding = 0,
  });

  @override
  State<AnimatedGradientFAB> createState() => _AnimatedGradientFABState();
}

class _AnimatedGradientFABState extends State<AnimatedGradientFAB>
    with TickerProviderStateMixin {
  late AnimationController _energyController;
  late AnimationController _breatheController;
  late AnimationController _shockwaveController;

  @override
  void initState() {
    super.initState();

    _energyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _shockwaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..value = 0.0;
  }

  @override
  void dispose() {
    _energyController.dispose();
    _breatheController.dispose();
    _shockwaveController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _shockwaveController.forward(from: 0.0);
  }

  void _handleTapUp(TapUpDetails details) {
    widget.onTap();
  }

  void _handleTapCancel() {
    _shockwaveController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: widget.bottomPadding + 16.0, right: 16.0),
      child: AnimatedBuilder(
        animation: Listenable.merge(
            [_energyController, _breatheController, _shockwaveController]),
        builder: (context, child) {
          final double rotation = _energyController.value * 2 * math.pi;
          final double breatheScale =
              1.0 + (math.sin(_breatheController.value * math.pi) * 0.02);
          final double tapScale =
              Curves.elasticOut.transform(_shockwaveController.value) * 0.15;

          final double totalGlassScale = breatheScale + tapScale;

          final double waveRadius = 36.0 + (_shockwaveController.value * 60.0);
          final double waveOpacity =
              1.0 - Curves.easeOutCirc.transform(_shockwaveController.value);

          return GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // --- LỚP 1: SÓNG NỔ (SHOCKWAVE) ---
                  if (_shockwaveController.value > 0.01)
                    Container(
                      width: waveRadius * 2,
                      height: waveRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1 * waveOpacity),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3 * waveOpacity),
                          width: 1,
                        ),
                      ),
                    ),

                  // --- LỚP 2: ÁO NĂNG LƯỢNG (GLOW) ---
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5856D6).withOpacity(0.6),
                          blurRadius: 25 + (_shockwaveController.value * 10),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.4),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                  ),

                  // --- LỚP 3: VỎ KÍNH CHỨA NĂNG LƯỢNG (GLASS CONTAINER) ---
                  Transform.scale(
                    scale: totalGlassScale,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: const [
                            Color(0xFF007AFF), // Blue
                            Color(0xFF5AC8FA), // Cyan
                            Color(0xFFFF2D55), // Pink
                            Color(0xFF5856D6), // Purple
                            Color(0xFF007AFF), // Blue
                          ],
                          transform: GradientRotation(rotation),
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        // --- LỚP 4: LỚP PHẢN CHIẾU ÁNH SÁNG (SPECULAR HIGHLIGHT) ---
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: const Alignment(-0.3, -0.3),
                                radius: 1.5,
                                colors: [
                                  Colors.white.withOpacity(0.4), // Highlight
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
