import 'package:flutter/material.dart';

class DiceWidget extends StatelessWidget {
  final int value;
  final bool isRolling;
  final double size;
  final Color color;

  const DiceWidget({
    super.key,
    required this.value,
    required this.isRolling,
    this.size = 100.0,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(-2, -2),
          ),
        ],
        border: Border.all(
          color: Colors.black12,
          width: 2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade100,
          ],
        ),
      ),
      child: isRolling ? _buildRollingDice() : _buildDiceFace(value),
    );
  }

  Widget _buildRollingDice() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.casino,
            size: size * 0.5,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            'Rolling...',
            style: TextStyle(
              fontSize: size * 0.15,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiceFace(int value) {
    return Padding(
      padding: EdgeInsets.all(size * 0.1),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dotSize = size * 0.18;
          final spacing = size * 0.2;

          return Stack(
            children: [
              // Center dot (for odd numbers)
              if (value % 2 == 1)
                Positioned(
                  left: constraints.maxWidth / 2 - dotSize / 2,
                  top: constraints.maxHeight / 2 - dotSize / 2,
                  child: _buildDot(dotSize),
                ),

              // Top-left dot (for 2, 3, 4, 5, 6)
              if (value > 1)
                Positioned(
                  left: spacing,
                  top: spacing,
                  child: _buildDot(dotSize),
                ),

              // Top-right dot (for 4, 5, 6)
              if (value > 3)
                Positioned(
                  right: spacing,
                  top: spacing,
                  child: _buildDot(dotSize),
                ),

              // Bottom-left dot (for 4, 5, 6)
              if (value > 3)
                Positioned(
                  left: spacing,
                  bottom: spacing,
                  child: _buildDot(dotSize),
                ),

              // Bottom-right dot (for 2, 3, 4, 5, 6)
              if (value > 1)
                Positioned(
                  right: spacing,
                  bottom: spacing,
                  child: _buildDot(dotSize),
                ),

              // Middle-left dot (for 6)
              if (value == 6)
                Positioned(
                  left: spacing,
                  top: constraints.maxHeight / 2 - dotSize / 2,
                  child: _buildDot(dotSize),
                ),

              // Middle-right dot (for 6)
              if (value == 6)
                Positioned(
                  right: spacing,
                  top: constraints.maxHeight / 2 - dotSize / 2,
                  child: _buildDot(dotSize),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(-1, -1),
          ),
        ],
        gradient: RadialGradient(
          colors: [
            color,
            color.withOpacity(0.8),
          ],
          center: Alignment.topLeft,
          radius: 1.0,
        ),
      ),
    );
  }
}
