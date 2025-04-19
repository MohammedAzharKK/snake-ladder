import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_board.dart';

class GameBoardWidget extends StatelessWidget {
  final GameBoard gameBoard;
  final double size;

  const GameBoardWidget({
    super.key,
    required this.gameBoard,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final cellSize = size / GameBoard.boardSize;
    final borderRadius = cellSize * 0.2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.brown.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.brown.shade800, width: 2),
      ),
      child: Stack(
        children: [
          // Draw the board cells
          ...List.generate(
            GameBoard.totalCells,
            (index) {
              final row =
                  GameBoard.boardSize - 1 - (index ~/ GameBoard.boardSize);
              final col = (row % 2 == 0)
                  ? index % GameBoard.boardSize
                  : GameBoard.boardSize - 1 - (index % GameBoard.boardSize);
              final cellNumber = index + 1;

              return Positioned(
                left: col * cellSize,
                top: row * cellSize,
                child: _buildCell(
                  cellNumber,
                  cellSize,
                  borderRadius,
                  gameBoard.powerUpCells.contains(cellNumber),
                ),
              );
            },
          ),

          // Draw snakes and ladders
          ...gameBoard.boardElements.map((element) {
            final startRow = GameBoard.boardSize -
                1 -
                ((element.start - 1) ~/ GameBoard.boardSize);
            final startCol = (startRow % 2 == 0)
                ? (element.start - 1) % GameBoard.boardSize
                : GameBoard.boardSize -
                    1 -
                    ((element.start - 1) % GameBoard.boardSize);
            final endRow = GameBoard.boardSize -
                1 -
                ((element.end - 1) ~/ GameBoard.boardSize);
            final endCol = (endRow % 2 == 0)
                ? (element.end - 1) % GameBoard.boardSize
                : GameBoard.boardSize -
                    1 -
                    ((element.end - 1) % GameBoard.boardSize);

            return CustomPaint(
              size: Size(size, size),
              painter: BoardElementPainter(
                startX: (startCol + 0.5) * cellSize,
                startY: (startRow + 0.5) * cellSize,
                endX: (endCol + 0.5) * cellSize,
                endY: (endRow + 0.5) * cellSize,
                isLadder: element.isLadder,
                cellSize: cellSize,
              ),
            );
          }),

          // Draw players
          ...gameBoard.players.map((player) {
            final row = GameBoard.boardSize -
                1 -
                ((player.position - 1) ~/ GameBoard.boardSize);
            final col = (row % 2 == 0)
                ? (player.position - 1) % GameBoard.boardSize
                : GameBoard.boardSize -
                    1 -
                    ((player.position - 1) % GameBoard.boardSize);

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              left: col * cellSize + (cellSize - cellSize * 0.4) / 2,
              top: row * cellSize + (cellSize - cellSize * 0.4) / 2,
              child: Container(
                width: cellSize * 0.4,
                height: cellSize * 0.4,
                decoration: BoxDecoration(
                  color: player.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: player == gameBoard.currentPlayer
                        ? Colors.yellow
                        : Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCell(
    int number,
    double size,
    double borderRadius,
    bool hasPowerUp,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getCellColor(number),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.brown.shade400),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                fontSize: size * 0.3,
                fontWeight: FontWeight.bold,
                color: _getTextColor(number),
              ),
            ),
          ),
          if (hasPowerUp)
            Positioned(
              right: size * 0.1,
              bottom: size * 0.1,
              child: Icon(
                Icons.star,
                size: size * 0.3,
                color: Colors.yellow.shade700,
              ),
            ),
        ],
      ),
    );
  }

  Color _getCellColor(int number) {
    final row = (number - 1) ~/ GameBoard.boardSize;
    return (row + (number % 2)) % 2 == 0
        ? Colors.brown.shade100
        : Colors.brown.shade300;
  }

  Color _getTextColor(int number) {
    return _getCellColor(number) == Colors.brown.shade100
        ? Colors.brown.shade800
        : Colors.brown.shade900;
  }
}

class BoardElementPainter extends CustomPainter {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final bool isLadder;
  final double cellSize;

