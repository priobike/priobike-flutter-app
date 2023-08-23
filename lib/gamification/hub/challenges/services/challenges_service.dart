import 'package:flutter/foundation.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';
import 'package:priobike/gamification/hub/challenges/services/challenge_validator.dart';
import 'package:priobike/gamification/hub/challenges/utils/challenge_generator.dart';

abstract class ChallengeService with ChangeNotifier {
  final ChallengesDao _dao = AppDatabase.instance.challengesDao;

  final ChallengeGenerator _generator = ChallengeGenerator();

  ChallengeValidator? _validator;

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
      startChallengeStreams();
    }();
  }

  void startChallengeStreams() {
    _dao.streamChallengesInInterval(intervalStartDay, intervalLengthInDays).listen(
      (update) {
        if (_currentChallenge != null) return;
        if (update.isEmpty) {
          if (!_loadedChallengeState) return;
          _currentChallenge = null;
        } else {
          _validator?.dispose();
          _currentChallenge = update.first;
          _validator = ChallengeValidator(challenge: _currentChallenge!);
        }
        notifyListeners();
      },
    );
  }

  Future<void> progressOpenChallenges() async {
    for (var challenge in (await openChallenges)) {
      var isCompleted = challenge.progress / challenge.target >= 1;
      if (!isCompleted && !inTimeFrame(challenge)) {
        await _dao.updateObject(challenge.copyWith(isOpen: false));
      } else {
        _currentChallenge = challenge;
      }
    }
    _loadedChallengeState = true;
  }

  bool inTimeFrame(Challenge challenge) {
    var now = DateTime.now();
    return now.isAfter(challenge.begin) && now.isBefore(challenge.end);
  }

  void generateChallenge() {
    if (_currentChallenge != null) return;
    _dao.createObject(generatedChallenge);
  }

  void deleteCurrentChallenge() {
    if (_currentChallenge == null) return;
    _dao.deleteObject(currentChallenge!);
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
  ChallengesCompanion get generatedChallenge => _generator.generateDailyChallenge();
}

class WeeklyChallengeService extends ChallengeService {
  @override
  int get intervalLengthInDays => DateTime.daysPerWeek;

  @override
  DateTime get intervalStartDay => DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

  @override
  Future<List<Challenge>> get openChallenges => _dao.getOpenWeeklyChallenges();

  @override
  ChallengesCompanion get generatedChallenge => _generator.generateWeeklyChallenge();
}
