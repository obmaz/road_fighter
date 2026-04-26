import 'dart:async';
import 'package:initial_sj/game/engine/gameplay_commands.dart';
import 'package:initial_sj/shared/models/result_summary.dart';
import 'package:initial_sj/shared/models/stage_run.dart';

class GameSessionController {
  // Broadcasters
  final StreamController<GameplayCommand> _commandStreamController = 
      StreamController<GameplayCommand>.broadcast();
  final StreamController<StageRun> _stateStreamController = 
      StreamController<StageRun>.broadcast();
  final StreamController<RunOutcome> _outcomeStreamController = 
      StreamController<RunOutcome>.broadcast();

  Stream<GameplayCommand> get commandStream => _commandStreamController.stream;
  Stream<StageRun> get stateStream => _stateStreamController.stream;
  Stream<RunOutcome> get outcomeStream => _outcomeStreamController.stream;

  // Command Input
  void sendCommand(GameplayCommand command) {
    _commandStreamController.add(command);
  }

  // State Update (called by Flame Engine)
  void updateState(StageRun updatedRun) {
    _stateStreamController.add(updatedRun);
  }

  void reportOutcome(RunOutcome outcome) {
    _outcomeStreamController.add(outcome);
  }

  void dispose() {
    _commandStreamController.close();
    _stateStreamController.close();
    _outcomeStreamController.close();
  }

  // Common Command Helpers
  void moveLeft(CommandState state) => sendCommand(GameplayCommand(GameplayCommandType.moveLeft, state: state));
  void moveRight(CommandState state) => sendCommand(GameplayCommand(GameplayCommandType.moveRight, state: state));
  void accelerate(CommandState state) => sendCommand(GameplayCommand(GameplayCommandType.accelerate, state: state));
  void brake(CommandState state) => sendCommand(GameplayCommand(GameplayCommandType.brake, state: state));
  void nitro(CommandState state) => sendCommand(GameplayCommand(GameplayCommandType.nitro, state: state));
  void pause() => sendCommand(GameplayCommand(GameplayCommandType.pause));
  void resume() => sendCommand(GameplayCommand(GameplayCommandType.resume));
}
