import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:initial_sj/core/services/local_storage_service.dart';
import 'package:initial_sj/shared/models/result_summary.dart';
import 'package:initial_sj/shared/state/app_state_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;
  late AppStateController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = LocalStorageService(prefs);
    controller = AppStateController(storage);
  });

  group('AppStateController Tests', () {
    test('Initial state should load correctly', () {
      expect(controller.profile, isNotNull);
      expect(controller.activeRun, isNull);
    });

    test('startNewRun should create activeRun', () {
      controller.startNewRun(1);
      expect(controller.activeRun, isNotNull);
      expect(controller.activeRun!.stageNumber, 1);
      expect(controller.latestResult, isNull);
    });

    test('setLatestResult should store summary', () {
      final summary = ResultSummary(
        finalScore: 1200,
        stageNumber: 1,
        outcome: RunOutcome.cleared,
        distanceReached: 6,
        coinsAwarded: 60,
      );

      controller.setLatestResult(summary);

      expect(controller.latestResult, isNotNull);
      expect(controller.latestResult!.finalScore, 1200);
    });
  });
}
