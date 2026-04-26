import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:initial_sj/shared/models/player_profile.dart';

class LocalStorageService {
  static const String _profileKey = 'player_profile';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  Future<void> saveProfile(PlayerProfile profile) async {
    final jsonString = jsonEncode(profile.toJson());
    await _prefs.setString(_profileKey, jsonString);
  }

  PlayerProfile? getProfile() {
    final jsonString = _prefs.getString(_profileKey);
    if (jsonString == null) return null;
    try {
      return PlayerProfile.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return null;
    }
  }
}
