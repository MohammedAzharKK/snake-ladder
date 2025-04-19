import 'package:flutter/material.dart';

import 'game_board.dart';
import 'game_models.dart';

// Enum to define different types of battle power-ups
enum BattlePowerUpType {
  freeze, // Skip opponent's next turn
  reverse, // Move opponent backward
  magnet, // Pull opponent to your position
  catapult, // Launch yourself forward
  confusion, // Opponent moves in reverse direction on next turn
  trap, // Place a trap on the board that affects any player who lands on it
}

// Class to represent a battle power-up in the game
class BattlePowerUp {
  final BattlePowerUpType type;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const BattlePowerUp({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  // Apply the battle power-up effect to the game
  void apply(GameBoard gameBoard, {required Player targetPlayer}) {
    final currentPlayer = gameBoard.currentPlayer;

    switch (type) {
      case BattlePowerUpType.freeze:
        // Target player skips their next turn
        gameBoard.frozenPlayers.add(targetPlayer);
        break;

      case BattlePowerUpType.reverse:
        // Move target player backward 1-6 spaces
        final steps = 1 + (DateTime.now().millisecondsSinceEpoch % 6);
        final newPosition = targetPlayer.position - steps;
        if (newPosition >= 1) {
          targetPlayer.moveTo(newPosition);
          gameBoard.checkBoardElements(player: targetPlayer);
        }
        break;

      case BattlePowerUpType.magnet:
        // Pull target player to current player's position
        targetPlayer.moveTo(currentPlayer.position);
        break;

      case BattlePowerUpType.catapult:
        // Launch current player forward 5-10 spaces
        final boost = 5 + (DateTime.now().millisecondsSinceEpoch % 6);
        final newPosition = currentPlayer.position + boost;
        if (newPosition <= GameBoard.totalCells) {
          currentPlayer.moveTo(newPosition);
          gameBoard.checkBoardElements();

          // Check for win condition
          if (currentPlayer.position == GameBoard.totalCells) {
            currentPlayer.isWinner = true;
            gameBoard.gameOver = true;
          }
        }
        break;

      case BattlePowerUpType.confusion:
        // Target player moves in reverse direction on next turn
        gameBoard.confusedPlayers.add(targetPlayer);
        break;

      case BattlePowerUpType.trap:
        // Place a trap on the current player's position
        // Any player who lands on this position will move back 3 spaces
        if (!gameBoard.trapPositions.contains(currentPlayer.position)) {
          gameBoard.trapPositions.add(currentPlayer.position);
        }
        break;
    }
  }

  // Get a list of all available battle power-ups
  static List<BattlePowerUp> getAllBattlePowerUps() {
    return [
      const BattlePowerUp(
        type: BattlePowerUpType.freeze,
        name: 'Freeze',
        description: 'Skip opponent\'s next turn',
        icon: Icons.ac_unit,
        color: Colors.lightBlue,
      ),
      const BattlePowerUp(
        type: BattlePowerUpType.reverse,
        name: 'Reverse',
        description: 'Move opponent backward',
        icon: Icons.arrow_back,
        color: Colors.red,
      ),
      const BattlePowerUp(
        type: BattlePowerUpType.magnet,
        name: 'Magnet',
        description: 'Pull opponent to your position',
        icon: Icons.margin_outlined,
        color: Colors.deepPurple,
      ),
      const BattlePowerUp(
        type: BattlePowerUpType.catapult,
        name: 'Catapult',
        description: 'Launch yourself forward',
        icon: Icons.flight_takeoff,
        color: Colors.orange,
      ),
      const BattlePowerUp(
        type: BattlePowerUpType.confusion,
        name: 'Confusion',
        description: 'Opponent moves in reverse on next turn',
        icon: Icons.psychology,
        color: Colors.teal,
      ),
      const BattlePowerUp(
        type: BattlePowerUpType.trap,
        name: 'Trap',
        description: 'Place a trap on the board',
        icon: Icons.warning,
        color: Colors.amber,
      ),
    ];
  }
}
