import 'package:flutter/material.dart';

import '../models/game_models.dart';
import 'game_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade300,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game title
              const Text(
                'Snake & Ladder',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black38,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),

              // Game mode selection
              _buildGameModeButton(
                context,
                'Classic Mode',
                'Play the traditional Snake & Ladder game',
                Icons.gamepad,
                Colors.green.shade600,
                () => _startGame(context, GameMode.classic),
              ),
              const SizedBox(height: 20),

              _buildGameModeButton(
                context,
                'Time Attack',
                'Race against the clock to reach the top',
                Icons.timer,
                Colors.orange.shade600,
                () => _startGame(context, GameMode.timeAttack),
              ),
              const SizedBox(height: 20),

              _buildGameModeButton(
                context,
                'Challenge Mode',
                'More snakes, fewer ladders. Can you win?',
                Icons.warning_rounded,
                Colors.red.shade600,
                () => _startGame(context, GameMode.challenge),
              ),
              const SizedBox(height: 20),

              _buildGameModeButton(
                context,
                'Power-Up Mode',
                'Collect and use special power-ups!',
                Icons.auto_awesome,
                Colors.purple.shade600,
                () => _startGame(context, GameMode.powerUp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameModeButton(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 280,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
        ),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startGame(BuildContext context, GameMode mode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(gameMode: mode),
      ),
    );
  }
}
