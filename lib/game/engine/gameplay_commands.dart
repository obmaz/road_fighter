enum GameplayCommandType {
  moveLeft,
  moveRight,
  accelerate,
  brake,
  nitro,
  pause,
  resume,
}

enum CommandState { start, stop }

class GameplayCommand {
  final GameplayCommandType type;
  final CommandState state;

  GameplayCommand(this.type, {this.state = CommandState.start});

  @override
  String toString() => 'GameplayCommand(${type.name}, ${state.name})';
}
