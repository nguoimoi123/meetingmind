import 'package:flutter/material.dart';
import 'dart:math' as math;

class MindmapScreen extends StatefulWidget {
  final Map<String, dynamic> graphData;
  final String title;

  const MindmapScreen({
    super.key,
    required this.graphData,
    required this.title,
  });

  @override
  State<MindmapScreen> createState() => _MindmapScreenState();
}

class _MindmapScreenState extends State<MindmapScreen> {
  Map<String, Offset> nodePositions = {};
  String? selectedNodeId;
  
  @override
  void initState() {
    super.initState();
    _calculateNodePositions();
  }

  void _calculateNodePositions() {
    final nodes = widget.graphData['nodes'] as List;
    final edges = widget.graphData['edges'] as List;
    
    if (nodes.isEmpty) return;
    
    // Tìm root node (level 0)
    final rootNode = nodes.firstWhere(
      (node) => node['level'] == 0,
      orElse: () => nodes.first,
    );
    
    // Center root node
    nodePositions[rootNode['id']] = const Offset(0, 0);
    
    // Build parent-child relationships
    final childrenMap = <String, List<dynamic>>{};
    for (var edge in edges) {
      final fromId = edge['from'];
      if (!childrenMap.containsKey(fromId)) {
        childrenMap[fromId] = [];
      }
      final childNode = nodes.firstWhere((n) => n['id'] == edge['to'], orElse: () => {});
      if (childNode is Map && childNode.isNotEmpty) {
        childrenMap[fromId]!.add(childNode);
      }
    }
    
    // Layout children in tree structure
    _layoutChildren(rootNode['id'], childrenMap, nodes, 0, 360, 200);
  }
  
