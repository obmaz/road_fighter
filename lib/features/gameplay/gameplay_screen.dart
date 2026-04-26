import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:initialsj/app/router/app_router.dart';
import 'package:initialsj/features/gameplay/widgets/pause_overlay.dart';
import 'package:initialsj/game/engine/camera_centered_game.dart';
import 'package:initialsj/game/engine/game_session_controller.dart';
import 'package:initialsj/game/hud/gameplay_hud_overlay.dart';
import 'package:initialsj/game/engine/gameplay_commands.dart';
import 'package:initialsj/game/world/stage_layout.dart';
import 'package:initialsj/shared/models/result_summary.dart';
import 'package:initialsj/shared/models/stage_run.dart';
import 'package:initialsj/shared/state/app_state_controller.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late final GameSessionController _sessionController;
  late final CameraCenteredGame _game;
  final ValueNotifier<StageRun?> _runNotifier = ValueNotifier<StageRun?>(null);
  bool _isPaused = false;
  StreamSubscription<StageRun>? _stateSubscription;
  StreamSubscription<RunOutcome>? _outcomeSubscription;
  int _joystickHorizontal = 0;
  double _joystickSteering = 0.0;

  void _releaseGameplayInputs() {
    _updateJoystickDirection(0, 0);
    _updateJoystickSteering(0);
    _sessionController.accelerate(CommandState.stop);
    _sessionController.brake(CommandState.stop);
    _sessionController.moveLeft(CommandState.stop);
    _sessionController.moveRight(CommandState.stop);
  }

  @override
  void initState() {
    super.initState();
    _sessionController = GameSessionController();
    final appState = context.read<AppStateController>();
    _game = CameraCenteredGame(
      sessionController: _sessionController,
      stageNumber: appState.activeRun?.stageNumber ?? 1,
      vehicle: appState.selectedVehicle,
    );

    _sessionController.commandStream.listen((command) {
      if (command.type == GameplayCommandType.pause) {
        setState(() => _isPaused = true);
        _game.pauseEngine();
      } else if (command.type == GameplayCommandType.resume) {
        setState(() => _isPaused = false);
        _game.resumeEngine();
      }
    });

    _stateSubscription = _sessionController.stateStream.listen((runState) {
      if (!mounted) {
        return;
      }
      _runNotifier.value = runState;
      context.read<AppStateController>().updateActiveRun(runState);
    });

    _outcomeSubscription = _sessionController.outcomeStream.listen((outcome) {
      if (!mounted) {
        return;
      }
      final appState = context.read<AppStateController>();
      final run = appState.activeRun;
      if (run == null) {
        return;
      }

      final summary = ResultSummary(
        finalScore: run.score,
        stageNumber: run.stageNumber,
        outcome: outcome,
        distanceReached: run.flagsCollected.toDouble(),
        coinsAwarded: run.flagsCollected * 100,
        newBestScore: run.score > appState.profile.bestScore,
        clearTimeSeconds: run.elapsedTime,
        lapsCompleted: run.currentLap > run.totalLaps
            ? run.totalLaps
            : run.currentLap,
      );

      appState.updateActiveRun(
        run.copyWith(
          status: outcome == RunOutcome.cleared
              ? RunStatus.cleared
              : RunStatus.failed,
        ),
      );
      appState.setLatestResult(summary);
      unawaited(appState.checkNewBestScore(summary.finalScore));
      unawaited(appState.addCoins(summary.coinsAwarded));
      context.go(AppRouter.resultPath);
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _outcomeSubscription?.cancel();
    _releaseGameplayInputs();
    _sessionController.dispose();
    _runNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safeBottom = mediaQuery.padding.bottom;
    final controlsHeight =
        (mediaQuery.size.height * 0.21).clamp(140.0, 196.0) + safeBottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        context.read<AppStateController>().endRun();
        context.go(AppRouter.titlePath);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Main Gameplay Area (Flame Game)
            Positioned.fill(
              child: GameWidget(
                game: _game,
                backgroundBuilder: (_) => _GameplayParallaxBackground(
                  game: _game,
                  runListenable: _runNotifier,
                ),
                overlayBuilderMap: {
                  'hud': (context, game) => GameplayHudOverlay(
                    sessionController: _sessionController,
                    game: _game,
                  ),
                },
                initialActiveOverlays: const ['hud'],
              ),
            ),

            // Touch Controls (Bottom Area)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: controlsHeight,
              child: SafeArea(top: false, child: _buildControls(context)),
            ),

            // Pause Overlay
            if (_isPaused)
              Positioned.fill(
                child: PauseOverlay(sessionController: _sessionController),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final verticalPadding = safeBottom > 0 ? 2.0 : 6.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(4, verticalPadding, 24, verticalPadding),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: _NitroButton(
              onPressed: () => _sessionController.nitro(CommandState.start),
              onReleased: () {},
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 92,
            height: 92,
            child: _SkillButton(onPressed: () {}, onReleased: () {}),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Align(
              alignment: const Alignment(-0.35, 0),
              child: _JoystickPanel(
                onDirectionChanged: _updateJoystickDirection,
                onSteeringChanged: _updateJoystickSteering,
                onTouchActiveChanged: (active) {
                  _sessionController.accelerate(
                    active ? CommandState.start : CommandState.stop,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateJoystickDirection(int horizontal, int vertical) {
    if (_joystickHorizontal != horizontal) {
      if (_joystickHorizontal == -1) {
        _sessionController.moveLeft(CommandState.stop);
      } else if (_joystickHorizontal == 1) {
        _sessionController.moveRight(CommandState.stop);
      }

      _joystickHorizontal = horizontal;

      if (_joystickHorizontal == -1) {
        _sessionController.moveLeft(CommandState.start);
      } else if (_joystickHorizontal == 1) {
        _sessionController.moveRight(CommandState.start);
      }
    }
  }

  void _updateJoystickSteering(double steering) {
    if ((_joystickSteering - steering).abs() < 0.001) {
      return;
    }
    _joystickSteering = steering;
    _game.player.setSteeringInput(steering);
  }

  @override
  void deactivate() {
    _releaseGameplayInputs();
    super.deactivate();
  }
}

class _GameplayParallaxBackground extends StatefulWidget {
  const _GameplayParallaxBackground({
    required this.game,
    required this.runListenable,
  });

  final CameraCenteredGame game;
  final ValueNotifier<StageRun?> runListenable;

  @override
  State<_GameplayParallaxBackground> createState() =>
      _GameplayParallaxBackgroundState();
}

class _GameplayParallaxBackgroundState
    extends State<_GameplayParallaxBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _parallaxTicker;

  @override
  void initState() {
    super.initState();
    _parallaxTicker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _parallaxTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_parallaxTicker, widget.runListenable]),
      builder: (context, child) {
        final stageNumber =
            widget.runListenable.value?.stageNumber ?? widget.game.stageNumber;
        final backgroundAsset = StageLayout.gameplayBackgroundAssetForStage(
          stageNumber,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final overscanX = width * 0.10;
            final overscanY = height * 0.12;
            final imageWidth = width + (overscanX * 2);
            final imageHeight = height + (overscanY * 2);
            final progress = _currentProgress();
            final roadCurve = _lookaheadRoadCurve();
            final horizontalShift =
                (-_laneOffset() * width * 0.055) - (roadCurve * width * 0.12);
            final verticalShift = (progress - 0.5) * height * 0.10;

            return ClipRect(
              child: Stack(
                children: [
                  Positioned(
                    left: -overscanX + horizontalShift,
                    top: -overscanY + verticalShift,
                    width: imageWidth,
                    height: imageHeight,
                    child: Image.asset(
                      backgroundAsset,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  double _currentProgress() {
    if (widget.game.isLoaded) {
      return widget.game.mapProgress.clamp(0.0, 1.0);
    }
    return (widget.runListenable.value?.mapProgress ?? 0.0).clamp(0.0, 1.0);
  }

  double _laneOffset() {
    if (!widget.game.isLoaded) {
      return 0.0;
    }
    return widget.game.normalizedPlayerLaneOffset.clamp(-1.0, 1.0);
  }

  double _lookaheadRoadCurve() {
    if (!widget.game.isLoaded) {
      return 0.0;
    }

    final playerY = widget.game.playerWorldPosition.y;
    final currentRoadCenter = widget.game.stage.roadCenterRatioForWorldY(
      playerY,
    );
    final distantRoadCenter = widget.game.stage.roadCenterRatioForWorldY(
      playerY - (widget.game.visibleDepth * 0.7),
    );
    return (distantRoadCenter - currentRoadCenter).clamp(-0.5, 0.5);
  }
}

class _NitroButton extends StatefulWidget {
  const _NitroButton({required this.onPressed, required this.onReleased});

  final VoidCallback onPressed;
  final VoidCallback onReleased;

  @override
  State<_NitroButton> createState() => _NitroButtonState();
}

class _NitroButtonState extends State<_NitroButton> {
  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      assetPath: 'assets/images/ui/nitro_button.webp',
      onPressed: widget.onPressed,
      onReleased: widget.onReleased,
    );
  }
}

class _SkillButton extends StatefulWidget {
  const _SkillButton({required this.onPressed, required this.onReleased});

  final VoidCallback onPressed;
  final VoidCallback onReleased;

  @override
  State<_SkillButton> createState() => _SkillButtonState();
}

class _SkillButtonState extends State<_SkillButton> {
  @override
  Widget build(BuildContext context) {
    return _ActionButton(
      assetPath: 'assets/images/ui/skill_button.webp',
      onPressed: widget.onPressed,
      onReleased: widget.onReleased,
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.assetPath,
    required this.onPressed,
    required this.onReleased,
  });

  final String assetPath;
  final VoidCallback onPressed;
  final VoidCallback onReleased;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        setState(() {
          _pressed = true;
        });
        widget.onPressed();
      },
      onPointerUp: (_) => _release(),
      onPointerCancel: (_) => _release(),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 90),
        scale: _pressed ? 0.95 : 1.0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 90),
          opacity: _pressed ? 0.92 : 1.0,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [Image.asset(widget.assetPath)],
          ),
        ),
      ),
    );
  }

  void _release() {
    if (_pressed) {
      setState(() {
        _pressed = false;
      });
    }
    widget.onReleased();
  }
}

class _JoystickPanel extends StatelessWidget {
  const _JoystickPanel({
    required this.onDirectionChanged,
    required this.onSteeringChanged,
    required this.onTouchActiveChanged,
  });

  final void Function(int horizontal, int vertical) onDirectionChanged;
  final ValueChanged<double> onSteeringChanged;
  final ValueChanged<bool> onTouchActiveChanged;

  @override
  Widget build(BuildContext context) {
    return _VirtualJoystick(
      onDirectionChanged: onDirectionChanged,
      onSteeringChanged: onSteeringChanged,
      onTouchActiveChanged: onTouchActiveChanged,
    );
  }
}

class _VirtualJoystick extends StatefulWidget {
  const _VirtualJoystick({
    required this.onDirectionChanged,
    required this.onSteeringChanged,
    required this.onTouchActiveChanged,
  });

  final void Function(int horizontal, int vertical) onDirectionChanged;
  final ValueChanged<double> onSteeringChanged;
  final ValueChanged<bool> onTouchActiveChanged;

  @override
  State<_VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<_VirtualJoystick> {
  static const double _baseSize = 124;
  static const double _knobSize = 50;
  static const double _travelRadius = 34;
  static const double _deadZone = 10;

  Offset _dragOffset = Offset.zero;
  bool _touchActive = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _baseSize,
      height: _baseSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: (_) => _resetStick(),
        onPanCancel: _resetStick,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white38, width: 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
              ),
              Transform.translate(
                offset: _dragOffset,
                child: Container(
                  width: _knobSize,
                  height: _knobSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE33B2F),
                    border: Border.all(color: Colors.white70, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePanStart(DragStartDetails details) {
    if (!_touchActive) {
      _touchActive = true;
      widget.onTouchActiveChanged(true);
    }
    _updateFromLocalPosition(details.localPosition);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    _updateFromLocalPosition(details.localPosition);
  }

  void _updateFromLocalPosition(Offset localPosition) {
    final center = const Offset(_baseSize / 2, _baseSize / 2);
    final rawDelta = localPosition - center;
    final delta = Offset(rawDelta.dx.clamp(-_travelRadius, _travelRadius), 0);

    setState(() {
      _dragOffset = delta;
    });

    final horizontal = delta.dx > _deadZone
        ? 1
        : delta.dx < -_deadZone
        ? -1
        : 0;
    final steering = (delta.dx / _travelRadius).clamp(-1.0, 1.0);
    widget.onDirectionChanged(horizontal, 0);
    widget.onSteeringChanged(steering);
  }

  void _resetStick() {
    setState(() {
      _dragOffset = Offset.zero;
    });
    if (_touchActive) {
      _touchActive = false;
      widget.onTouchActiveChanged(false);
    }
    widget.onDirectionChanged(0, 0);
    widget.onSteeringChanged(0);
  }
}
