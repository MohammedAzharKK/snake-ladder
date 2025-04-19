import 'dart:async';

import 'package:flutter/material.dart';

import '../models/game_board.dart';
import '../models/game_models.dart';
import '../models/power_up.dart';
import '../widgets/dice_widget.dart';
import '../widgets/game_board_widget.dart';

class GameScreen extends StatefulWidget {
  final GameMode gameMode;

  const GameScreen({super.key, this.gameMode = GameMode.classic});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late GameBoard gameBoard;
  bool isRolling = false;
  int lastRoll = 0;
  String message = 'Tap the dice to roll';

  // Timer for Time Attack mode
  int? remainingSeconds;
  Timer? gameTimer;

  // Animation controller for dice
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize players
    final players = [
      Player('Player 1', Colors.red),
      Player('Player 2', Colors.blue),
    ];

    // Initialize game board based on game mode
    switch (widget.gameMode) {
      case GameMode.classic:
        gameBoard = GameBoard(players: players);
        message = 'Classic Mode: Tap the dice to roll';
        break;
      case GameMode.timeAttack:
        gameBoard = GameBoard(players: players);
        remainingSeconds = 60; // 60 seconds time limit
        message = 'Time Attack: You have 60 seconds!';
        _startTimer();
        break;
      case GameMode.challenge:
        // Create a more challenging board with more snakes and fewer ladders
        gameBoard = GameBoard.challenge(players: players);
        message = 'Challenge Mode: Watch out for snakes!';
        break;
      case GameMode.powerUp:
        // Create a board with power-ups
        gameBoard = GameBoard(players: players);
        gameBoard.setupPowerUpCells(
            density: 0.15); // 15% of cells have power-ups
        message = 'Power-Up Mode: Collect and use power-ups!';
        break;
    }

