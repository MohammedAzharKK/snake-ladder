import 'game_models.dart';
import 'power_up.dart';

class GameBoard {
  // Standard 10x10 board with 100 cells (1-100)
  static const int boardSize = 10;
  static const int totalCells = boardSize * boardSize;

  // List of players
  final List<Player> players;

  // Current player index
  int currentPlayerIndex = 0;

  // Game state
  bool gameOver = false;
  bool skipNextPlayerChange = false; // For extra turn power-up

  // Battle mode state
  List<Player> frozenPlayers = []; // Players who skip their next turn
  List<Player> confusedPlayers = []; // Players who move in reverse on next turn
  List<int> trapPositions = []; // Positions with traps

  // Dice for the game
  final Dice dice = Dice();

  // Power-up cells - positions where players can get power-ups
  final List<int> powerUpCells = [];

  // Board elements (snakes and ladders)
  final List<BoardElement> boardElements = [
    // Ladders (start, end)
    BoardElement(1, 38),
    BoardElement(4, 14),
    BoardElement(9, 31),
    BoardElement(21, 42),
    BoardElement(28, 84),
    BoardElement(51, 67),
    BoardElement(72, 91),
    BoardElement(80, 99),

    // Snakes (start, end)
    BoardElement(17, 7),
    BoardElement(54, 34),
    BoardElement(62, 19),
    BoardElement(64, 60),
    BoardElement(87, 36),
    BoardElement(93, 73),
    BoardElement(95, 75),
    BoardElement(98, 79),
  ];

  GameBoard({required this.players}) {
    // Initialize all players at position 1
    for (var player in players) {
      player.position = 1;
      player.isWinner = false;
      player.hasShield = false;
    }

    // Setup power-up cells
    setupPowerUpCells();
  }

  // Factory constructor for challenge mode (more snakes, fewer ladders)
  factory GameBoard.challenge({required List<Player> players}) {
    final board = GameBoard(players: players);

    // Clear default elements and add custom ones for challenge mode
    board.boardElements.clear();

    // Ladders (fewer)
    board.boardElements.add(BoardElement(4, 14));
    board.boardElements.add(BoardElement(21, 42));
    board.boardElements.add(BoardElement(51, 67));

    // Snakes (more)
    board.boardElements.add(BoardElement(17, 7));
    board.boardElements.add(BoardElement(54, 34));
    board.boardElements.add(BoardElement(62, 19));
    board.boardElements.add(BoardElement(64, 60));
    board.boardElements.add(BoardElement(87, 36));
    board.boardElements.add(BoardElement(93, 73));
    board.boardElements.add(BoardElement(95, 75));
    board.boardElements.add(BoardElement(98, 79));
    board.boardElements.add(BoardElement(80, 44));
    board.boardElements.add(BoardElement(73, 12));

    // Add more power-up cells for challenge mode
    board.powerUpCells.clear();
    board.setupPowerUpCells(density: 0.15); // 15% of cells have power-ups

    return board;
  }

  // Get current player
  Player get currentPlayer => players[currentPlayerIndex];

  // Roll dice and move current player
  Future<int> rollAndMove() async {
    if (gameOver) return 0;

    // Roll the dice
    final steps = await dice.rollWithAnimation();

    // Check if player is confused (Battle Mode)
    final isConfused = confusedPlayers.contains(currentPlayer);
    if (isConfused) {
      confusedPlayers.remove(currentPlayer);
    }

    // Calculate target position (reverse direction if confused)
    int targetPosition = isConfused
        ? currentPlayer.position - steps
        : currentPlayer.position + steps;

    // Ensure position is within bounds
    if (isConfused) {
      targetPosition = targetPosition < 1 ? 1 : targetPosition;
    } else {
      targetPosition =
          targetPosition > totalCells ? totalCells : targetPosition;
    }

    // Move the player step by step
    final startPosition = currentPlayer.position;
    final direction = isConfused ? -1 : 1;

    for (int i = 1; i <= steps; i++) {
      final newPosition = startPosition + (i * direction);
      if (newPosition >= 1 && newPosition <= totalCells) {
        currentPlayer.moveTo(newPosition);
        await Future.delayed(
            const Duration(milliseconds: 300)); // Animation delay
      }
    }

    // Check for snakes and ladders with path-based movement
    await _moveAlongBoardElement();

    // Check for win condition
    if (currentPlayer.position == totalCells) {
      currentPlayer.isWinner = true;
      gameOver = true;
    }

    // Move to next player if game is not over
    if (!gameOver) {
      nextPlayer();
    }

    return steps;
  }