  void _layoutChildren(
    String parentId,
    Map<String, List<dynamic>> childrenMap,
    List nodes,
    double startAngle,
    double angleRange,
    double radius,
  ) {
    final children = childrenMap[parentId] ?? [];
    if (children.isEmpty) return;
    
    final parentPos = nodePositions[parentId]!;
    final angleStep = angleRange / children.length;
    
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final angle = (startAngle + angleStep * i + angleStep / 2) * math.pi / 180;
      
      final x = parentPos.dx + radius * math.cos(angle);
      final y = parentPos.dy + radius * math.sin(angle);
      nodePositions[child['id']] = Offset(x, y);
      
      // Recursively layout grandchildren
      final childAngleStart = startAngle + angleStep * i;
      _layoutChildren(
        child['id'],
        childrenMap,
        nodes,
        childAngleStart,
        angleStep,
        radius * 0.7,
      );
    }
  }

  Color _getColorForLevel(int level) {
    const colors = [
      Color(0xFF6366F1), // Level 0 - Blue
      Color(0xFF00C6FF), // Level 1 - Cyan
      Color(0xFF10B981), // Level 2 - Green
      Color(0xFFF7971E), // Level 3 - Orange
      Color(0xFFEC4899), // Level 4 - Pink
    ];
    return colors[level % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nodes = widget.graphData['nodes'] as List;
    final edges = widget.graphData['edges'] as List;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showLegend();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ],
          ),
        ),
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.3,
          maxScale: 5.0,
          child: Center(
            child: CustomPaint(
              size: const Size(1200, 1200),
              painter: MindmapPainter(
                nodes: nodes,
                edges: edges,
                nodePositions: nodePositions,
                selectedNodeId: selectedNodeId,
                getColorForLevel: _getColorForLevel,
              ),
              child: GestureDetector(
                onTapDown: (details) {
                  final localPosition = details.localPosition - const Offset(600, 600);
                  
                  for (var node in nodes) {
                    final pos = nodePositions[node['id']]!;
                    final distance = (pos - localPosition).distance;
                    final level = node['level'] as int;
                    final nodeRadius = level == 0 ? 55.0 : 38.0;
                    
                    if (distance < nodeRadius) {
                      setState(() {
                        selectedNodeId = node['id'];
                      });
                      _showNodeDetails(node);
                      break;
                    }
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLegend() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.palette_outlined, color: colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Chú thích màu sắc'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem('Chủ đề chính', 0),
            _buildLegendItem('Nhánh cấp 1', 1),
            _buildLegendItem('Chi tiết cấp 2', 2),
            _buildLegendItem('Chi tiết cấp 3', 3),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int level) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getColorForLevel(level),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Text(label),
        ],
      ),
    );
  }

  void _showNodeDetails(Map<String, dynamic> node) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getColorForLevel(node['level']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: _getColorForLevel(node['level']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    node['label'],
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Cấp độ', 'Level ${node['level']}', colorScheme),
            _buildInfoRow('Loại', node['type'], colorScheme),
            _buildInfoRow('ID', node['id'], colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MindmapPainter extends CustomPainter {
  final List nodes;
  final List edges;
  final Map<String, Offset> nodePositions;
  final String? selectedNodeId;
  final Color Function(int) getColorForLevel;

  MindmapPainter({
    required this.nodes,
    required this.edges,
    required this.nodePositions,
    required this.selectedNodeId,
    required this.getColorForLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw edges first with curves
    for (var edge in edges) {
      final fromPos = nodePositions[edge['from']];
      final toPos = nodePositions[edge['to']];
      
      if (fromPos != null && toPos != null) {
        final start = center + fromPos;
        final end = center + toPos;
        
        final toNode = nodes.firstWhere((n) => n['id'] == edge['to']);
        final edgeColor = getColorForLevel(toNode['level']);
        
        // Draw curved line
        final path = Path();
        path.moveTo(start.dx, start.dy);
        
        // Calculate control point for curve
        final midX = (start.dx + end.dx) / 2;
        final midY = (start.dy + end.dy) / 2;
        final dx = end.dx - start.dx;
        final dy = end.dy - start.dy;
        final controlX = midX - dy * 0.2;
        final controlY = midY + dx * 0.2;
        
        path.quadraticBezierTo(controlX, controlY, end.dx, end.dy);
        
        final edgePaint = Paint()
          ..color = edgeColor.withOpacity(0.4)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        
        canvas.drawPath(path, edgePaint);
        
        // Draw arrow head
        _drawArrowHead(canvas, start, end, edgeColor);
        
        // Draw edge label
        if (edge['relation'] != null && edge['relation'].toString().isNotEmpty) {
          _drawEdgeLabel(canvas, midX, midY, edge['relation'], edgeColor);
        }
      }
    }

    // Draw nodes with shadows and gradients
    for (var node in nodes) {
      final pos = nodePositions[node['id']];
      if (pos == null) continue;
      
      final isSelected = node['id'] == selectedNodeId;
      final level = node['level'] as int;
      final color = getColorForLevel(level);
      
      final nodeRadius = isSelected ? 48.0 : (level == 0 ? 55.0 : 38.0);
      final nodeCenter = center + pos;
      
      // Draw shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(nodeCenter + const Offset(2, 4), nodeRadius, shadowPaint);
      
      // Draw gradient circle
      final gradient = RadialGradient(
        colors: [
          color,
          color.withOpacity(0.8),
        ],
      );
      
      final gradientPaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: nodeCenter, radius: nodeRadius),
        );
      canvas.drawCircle(nodeCenter, nodeRadius, gradientPaint);
      
      // Node border
      final borderPaint = Paint()
        ..color = isSelected ? Colors.white : Colors.white.withOpacity(0.3)
        ..strokeWidth = isSelected ? 4 : 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(nodeCenter, nodeRadius, borderPaint);
      
      // Node label with better formatting
      final textPainter = TextPainter(
        text: TextSpan(
          text: node['label'],
          style: TextStyle(
            color: Colors.white,
            fontSize: level == 0 ? 15 : 12,
            fontWeight: level == 0 ? FontWeight.bold : FontWeight.w600,
            height: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      textPainter.layout(maxWidth: nodeRadius * 2 - 12);
      textPainter.paint(
        canvas,
        nodeCenter - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end, Color color) {
    const arrowSize = 8.0;
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    
    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - arrowSize * math.cos(angle - math.pi / 6),
      end.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    arrowPath.lineTo(
      end.dx - arrowSize * math.cos(angle + math.pi / 6),
      end.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    arrowPath.close();
    
    final arrowPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(arrowPath, arrowPaint);
  }
  
  void _drawEdgeLabel(Canvas canvas, double x, double y, String label, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Draw background
    final bgRect = Rect.fromCenter(
      center: Offset(x, y),
      width: textPainter.width + 8,
      height: textPainter.height + 4,
    );
    
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      bgPaint,
    );
    
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerHighest.withOpacity(0.3),
            ],
          ),
        ),
        child: InteractiveViewer(
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.3,
          maxScale: 5.0,
          child: Center(
            child: CustomPaint(
              size: const Size(1200, 1200),
              painter: MindmapPainter(
                nodes: nodes,
                edges: edges,
                nodePositions: nodePositions,
                selectedNodeId: selectedNodeId,
                getColorForLevel: _getColorForLevel,
              ),
              child: GestureDetector(
                onTapDown: (details) {
                  // Detect node tap
                  final localPosition = details.localPosition - const Offset(600, 600);
                  
                  for (var node in nodes) {
                    final pos = nodePositions[node['id']]!;
                    final distance = (pos - localPosition).distance;
                    final level = node['level'] as int;
                    final nodeRadius = level == 0 ? 55.0 : 38.0;
                    
                    if (distance < nodeRadius) {
                      setState(() {
                        selectedNodeId = node['id'];
                      });
                      _showNodeDetails(node);
                      break;
                    }
                  }
                },
              ) }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showNodeDetails(Map<String, dynamic> node) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getColorForLevel(node['level']).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: _getColorForLevel(node['level']),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    node['label'],
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Cấp độ', 'Level ${node['level']}', colorScheme),
            _buildInfoRow('Loại', node['type'], colorScheme),
            _buildInfoRow('ID', node['id'], colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MindmapPainter extends CustomPainter {
  final List nodes;
  final List edges;
  final Map<String, Offset> nodePositions;
  final String? selectedNodeId;
  final Color Function(int) getColorForLevel;

  MindmapPainter({
    required this.nodes,
    required this.edges,
    required this.nodePositions,
    required this.selectedNodeId,
    required this.getColorForLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Draw edges first with curves
    for (var edge in edges) {
      final fromPos = nodePositions[edge['from']];
      final toPos = nodePositions[edge['to']];
      
      if (fromPos != null && toPos != null) {
        final start = center + fromPos;
        final end = center + toPos;
        
        // Get node colors for edge
        final fromNode = nodes.firstWhere((n) => n['id'] == edge['from']);
        final toNode = nodes.firstWhere((n) => n['id'] == edge['to']);
        final edgeColor = getColorForLevel(toNode['level']);
        
        // Draw curved line
        final path = Path();
        path.moveTo(start.dx, start.dy);
        
        // Calculate control point for curve
        final midX = (start.dx + end.dx) / 2;
        final midY = (start.dy + end.dy) / 2;
        final dx = end.dx - start.dx;
        final dy = end.dy - start.dy;
        final controlX = midX - dy * 0.2;
        final controlY = midY + dx * 0.2;
        
        path.quadraticBezierTo(controlX, controlY, end.dx, end.dy);
        
        final edgePaint = Paint()
          ..color = edgeColor.withOpacity(0.4)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        
        canvas.drawPath(path, edgePaint);
        
        // Draw arrow head
        _drawArrowHead(canvas, start, end, edgeColor);
        
        // Draw edge label
        if (edge['relation'] != null && edge['relation'].toString().isNotEmpty) {
          _drawEdgeLabel(canvas, midX, midY, edge['relation'], edgeColor);
        }
      }
    }

    // Draw nodes with shadows and gradients
    for (var node in nodes) {
      final pos = nodePositions[node['id']];
      if (pos == null) continue;
      
      final isSelected = node['id'] == selectedNodeId;
      final level = node['level'] as int;
      final color = getColorForLevel(level);
      
      final nodeRadius = isSelected ? 48.0 : (level == 0 ? 55.0 : 38.0);
      final nodeCenter = center + pos;
      
      // Draw shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(nodeCenter + const Offset(2, 4), nodeRadius, shadowPaint);
      
      // Draw gradient circle
      final gradient = RadialGradient(
        colors: [
          color,
          color.withOpacity(0.8),
        ],
      );
      
      final gradientPaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: nodeCenter, radius: nodeRadius),
        );
      canvas.drawCircle(nodeCenter, nodeRadius, gradientPaint);
      
      // Node border
      final borderPaint = Paint()
        ..color = isSelected ? Colors.white : Colors.white.withOpacity(0.3)
        ..strokeWidth = isSelected ? 4 : 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(nodeCenter, nodeRadius, borderPaint);
      
      // Node label with better formatting
      final textPainter = TextPainter(
        text: TextSpan(
          text: node['label'],
          style: TextStyle(
            color: Colors.white,
            fontSize: level == 0 ? 15 : 12,
            fontWeight: level == 0 ? FontWeight.bold : FontWeight.w600,
            height: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      textPainter.layout(maxWidth: nodeRadius * 2 - 12);
      textPainter.paint(
        canvas,
        nodeCenter
  void _drawEdgeLabel(Canvas canvas, double x, double y, String label, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          backgroundColor: Colors.white.withOpacity(0.9),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    // Draw background
    final bgRect = Rect.fromCenter(
      center: Offset(x, y),
      width: textPainter.width + 8,
      height: textPainter.height + 4,
    );
    
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      bgPaint,
    );
    
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }

          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(center + pos, nodeRadius, borderPaint);
      }
      
      // Node label
      final textPainter = TextPainter(
        text: TextSpan(
          text: node['label'],
          style: TextStyle(
            color: Colors.white,
            fontSize: level == 0 ? 14 : 11,
            fontWeight: level == 0 ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      textPainter.layout(maxWidth: nodeRadius * 2 - 8);
      textPainter.paint(
        canvas,
        center + pos - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