    // Setup animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    gameTimer?.cancel();
    super.dispose();
  }

  // Start timer for Time Attack mode
  void _startTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds! > 0) {
          remainingSeconds = remainingSeconds! - 1;
        } else {
          // Time's up
          gameTimer?.cancel();
          gameBoard.gameOver = true;
          message = 'Time\'s up! Game over!';
        }
      });
    });
  }

  // Roll the dice and move the current player
  Future<void> _rollDice() async {
    if (isRolling || gameBoard.gameOver) return;

    setState(() {
      isRolling = true;
      message = 'Rolling...';
    });

    // Animate the dice
    await _controller.forward(from: 0.0);
    _controller.reverse();

    // Roll and move
    final steps = await gameBoard.rollAndMove();

    setState(() {
      lastRoll = steps;
      isRolling = false;

      if (gameBoard.gameOver) {
        message = '${gameBoard.currentPlayer.name} wins! 🎉';
      } else {
        final landedOnElement = _checkIfLandedOnElement();
        if (landedOnElement != null) {
          message =
              '${gameBoard.currentPlayer.name} rolled $steps and ${landedOnElement.isLadder ? "climbed a ladder to ${landedOnElement.end}" : "slid down a snake to ${landedOnElement.end}"}. ${gameBoard.currentPlayer.name}\'s turn.';
        } else {
          message =
              '${gameBoard.currentPlayer.name} rolled $steps. ${gameBoard.currentPlayer.name}\'s turn.';
        }
      }
    });
  }

  // Check if player landed on a snake or ladder
  BoardElement? _checkIfLandedOnElement() {
    for (var element in gameBoard.boardElements) {
      if (element.end == gameBoard.currentPlayer.position &&
          element.start != gameBoard.currentPlayer.position) {
        return element;
      }
    }
    return null;
  }

  // Reset the game
  void _resetGame() {
    setState(() {
      gameBoard.resetGame();
      lastRoll = 0;

      // Reset timer for Time Attack mode
      if (widget.gameMode == GameMode.timeAttack) {
        gameTimer?.cancel();
        remainingSeconds = 60;
        message = 'Time Attack: You have 60 seconds!';
        _startTimer();
      } else {
        message = 'Game reset! Tap the dice to roll';
      }
    });
  }

  // Return to home screen
  void _goToHome() {
    gameTimer?.cancel();
    Navigator.of(context).pop();
  }

  // Get color based on game mode
  Color _getGameModeColor() {
    switch (widget.gameMode) {
      case GameMode.classic:
        return Colors.blue.shade800;
      case GameMode.timeAttack:
        return Colors.orange.shade800;
      case GameMode.challenge:
        return Colors.red.shade800;
      case GameMode.powerUp:
        return Colors.purple.shade800;
      default:
        return Colors.blue.shade800; // Default color
    }
  }

  // Get title based on game mode
  String _getGameModeTitle() {
    switch (widget.gameMode) {
      case GameMode.classic:
        return 'Classic Mode';
      case GameMode.timeAttack:
        return 'Time Attack';
      case GameMode.challenge:
        return 'Challenge Mode';
      case GameMode.powerUp:
        return 'Power-Up Mode';
      default:
        return 'Classic Mode'; // Default title
    }
  }

  // Use a power-up
  void _usePowerUp(PowerUp powerUp, {Player? targetPlayer}) {
    if (gameBoard.gameOver) return;

    setState(() {
      // Apply power-up effect
      powerUp.apply(gameBoard, targetPlayer: targetPlayer);

      // Remove power-up from player's inventory
      gameBoard.currentPlayer.usePowerUp(powerUp);

      // Update message
      message = '${gameBoard.currentPlayer.name} used ${powerUp.name}!';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final boardSize = screenSize.width * 0.9; // Board takes 90% of screen width

    return Scaffold(
      appBar: AppBar(
        title: Text('Snake & Ladder - ${_getGameModeTitle()}'),
        backgroundColor: _getGameModeColor(),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goToHome,
          tooltip: 'Back to Home',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: 'Reset Game',
          ),
        ],
      ),
      body: Column(
        children: [
          // Game board
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GameBoardWidget(
              gameBoard: gameBoard,
              size: boardSize,
            ),
          ),

          // Game controls and info
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Game message and timer
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      Text(
                        message,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.gameMode == GameMode.timeAttack &&
                          remainingSeconds != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Time: $remainingSeconds seconds',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: remainingSeconds! < 10
                                  ? Colors.red
                                  : Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Dice and player info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Player indicators
                    Expanded(
                      child: Column(
                        children: gameBoard.players.map((player) {
                          final isCurrentPlayer =
                              player == gameBoard.currentPlayer;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: player.color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isCurrentPlayer
                                              ? Colors.yellow
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    if (player.hasShield)
                                      Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.white, width: 1),
                                          ),
                                          child: const Icon(
                                            Icons.shield,
                                            size: 8,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player.name,
                                        style: TextStyle(
                                          fontWeight: isCurrentPlayer
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      Text(
                                        'Position: ${player.position}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Dice
                    GestureDetector(
                      onTap: _rollDice,
                      child: ScaleTransition(
                        scale: _animation,
                        child: DiceWidget(
                          value: lastRoll,
                          isRolling: isRolling,
                          color: _getGameModeColor(),
                          size: 120.0, // Larger size for better visibility
                        ),
                      ),
                    ),
                  ],
                ),

                // Power-ups section
                if (widget.gameMode == GameMode.powerUp ||
                    gameBoard.players.any((p) => p.powerUps.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Column(
                      children: [
                        Text(
                          'Power-Ups',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getGameModeColor(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (gameBoard.currentPlayer.powerUps.isEmpty)
                          const Text(
                            'No power-ups available',
                            style: TextStyle(
                                fontSize: 12, fontStyle: FontStyle.italic),
                          )
                        else
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  gameBoard.currentPlayer.powerUps.length,
                              itemBuilder: (context, index) {
                                final powerUp =
                                    gameBoard.currentPlayer.powerUps[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0),
                                  child: Tooltip(
                                    message:
                                        '${powerUp.name}: ${powerUp.description}',
                                    child: InkWell(
                                      onTap: () {
                                        if (powerUp.type ==
                                            PowerUpType.swapPosition) {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title:
                                                  const Text('Select Player'),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: gameBoard.players
                                                    .where((p) =>
                                                        p !=
                                                        gameBoard.currentPlayer)
                                                    .map((p) => ListTile(
                                                          leading: CircleAvatar(
                                                            backgroundColor:
                                                                p.color,
                                                            radius: 12,
                                                          ),
                                                          title: Text(p.name),
                                                          onTap: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            _usePowerUp(powerUp,
                                                                targetPlayer:
                                                                    p);
                                                          },
                                                        ))
                                                    .toList(),
                                              ),
                                            ),
                                          );
                                        } else {
                                          _usePowerUp(powerUp);
                                        }
                                      },
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: powerUp.color.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border:
                                              Border.all(color: powerUp.color),
                                        ),
                                        child: Icon(
                                          powerUp.icon,
                                          color: powerUp.color,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
