import 'package:flutter/foundation.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';
import 'package:priobike/gamification/hub/challenges/services/challenge_generator.dart';

abstract class ChallengeService with ChangeNotifier {
  final ChallengesDao _dao = AppDatabase.instance.challengesDao;

  bool _loadedChallengeState = false;
  bool get loadedChallengeState => _loadedChallengeState;

  Challenge? _currentChallenge;
  Challenge? get currentChallenge => _currentChallenge;

  int get intervalLengthInDays;

  DateTime get intervalStartDay;

  Future<List<Challenge>> get openChallenges;

  ChallengesCompanion get generatedChallenge;

  ChallengeService() {
    () async {
      await progressOpenChallenges();
      await loadCurrentState();
      startChallengeStreams();
    }();
  }

  void startChallengeStreams() {
    _dao.streamChallengesInInterval(intervalStartDay, intervalLengthInDays).listen((update) {
      if (update.isEmpty) {
        if (!_loadedChallengeState) return;
        _dao.createObject(generatedChallenge);
      } else {
        _currentChallenge = update.first;
        notifyListeners();
      }
    });
  }

  Future<void> loadCurrentState() async {
    var challengesOnDay = await _dao.getChallengesInInterval(intervalStartDay, 1);
    if (challengesOnDay.isNotEmpty) {
      _currentChallenge = challengesOnDay.first;
    }

    _loadedChallengeState = true;
  }

  Future<void> progressOpenChallenges() async {
    for (var challenge in (await openChallenges)) {
      var modifiedChallenge = challenge;

      var isCompleted = challenge.progress / challenge.target >= 1;

      if (!inTimeFrame(challenge) || isCompleted) {
        await _dao.updateObject(modifiedChallenge.copyWith(isOpen: true, hasBeenCompleted: true));
      }
    }
  }

  bool inTimeFrame(Challenge challenge) {
    var now = DateTime.now();
    return now.isAfter(challenge.start) && now.isBefore(challenge.end);
  }
}

class DailyChallengeService extends ChallengeService {
  @override
  int get intervalLengthInDays => 1;

  @override
  DateTime get intervalStartDay => DateTime.now();

  @override
  Future<List<Challenge>> get openChallenges => _dao.getOpenDailyChallenges();

  @override
  ChallengesCompanion get generatedChallenge => ChallengeGenerator.generateDailyChallenge();
}

class WeeklyChallengeService extends ChallengeService {
  @override
  int get intervalLengthInDays => DateTime.daysPerWeek;

  @override
  DateTime get intervalStartDay => DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

  @override
  Future<List<Challenge>> get openChallenges => _dao.getOpenWeeklyChallenges();

  @override
  ChallengesCompanion get generatedChallenge => ChallengeGenerator.generateWeeklyChallenge();
}
