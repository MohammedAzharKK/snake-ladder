import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'power_up.dart';

// Game modes
enum GameMode {
  classic,
  timeAttack,
  challenge,
  powerUp, // New power-up mode
}

// Position class to track player's position on the board
class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  @override
  String toString() => 'Position($x, $y)';
}

// Player class to represent each player in the game
class Player {
  final String name;
  final Color color;
  int position;
  bool isWinner;
  bool hasShield; // Protection from one snake
  List<PowerUp> powerUps; // List of power-ups the player has

  Player(
    this.name,
    this.color, {
    this.position = 1,
    this.isWinner = false,
    this.hasShield = false,
    List<PowerUp>? powerUps,
  }) : powerUps = powerUps ?? [];

  void move(int steps) {
    position += steps;
  }

  void moveTo(int newPosition) {
    position = newPosition;
  }

  // Add a power-up to the player
  void addPowerUp(PowerUp powerUp) {
    powerUps.add(powerUp);
  }

  // Use a power-up
  void usePowerUp(PowerUp powerUp) {
    powerUps.remove(powerUp);
  }

  @override
  String toString() => 'Player($name, position: $position, winner: $isWinner)';
}

// Dice class to handle dice rolling
class Dice {
  final math.Random _random = math.Random();
  int _currentValue = 1;
  bool _isRolling = false;

  int get value => _currentValue;
  bool get isRolling => _isRolling;

  void roll() {
    _isRolling = true;
    _currentValue = _random.nextInt(6) + 1; // 1 to 6
    _isRolling = false;
  }

  // For animation purposes
  Future<int> rollWithAnimation() async {
    _isRolling = true;
    // Simulate dice rolling animation
    for (int i = 0; i < 10; i++) {
      _currentValue = _random.nextInt(6) + 1;
      await Future.delayed(const Duration(milliseconds: 50));
    }
    _isRolling = false;
    return _currentValue;
  }
}

// Special element on the board (Snake or Ladder)
class BoardElement {
  final int start;
  final int end;
  final bool isLadder; // true for ladder, false for snake

  const BoardElement(this.start, this.end) : isLadder = end > start;

  @override
  String toString() =>
      isLadder ? 'Ladder from $start to $end' : 'Snake from $start to $end';
}

// Import for Color class
