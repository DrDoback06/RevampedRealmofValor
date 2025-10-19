import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 3D-style dice roller component for RNG events in battle
class DiceRoller extends StatefulWidget {
  final int sides; // 6, 10, 20, etc.
  final Function(int) onRollComplete;
  final String? seed; // Optional seed for deterministic rolls
  final bool autoRoll;

  const DiceRoller({
    super.key,
    this.sides = 6,
    required this.onRollComplete,
    this.seed,
    this.autoRoll = false,
  });

  @override
  State<DiceRoller> createState() => _DiceRollerState();
}

class _DiceRollerState extends State<DiceRoller> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int? _result;
  bool _isRolling = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.autoRoll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => roll());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void roll() {
    if (_isRolling) return;

    setState(() {
      _isRolling = true;
      _result = null;
    });

    _controller.forward(from: 0).then((_) {
      final random = widget.seed != null
          ? math.Random(widget.seed.hashCode)
          : math.Random();
      final result = random.nextInt(widget.sides) + 1;

      setState(() {
        _result = result;
        _isRolling = false;
      });

      widget.onRollComplete(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isRolling ? null : roll,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final rotation = _controller.value * 4 * math.pi;
          
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(rotation)
              ..rotateY(rotation * 0.7)
              ..rotateZ(rotation * 0.5),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isRolling ? Colors.white : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(color: Colors.grey[800]!, width: 2),
              ),
              child: Center(
                child: _isRolling
                    ? const Text(
                        '?',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      )
                    : Text(
                        _result?.toString() ?? '?',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Dice roller dialog for battle events
class DiceRollerDialog extends StatelessWidget {
  final int sides;
  final String reason;
  final String? seed;

  const DiceRollerDialog({
    super.key,
    this.sides = 20,
    required this.reason,
    this.seed,
  });

  static Future<int?> show(BuildContext context, {
    required String reason,
    int sides = 20,
    String? seed,
  }) {
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DiceRollerDialog(
        sides: sides,
        reason: reason,
        seed: seed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.purple, width: 2),
      ),
      title: Text(
        reason,
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DiceRoller(
            sides: sides,
            autoRoll: true,
            seed: seed,
            onRollComplete: (result) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (context.mounted) {
                  Navigator.of(context).pop(result);
                }
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Rolling d$sides...',
            style: const TextStyle(color: Colors.white70),
          ),
          if (seed != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Seed: ${seed!.substring(0, math.min(8, seed!.length))}...',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