  // Move player along a snake or ladder path
  Future<void> _moveAlongBoardElement() async {
    for (var element in boardElements) {
      if (element.start == currentPlayer.position) {
        // If it's a snake and player has shield, use the shield instead of moving
        if (!element.isLadder && currentPlayer.hasShield) {
          currentPlayer.hasShield = false;
          break;
        }

        // Calculate the path points for the element
        final startPos = GameBoard.positionToCoordinates(element.start);
        final endPos = GameBoard.positionToCoordinates(element.end);
        final pathPoints =
            _calculatePathPoints(startPos, endPos, element.isLadder);

        // Move along the path
        for (var point in pathPoints) {
          final position = GameBoard.coordinatesToPosition(point);
          currentPlayer.moveTo(position);
          await Future.delayed(const Duration(
              milliseconds: 200)); // Faster animation for snakes/ladders
        }
        break;
      }
    }
  }

  // Calculate intermediate points for snake or ladder path
  List<Position> _calculatePathPoints(
      Position start, Position end, bool isLadder) {
    final points = <Position>[];
    final steps = 10; // Number of intermediate points

    if (isLadder) {
      // Ladder: straight line with slight curve
      for (int i = 1; i < steps; i++) {
        final t = i / steps;
        final x =
            start.x.toDouble() + (end.x.toDouble() - start.x.toDouble()) * t;
        final y =
            start.y.toDouble() + (end.y.toDouble() - start.y.toDouble()) * t;
        points.add(Position(x.round(), y.round()));
      }
    } else {
      // Snake: curved path
      final midX = (start.x.toDouble() + end.x.toDouble()) / 2;
      final midY = (start.y.toDouble() + end.y.toDouble()) / 2;
      final controlX1 = midX + (end.y.toDouble() - start.y.toDouble()) * 0.3;
      final controlY1 = midY - (end.x.toDouble() - start.x.toDouble()) * 0.3;
      final controlX2 = midX - (end.y.toDouble() - start.y.toDouble()) * 0.3;
      final controlY2 = midY + (end.x.toDouble() - start.x.toDouble()) * 0.3;

      for (int i = 1; i < steps; i++) {
        final t = i / steps;
        final x = _cubicBezierPoint(
            t, start.x.toDouble(), controlX1, controlX2, end.x.toDouble());
        final y = _cubicBezierPoint(
            t, start.y.toDouble(), controlY1, controlY2, end.y.toDouble());
        points.add(Position(x.round(), y.round()));
      }
    }

    return points;
  }

  // Calculate point on cubic bezier curve
  double _cubicBezierPoint(
      double t, double p0, double p1, double p2, double p3) {
    final oneMinusT = 1 - t;
    return oneMinusT * oneMinusT * oneMinusT * p0 +
        3 * oneMinusT * oneMinusT * t * p1 +
        3 * oneMinusT * t * t * p2 +
        t * t * t * p3;
  }

