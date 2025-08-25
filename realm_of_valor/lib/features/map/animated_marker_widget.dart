import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/quest_model.dart';

class AnimatedMarkerWidget extends StatefulWidget {
  final Quest quest;
  final VoidCallback? onTap;
  final bool isSelected;

  const AnimatedMarkerWidget({
    super.key,
    required this.quest,
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<AnimatedMarkerWidget> createState() => _AnimatedMarkerWidgetState();
}

class _AnimatedMarkerWidgetState extends State<AnimatedMarkerWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _bounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _startAnimations();
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
    
    if (widget.isSelected) {
      _bounceController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedMarkerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _bounceController.forward();
        HapticFeedback.lightImpact();
      } else {
        _bounceController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _glowController, _bounceController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value * _bounceAnimation.value,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getQuestColor().withOpacity(0.8),
                border: Border.all(
                  color: _getQuestColor(),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getQuestColor().withOpacity(_glowAnimation.value * 0.6),
                    blurRadius: 10 + (_glowAnimation.value * 10),
                    spreadRadius: 2 + (_glowAnimation.value * 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _getQuestIcon(),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getQuestColor() {
    switch (widget.quest.type) {
      case QuestType.battle:
        return Colors.red;
      case QuestType.treasure:
        return Colors.blue;
      case QuestType.location:
        return Colors.green;
      case QuestType.story:
        return Colors.purple;
      case QuestType.fitness:
        return Colors.orange;
      case QuestType.social:
        return Colors.cyan;
      case QuestType.daily:
        return Colors.yellow;
      case QuestType.weekly:
        return Colors.indigo;
    }
  }

  IconData _getQuestIcon() {
    switch (widget.quest.type) {
      case QuestType.battle:
        return Icons.sword;
      case QuestType.treasure:
        return Icons.chest;
      case QuestType.location:
        return Icons.explore;
      case QuestType.story:
        return Icons.book;
      case QuestType.fitness:
        return Icons.fitness_center;
      case QuestType.social:
        return Icons.people;
      case QuestType.daily:
        return Icons.today;
      case QuestType.weekly:
        return Icons.calendar_view_week;
    }
  }
}

class QuestMarkerPainter extends CustomPainter {
  final Quest quest;
  final bool isSelected;
  final double pulseValue;
  final double glowValue;

  QuestMarkerPainter({
    required this.quest,
    this.isSelected = false,
    this.pulseValue = 1.0,
    this.glowValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 20.0 * pulseValue;

    // Draw glow
    if (glowValue > 0) {
      final glowPaint = Paint()
        ..color = _getQuestColor().withOpacity(glowValue * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
      canvas.drawCircle(center, radius + 5, glowPaint);
    }

    // Draw main circle
    final mainPaint = Paint()
      ..color = _getQuestColor()
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, mainPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    canvas.drawCircle(center, radius, borderPaint);

    // Draw icon
    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    _drawIcon(canvas, center, iconPaint);
  }

  void _drawIcon(Canvas canvas, Offset center, Paint paint) {
    // Simplified icon drawing - in practice, you'd use a proper icon font
    final textPainter = TextPainter(
      text: TextSpan(
        text: _getQuestIconText(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  String _getQuestIconText() {
    switch (quest.type) {
      case QuestType.battle:
        return '⚔️';
      case QuestType.treasure:
        return '💎';
      case QuestType.location:
        return '🗺️';
      case QuestType.story:
        return '📖';
      case QuestType.fitness:
        return '💪';
      case QuestType.social:
        return '👥';
      case QuestType.daily:
        return '📅';
      case QuestType.weekly:
        return '📆';
    }
  }

  Color _getQuestColor() {
    switch (quest.type) {
      case QuestType.battle:
        return Colors.red;
      case QuestType.treasure:
        return Colors.blue;
      case QuestType.location:
        return Colors.green;
      case QuestType.story:
        return Colors.purple;
      case QuestType.fitness:
        return Colors.orange;
      case QuestType.social:
        return Colors.cyan;
      case QuestType.daily:
        return Colors.yellow;
      case QuestType.weekly:
        return Colors.indigo;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}