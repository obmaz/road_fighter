import 'package:initial_sj/shared/models/vehicle_spec.dart';

class PlayerProfile {
  final String playerId;
  final String displayName;
  final int coinBalance;
  final int level;
  final int bestScore;
  final List<String> ownedVehicleIds;
  final String selectedVehicleId;

  PlayerProfile({
    required this.playerId,
    this.displayName = 'Player 1',
    this.coinBalance = 0,
    this.level = 1,
    this.bestScore = 0,
    List<String>? ownedVehicleIds,
    this.selectedVehicleId = VehicleCatalog.starterId,
  }) : ownedVehicleIds =
           ownedVehicleIds ?? VehicleCatalog.defaultOwnedVehicleIds();

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final ownedVehicleIds = (json['ownedVehicleIds'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    final selectedVehicleId =
        (json['selectedVehicleId'] as String?) ?? VehicleCatalog.starterId;

    return PlayerProfile(
      playerId: json['playerId'],
      displayName: json['displayName'] ?? 'Player 1',
      coinBalance: json['coinBalance'] ?? 0,
      level: json['level'] ?? 1,
      bestScore: json['bestScore'] ?? 0,
      ownedVehicleIds: ownedVehicleIds,
      selectedVehicleId: selectedVehicleId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'displayName': displayName,
      'coinBalance': coinBalance,
      'level': level,
      'bestScore': bestScore,
      'ownedVehicleIds': ownedVehicleIds,
      'selectedVehicleId': selectedVehicleId,
    };
  }

  PlayerProfile copyWith({
    String? displayName,
    int? coinBalance,
    int? level,
    int? bestScore,
    List<String>? ownedVehicleIds,
    String? selectedVehicleId,
  }) {
    return PlayerProfile(
      playerId: playerId,
      displayName: displayName ?? this.displayName,
      coinBalance: coinBalance ?? this.coinBalance,
      level: level ?? this.level,
      bestScore: bestScore ?? this.bestScore,
      ownedVehicleIds: ownedVehicleIds ?? this.ownedVehicleIds,
      selectedVehicleId: selectedVehicleId ?? this.selectedVehicleId,
    );
  }
}