  // Check if player landed on a snake or ladder
  void checkBoardElements({Player? player}) {
    // Use provided player or current player
    final targetPlayer = player ?? currentPlayer;

    // Check for snakes and ladders
    for (var element in boardElements) {
      if (element.start == targetPlayer.position) {
        // If it's a snake and player has shield, use the shield instead of moving
        if (!element.isLadder && targetPlayer.hasShield) {
          targetPlayer.hasShield = false;
          break;
        }
        targetPlayer.moveTo(element.end);
        break;
      }
    }

    // Check for power-up cells
    if (powerUpCells.contains(targetPlayer.position)) {
      // 40% chance to get a power-up when landing on a power-up cell
      if ((DateTime.now().millisecondsSinceEpoch % 10) < 4) {
        final availablePowerUps = PowerUp.getAllPowerUps();
        final randomIndex =
            DateTime.now().millisecondsSinceEpoch % availablePowerUps.length;
        targetPlayer.addPowerUp(availablePowerUps[randomIndex]);
      }
    }

    // Check for trap positions (Battle Mode)
    if (trapPositions.contains(targetPlayer.position)) {
      // Move player back 3 spaces if they land on a trap
      final newPosition = targetPlayer.position - 3;
      if (newPosition >= 1) {
        targetPlayer.moveTo(newPosition);
      }
      // Remove the trap after it's triggered
      trapPositions.remove(targetPlayer.position + 3);
    }
  }

  // Move to next player
  void nextPlayer() {
    if (skipNextPlayerChange) {
      skipNextPlayerChange = false;
      return;
    }

    // Move to next player
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;

    // Check if next player is frozen (Battle Mode)
    if (frozenPlayers.contains(currentPlayer)) {
      frozenPlayers.remove(currentPlayer);
      // Skip this player's turn
      nextPlayer();
    }
  }

  // Setup power-up cells on the board
  void setupPowerUpCells({double density = 0.1}) {
    powerUpCells.clear();

    // Determine how many power-up cells to create (default 10% of board)
    final numberOfPowerUps = (totalCells * density).round();

    // Create a list of possible positions (exclude start, end, and snake/ladder positions)
    final List<int> possiblePositions = [];
    for (int i = 2; i < totalCells; i++) {
      bool isSpecialCell = false;

      // Check if position is already a snake or ladder
      for (var element in boardElements) {
        if (element.start == i || element.end == i) {
          isSpecialCell = true;
          break;
        }
      }

      if (!isSpecialCell) {
        possiblePositions.add(i);
      }
    }

    // Randomly select positions for power-ups
    if (possiblePositions.length > numberOfPowerUps) {
      possiblePositions.shuffle();
      for (int i = 0; i < numberOfPowerUps; i++) {
        powerUpCells.add(possiblePositions[i]);
      }
    }
  }

  // Reset the game
  void resetGame() {
    // Reset battle mode state
    frozenPlayers.clear();
    confusedPlayers.clear();
    trapPositions.clear();

    for (var player in players) {
      player.position = 1;
      player.isWinner = false;
      player.hasShield = false;
      player.powerUps.clear();
    }
    currentPlayerIndex = 0;
    gameOver = false;
    skipNextPlayerChange = false;

    // Reset power-up cells
    setupPowerUpCells();
  }

  // Convert board position (1-100) to x,y coordinates (0-9, 0-9)
  // This is useful for rendering the board
  static Position positionToCoordinates(int position) {
    position = position.clamp(1, totalCells) - 1; // Convert to 0-99

    final int row = 9 - (position ~/ 10); // Rows go from bottom to top (0-9)
    int col;

    // Handle snake pattern (alternate left-to-right and right-to-left rows)
    if (row % 2 == 0) {
      // Even rows go left to right
      col = position % 10;
    } else {
      // Odd rows go right to left
      col = 9 - (position % 10);
    }

    return Position(col, row);
  }

  // Convert coordinates to board position
  static int coordinatesToPosition(Position pos) {
    final int row = 9 - pos.y;
    int position;

    if (row % 2 == 0) {
      // Even rows go left to right
      position = (row * 10) + pos.x + 1;
    } else {
      // Odd rows go right to left
      position = (row * 10) + (9 - pos.x) + 1;
    }

    return position.clamp(1, totalCells);
  }
}
