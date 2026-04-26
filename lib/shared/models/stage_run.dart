enum RunStatus { ready, running, paused, cleared, failed, exited }

class StageRun {
  final int livesRemaining;
  final String runId;
  final int stageNumber;
  final RunStatus status;
  final int score;
  final double mapProgress;
  final int currentLap;
  final int totalLaps;
  final int lapRemainingMeters;
  final int flagsCollected;
  final int totalFlags;
  final double currentSpeed;
  final double fuelRemaining;
  final Offset2 playerPosition;
  final double elapsedTime;
  final int collisionCount;
  final int chasersNearby;

  StageRun({
    required this.runId,
    required this.stageNumber,
    this.livesRemaining = 3,
    this.status = RunStatus.ready,
    this.score = 0,
    this.mapProgress = 0.0,
    this.currentLap = 1,
    this.totalLaps = 2,
    this.lapRemainingMeters = 0,
    this.flagsCollected = 0,
    this.totalFlags = 0,
    this.currentSpeed = 0.0,
    this.fuelRemaining = 1.0,
    this.playerPosition = const Offset2.zero(),
    this.elapsedTime = 0.0,
    this.collisionCount = 0,
    this.chasersNearby = 0,
  });

  StageRun copyWith({
    int? livesRemaining,
    RunStatus? status,
    int? score,
    double? mapProgress,
    int? currentLap,
    int? totalLaps,
    int? lapRemainingMeters,
    int? flagsCollected,
    int? totalFlags,
    double? currentSpeed,
    double? fuelRemaining,
    Offset2? playerPosition,
    double? elapsedTime,
    int? collisionCount,
    int? chasersNearby,
  }) {
    return StageRun(
      runId: runId,
      stageNumber: stageNumber,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      status: status ?? this.status,
      score: score ?? this.score,
      mapProgress: mapProgress ?? this.mapProgress,
      currentLap: currentLap ?? this.currentLap,
      totalLaps: totalLaps ?? this.totalLaps,
      lapRemainingMeters: lapRemainingMeters ?? this.lapRemainingMeters,
      flagsCollected: flagsCollected ?? this.flagsCollected,
      totalFlags: totalFlags ?? this.totalFlags,
      currentSpeed: currentSpeed ?? this.currentSpeed,
      fuelRemaining: fuelRemaining ?? this.fuelRemaining,
      playerPosition: playerPosition ?? this.playerPosition,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      collisionCount: collisionCount ?? this.collisionCount,
      chasersNearby: chasersNearby ?? this.chasersNearby,
    );
  }
}

class Offset2 {
  final double x;
  final double y;

  const Offset2(this.x, this.y);

  const Offset2.zero() : x = 0.0, y = 0.0;
}
