import 'package:flutter/material.dart';
import 'game_models.dart';
import 'game_board.dart';

// Enum to define different types of power-ups
enum PowerUpType {
  extraTurn,     // Player gets an extra turn
  speedBoost,    // Move forward extra spaces
  shield,        // Protection from one snake
  swapPosition,  // Swap position with another player
  teleport,      // Teleport to a random position
}

// Class to represent a power-up in the game
class PowerUp {
  final PowerUpType type;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  
  const PowerUp({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
  
  // Apply the power-up effect to the game
  void apply(GameBoard gameBoard, {Player? targetPlayer}) {
    final currentPlayer = gameBoard.currentPlayer;
    
    switch (type) {
      case PowerUpType.extraTurn:
        // Player gets another turn (don't change currentPlayerIndex)
        gameBoard.skipNextPlayerChange = true;
        break;
        
      case PowerUpType.speedBoost:
        // Move forward 1-3 extra spaces
        final extraSteps = (1 + (DateTime.now().millisecondsSinceEpoch % 3));
        final newPosition = currentPlayer.position + extraSteps;
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
        
      case PowerUpType.shield:
        // Protect from the next snake
        currentPlayer.hasShield = true;
        break;
        
      case PowerUpType.swapPosition:
        // Swap position with another player
        if (targetPlayer != null && targetPlayer != currentPlayer) {
          final tempPosition = currentPlayer.position;
          currentPlayer.moveTo(targetPlayer.position);
          targetPlayer.moveTo(tempPosition);
        }
        break;
        
      case PowerUpType.teleport:
        // Teleport to a random position between current and 100
        if (currentPlayer.position < GameBoard.totalCells - 1) {
          final maxJump = GameBoard.totalCells - currentPlayer.position;
          final jump = 1 + (DateTime.now().millisecondsSinceEpoch % maxJump.clamp(1, 20));
          currentPlayer.moveTo(currentPlayer.position + jump);
          gameBoard.checkBoardElements();
          
          // Check for win condition
          if (currentPlayer.position == GameBoard.totalCells) {
            currentPlayer.isWinner = true;
            gameBoard.gameOver = true;
          }
        }
        break;
    }
  }
  
  // Get a list of all available power-ups
  static List<PowerUp> getAllPowerUps() {
    return [
      const PowerUp(
        type: PowerUpType.extraTurn,
        name: 'Extra Turn',
        description: 'Roll the dice again!',
        icon: Icons.replay,
        color: Colors.purple,
      ),
      const PowerUp(
        type: PowerUpType.speedBoost,
        name: 'Speed Boost',
        description: 'Move 1-3 spaces forward',
        icon: Icons.flash_on,
        color: Colors.amber,
      ),
      const PowerUp(
        type: PowerUpType.shield,
        name: 'Snake Shield',
        description: 'Protection from one snake',
        icon: Icons.shield,
        color: Colors.blue,
      ),
      const PowerUp(
        type: PowerUpType.swapPosition,
        name: 'Position Swap',
        description: 'Swap position with another player',
        icon: Icons.swap_horiz,
        color: Colors.green,
      ),
      const PowerUp(
        type: PowerUpType.teleport,
        name: 'Teleport',
        description: 'Teleport forward to a random position',
        icon: Icons.bolt,
        color: Colors.deepOrange,
      ),
    ];
  }
}