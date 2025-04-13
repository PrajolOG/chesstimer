// lib/timer.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'dart:async';
import 'package:audioplayers/audioplayers.dart'; // For sound effects

class TimerPage extends StatefulWidget {
  final int whiteTime;
  final int blackTime;
  final int increment;

  const TimerPage({
    Key? key,
    required this.whiteTime,
    required this.blackTime,
    required this.increment,
  }) : super(key: key);

  @override
  _TimerPageState createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with TickerProviderStateMixin {
  // Time and Game State
  late int _whiteTime; // in seconds
  late int _blackTime; // in seconds
  late int _increment; // in seconds
  bool _isWhiteTurn = true;
  bool _isRunning = false;
  Timer? _timer;
  bool _isGameOver = false;
  String _gameOverMessageWhite = '';
  String _gameOverMessageBlack = '';

  // UI State
  bool _showPauseOverlay = false;
  List<int> _whiteMoves = [];
  List<int> _blackMoves = [];

  // Low Time Warning
  static const int _lowTimeThreshold =
      60; // Seconds remaining to trigger warning
  bool _isWhiteLowTime = false;
  bool _isBlackLowTime = false;
  AnimationController? _whiteBlinkController;
  Animation<Color?>? _whiteBlinkColorAnimation;
  AnimationController? _blackBlinkController;
  Animation<Color?>? _blackBlinkColorAnimation;

  // --- Sound Effects Setup ---
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _clickSoundPath = 'sounds/click.mp3';
  final String _gameOverSoundPath = 'sounds/gameover.mp3';
  // --- End Sound Effects Setup ---

  @override
  void initState() {
    super.initState();
    _resetTimes(); // Initialize times
    _increment = widget.increment;

    // Initialize Animation Controllers
    _whiteBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _blackBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Define color tween for blinking
    _whiteBlinkColorAnimation = ColorTween(
      begin: Colors.green[700],
      end: Colors.red[700],
    ).animate(_whiteBlinkController!);
    _blackBlinkColorAnimation = ColorTween(
      begin: Colors.green[700],
      end: Colors.red[700],
    ).animate(_blackBlinkController!);

    // Initial check for low time
    _checkLowTimeWhite(runAnimation: false);
    _checkLowTimeBlack(runAnimation: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _whiteBlinkController?.dispose();
    _blackBlinkController?.dispose();
    _audioPlayer.dispose(); // Dispose the player
    super.dispose();
  }

  // --- Core Timer Logic ---
  void _startTimer() {
    if (!_isRunning && !_isGameOver) {
      setState(() {
        _isRunning = true;
        _showPauseOverlay = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
      _checkLowTimeConditions();
    }
  }

  void _tick(Timer timer) {
    if (!_isRunning || _isGameOver) {
      timer.cancel();
      _stopBlinkAnimations();
      return;
    }
    // Ensure widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        if (_isWhiteTurn) {
          if (_whiteTime > 0) {
            _whiteTime--;
            _checkLowTimeWhite();
          } else {
            _whiteTime = 0;
            _gameOver(false, "Timeout");
          }
        } else {
          if (_blackTime > 0) {
            _blackTime--;
            _checkLowTimeBlack();
          } else {
            _blackTime = 0;
            _gameOver(true, "Timeout");
          }
        }
      });
    } else {
      // Widget is disposed, cancel the timer
      timer.cancel();
      _stopBlinkAnimations();
    }
  }