  BoardElementPainter({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.isLadder,
    required this.cellSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isLadder ? Colors.green : Colors.red
      ..strokeWidth = cellSize * 0.1
      ..style = PaintingStyle.stroke;

    if (isLadder) {
      _drawLadder(canvas, paint);
    } else {
      _drawSnake(canvas, paint);
    }
  }

  void _drawLadder(Canvas canvas, Paint paint) {
    // Draw main ladder poles
    final dx = endX - startX;
    final dy = endY - startY;
    final distance = math.sqrt(dx * dx + dy * dy);
    final angle = math.atan2(dy, dx);
    final perpX = math.cos(angle + math.pi / 2);
    final perpY = math.sin(angle + math.pi / 2);
    final poleOffset = cellSize * 0.2;

    // Left pole
    canvas.drawLine(
      Offset(startX - perpX * poleOffset, startY - perpY * poleOffset),
      Offset(endX - perpX * poleOffset, endY - perpY * poleOffset),
      paint,
    );

    // Right pole
    canvas.drawLine(
      Offset(startX + perpX * poleOffset, startY + perpY * poleOffset),
      Offset(endX + perpX * poleOffset, endY + perpY * poleOffset),
      paint,
    );

    // Draw rungs
    final rungCount = (distance / (cellSize * 0.5)).round();
    for (int i = 1; i < rungCount; i++) {
      final t = i / rungCount;
      final x = startX + dx * t;
      final y = startY + dy * t;

      canvas.drawLine(
        Offset(x - perpX * poleOffset, y - perpY * poleOffset),
        Offset(x + perpX * poleOffset, y + perpY * poleOffset),
        paint,
      );
    }

    // Draw ladder top and bottom
    final topPaint = Paint()
      ..color = Colors.green.shade700
      ..style = PaintingStyle.fill;
    final bottomPaint = Paint()
      ..color = Colors.green.shade900
      ..style = PaintingStyle.fill;

    // Top platform
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(endX, endY),
        width: cellSize * 0.4,
        height: cellSize * 0.2,
      ),
      topPaint,
    );

    // Bottom platform
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(startX, startY),
        width: cellSize * 0.4,
        height: cellSize * 0.2,
      ),
      bottomPaint,
    );
  }

  void _drawSnake(Canvas canvas, Paint paint) {
    final path = Path();
    path.moveTo(startX, startY);

    // Calculate control points for the curve
    final dx = endX - startX;
    final dy = endY - startY;
    final midX = startX + dx * 0.5;
    final midY = startY + dy * 0.5;

    // Add some curvature to the snake
    final controlX1 = midX + dy * 0.3;
    final controlY1 = midY - dx * 0.3;
    final controlX2 = midX - dy * 0.3;
    final controlY2 = midY + dx * 0.3;

    path.cubicTo(
      controlX1,
      controlY1,
      controlX2,
      controlY2,
      endX,
      endY,
    );

    // Draw snake body
    canvas.drawPath(path, paint);

    // Draw snake head
    final headPaint = Paint()
      ..color = Colors.red.shade900
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(startX, startY),
      cellSize * 0.15,
      headPaint,
    );

    // Draw snake eyes
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final angle = math.atan2(dy, dx);
    final eyeOffset = cellSize * 0.1;
    final eyeX = startX + math.cos(angle) * eyeOffset;
    final eyeY = startY + math.sin(angle) * eyeOffset;

    canvas.drawCircle(
      Offset(eyeX - math.sin(angle) * eyeOffset * 0.5,
          eyeY + math.cos(angle) * eyeOffset * 0.5),
      cellSize * 0.03,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(eyeX + math.sin(angle) * eyeOffset * 0.5,
          eyeY - math.cos(angle) * eyeOffset * 0.5),
      cellSize * 0.03,
      eyePaint,
    );

    // Draw snake tongue
    final tonguePaint = Paint()
      ..color = Colors.red.shade300
      ..strokeWidth = cellSize * 0.02
      ..style = PaintingStyle.stroke;

    final tongueLength = cellSize * 0.2;
    final tongueX = startX + math.cos(angle) * tongueLength;
    final tongueY = startY + math.sin(angle) * tongueLength;

    canvas.drawLine(
      Offset(startX, startY),
      Offset(tongueX, tongueY),
      tonguePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Import for math functions