  void _pauseTimer() {
    if (_isRunning) {
      _timer?.cancel();
      _stopBlinkAnimations();
      if (mounted) {
        setState(() {
          _isRunning = false;
          _showPauseOverlay = true;
        });
      }
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _resetTimes();
        _isWhiteTurn = true;
        _whiteMoves = [];
        _blackMoves = [];
        _isGameOver = false;
        _gameOverMessageWhite = '';
        _gameOverMessageBlack = '';
        _isRunning = false;
        _showPauseOverlay = false;
        _isWhiteLowTime = false;
        _isBlackLowTime = false;
        _stopBlinkAnimations();
        _checkLowTimeWhite(runAnimation: false);
        _checkLowTimeBlack(runAnimation: false);
      });
    }
  }

  void _switchTurn() {
    if (_isRunning && !_isGameOver) {
      HapticFeedback.lightImpact();
      // Ensure widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          if (_isWhiteTurn) {
            _whiteTime += _increment;
            _whiteMoves.add(_whiteMoves.length + 1);
            if (_isWhiteLowTime) _stopBlinkAnimation(_whiteBlinkController);
          } else {
            _blackTime += _increment;
            _blackMoves.add(_blackMoves.length + 1);
            if (_isBlackLowTime) _stopBlinkAnimation(_blackBlinkController);
          }
          _isWhiteTurn = !_isWhiteTurn;
          _checkLowTimeConditions();
        });
      }
    }
  }

  void _gameOver(bool whiteWins, String reason) {
    if (_isGameOver) return;
    _playSound(_gameOverSoundPath); // Play game over sound
    _timer?.cancel(); // Make sure timer is cancelled first
    // Ensure widget is still mounted before calling setState
    if (mounted) {
      setState(() {
        _isGameOver = true;
        _isRunning = false;
        _showPauseOverlay = false;
        _gameOverMessageWhite = whiteWins ? 'WINNER' : 'Loser';
        _gameOverMessageBlack = whiteWins ? 'Loser' : 'WINNER';
        if (reason == "Timeout") {
          if (!whiteWins)
            _gameOverMessageWhite += '\n(Timeout)';
          else
            _gameOverMessageBlack += '\n(Timeout)';
        } else if (reason == "Resignation") {
          if (!whiteWins)
            _gameOverMessageWhite += '\n(Resigned)';
          else
            _gameOverMessageBlack += '\n(Resigned)';
        }
        _isWhiteLowTime = false;
        _isBlackLowTime = false;
        _stopBlinkAnimations(); // Stop blinking on game over
      });
    }
  }

  void _resign(bool whiteResigned) {
    if (!_isGameOver) {
      _gameOver(!whiteResigned, "Resignation");
    }
  }

  // --- Low Time Logic ---
  void _checkLowTimeConditions() {
    if (!_isRunning || _isGameOver) return;
    _checkLowTimeWhite(runAnimation: _isWhiteTurn);
    _checkLowTimeBlack(runAnimation: !_isWhiteTurn);
  }

  void _checkLowTimeWhite({bool runAnimation = true}) {
    bool wasLow = _isWhiteLowTime;
    bool isNowLow = _whiteTime <= _lowTimeThreshold && _whiteTime > 0;
    if (isNowLow != wasLow) {
      if (mounted)
        setState(() {
          _isWhiteLowTime = isNowLow;
        });
    }
    if (_isRunning && _isWhiteTurn && isNowLow && runAnimation) {
      _startBlinkAnimation(_whiteBlinkController);
    } else if (!isNowLow || !_isRunning || !_isWhiteTurn) {
      _stopBlinkAnimation(_whiteBlinkController);
    }
  }

  void _checkLowTimeBlack({bool runAnimation = true}) {
    bool wasLow = _isBlackLowTime;
    bool isNowLow = _blackTime <= _lowTimeThreshold && _blackTime > 0;
    if (isNowLow != wasLow) {
      if (mounted)
        setState(() {
          _isBlackLowTime = isNowLow;
        });
    }
    if (_isRunning && !_isWhiteTurn && isNowLow && runAnimation) {
      _startBlinkAnimation(_blackBlinkController);
    } else if (!isNowLow || !_isRunning || _isWhiteTurn) {
      _stopBlinkAnimation(_blackBlinkController);
    }
  }

  void _startBlinkAnimation(AnimationController? controller) {
    if (mounted && controller != null && !controller.isAnimating) {
      controller.repeat(reverse: true);
    }
  }

  void _stopBlinkAnimation(AnimationController? controller) {
    if (mounted && controller != null && controller.isAnimating) {
      controller.stop();
      controller.reset();
    }
  }

  void _stopBlinkAnimations() {
    _stopBlinkAnimation(_whiteBlinkController);
    _stopBlinkAnimation(_blackBlinkController);
  }

  // --- Helper Methods ---
  void _resetTimes() {
    _whiteTime = widget.whiteTime * 60;
    _blackTime = widget.blackTime * 60;
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // --- Sound Playback Function (Using ONLY AudioPlayer) ---
  Future<void> _playSound(String assetPathSuffix) async {
    PlayerMode mode =
        (assetPathSuffix == _clickSoundPath)
            ? PlayerMode.lowLatency
            : PlayerMode.mediaPlayer;

    try {
      // Explicitly stop any potentially ongoing sound before playing again.
      await _audioPlayer.stop();
      // Use AssetSource (audioplayers adds 'assets/' prefix automatically)
      await _audioPlayer.play(AssetSource(assetPathSuffix), mode: mode);
    } catch (e) {
      // Consider adding proper logging here for production builds if needed
      // For now, just catch the error silently or log to console only in debug mode
      // if (kDebugMode) {
      //   print("Error playing sound '$assetPathSuffix': $e");
      // }
    }
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Column(
          children: [
            _buildPlayerArea(
              isWhitePlayer: true,
              time: _whiteTime,
              moves: _whiteMoves,
              isTurn: _isWhiteTurn,
              isLowTime: _isWhiteLowTime,
              blinkController: _whiteBlinkController,
              blinkAnimation: _whiteBlinkColorAnimation,
              gameOverMessage: _gameOverMessageWhite,
            ),
            _buildControlBar(),
            _buildPlayerArea(
              isWhitePlayer: false,
              time: _blackTime,
              moves: _blackMoves,
              isTurn: !_isWhiteTurn,
              isLowTime: _isBlackLowTime,
              blinkController: _blackBlinkController,
              blinkAnimation: _blackBlinkColorAnimation,
              gameOverMessage: _gameOverMessageBlack,
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildPlayerArea({
    required bool isWhitePlayer,
    required int time,
    required List<int> moves,
    required bool isTurn,
    required bool isLowTime,
    required AnimationController? blinkController,
    required Animation<Color?>? blinkAnimation,
    required String gameOverMessage,
  }) {
    Color baseBackgroundColor;
    if (_isGameOver) {
      baseBackgroundColor = Colors.grey[700]!;
    } else if (isTurn) {
      baseBackgroundColor = Colors.green[700]!;
    } else {
      baseBackgroundColor =
          isWhitePlayer ? Colors.grey[850]! : Colors.grey[800]!;
    }
    bool shouldBlink =
        isTurn &&
        _isRunning &&
        !_isGameOver &&
        (isWhitePlayer ? _isWhiteLowTime : _isBlackLowTime);
    Widget background =
        (shouldBlink && blinkController != null && blinkAnimation != null)
            ? AnimatedBuilder(
              animation: blinkAnimation,
              builder: (context, child) {
                return Container(
                  color: blinkAnimation.value ?? baseBackgroundColor,
                );
              },
            )
            : Container(color: baseBackgroundColor);

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isGameOver && gameOverMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              gameOverMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isWhitePlayer ? 35 : 40,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                    blurRadius: 2.0,
                    color: Colors.black54,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        Text(
          _formatTime(time),
          style: TextStyle(
            fontSize: _isGameOver ? 60 : 85,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            shadows: const [
              Shadow(
                blurRadius: 1.0,
                color: Colors.black38,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ],
    );

    if (isWhitePlayer) {
      content = Transform.rotate(angle: 3.14159, child: content);
    }

    return Expanded(
      flex: 5,
      child: GestureDetector(
        onTap: () {
          // Guard Clause: Exit if game is over
          if (_isGameOver) {
            return;
          }

          // Play Sound (only if game is not over)
          _playSound(_clickSoundPath); // Play sound FIRST

          // Handle Game Logic
          if (isTurn && _isRunning) {
            _switchTurn();
          } else if (!_isRunning) {
            // Allow starting only if it's the tapped player's turn OR the very first move
            if (isTurn ||
                (_isWhiteTurn &&
                    isWhitePlayer &&
                    _whiteMoves.isEmpty &&
                    _blackMoves.isEmpty)) {
              _startTimer();
            }
          }
          // Else: Timer is running, but it's not the tapped player's turn (do nothing)
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: background),
            Center(child: content),
            _buildMovesCounter(moves, isWhitePlayer),
            if (_showPauseOverlay && !_isGameOver) _buildPauseOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      height: 70,
      color: Colors.grey[900],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.flag,
            tooltip: 'White Resign',
            onPressed: _isGameOver ? null : () => _resign(true),
            color: Colors.white70,
          ),
          _buildControlButton(
            icon:
                _isRunning
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
            tooltip:
                _isRunning ? 'Pause' : (_isGameOver ? 'Game Over' : 'Start'),
            onPressed:
                _isGameOver ? null : (_isRunning ? _pauseTimer : _startTimer),
            size: 45,
            color: Colors.white,
          ),
          _buildControlButton(
            icon: Icons.refresh,
            tooltip: 'Reset Game',
            onPressed: _resetTimer,
            color: Colors.white,
          ),
          _buildControlButton(
            icon: Icons.settings,
            tooltip: 'Settings / Go Back',
            onPressed: () {
              if (_isRunning) _pauseTimer();
              Navigator.pop(context);
            },
            color: Colors.white,
          ),
          _buildControlButton(
            icon: Icons.flag,
            tooltip: 'Black Resign',
            onPressed: _isGameOver ? null : () => _resign(false),
            color: Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    double size = 35.0,
    Color color = Colors.white,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        size: size,
        color: onPressed == null ? Colors.grey[600] : color,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 25.0,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildMovesCounter(List<int> moves, bool isRotated) {
    int moveCount = moves.length;
    Widget movesText = Text(
      'Moves: $moveCount',
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontWeight: FontWeight.w500,
        fontSize: 16,
        shadows: const [
          Shadow(blurRadius: 1.0, color: Colors.black26, offset: Offset(1, 1)),
        ],
      ),
    );

    if (isRotated) {
      movesText = Transform.rotate(angle: 3.14159, child: movesText);
    }

    return Positioned(
      // For rotated (top box): bottom right
      // For non-rotated (bottom box): top right
      bottom: isRotated ? 15 : null,
      top: !isRotated ? 15 : null,
      right: 20, // Right alignment for both boxes
      child: movesText,
    );
  }

  Widget _buildPauseOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: const Center(
          child: Icon(
            Icons.pause_circle_outline,
            color: Colors.white70,
            size: 80,
          ),
        ),
      ),
    );
  }
} // End _TimerPageState class
