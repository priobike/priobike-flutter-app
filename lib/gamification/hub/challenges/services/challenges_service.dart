import 'dart:async';

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

  StreamSubscription? stream;

  ChallengeService() {
    loadOpenChallenges();
  }

  void completeChallenge() {
    if (_currentChallenge == null) return;
    // Do nothing, if the challenge wasn't completed yet.
    var notCompleted = _currentChallenge!.progress / _currentChallenge!.target < 1;
    if (notCompleted) return;

    stream?.cancel();
    _validator?.dispose();
    _dao.updateObject(_currentChallenge!.copyWith(isOpen: false));
    _currentChallenge = null;
  }

  void startChallengeStream() {
    if (_currentChallenge == null) return;
    stream?.cancel();
    stream = _dao.streamObjectByPrimaryKey(_currentChallenge!.id).listen((update) {
      _currentChallenge = update;
      notifyListeners();
      if (update == null) stream?.cancel();
    });
  }

  Future<void> loadOpenChallenges() async {
    for (var challenge in (await openChallenges)) {
      // If an open challenge was not completed, but the time did run out, close the challenge.
      var isCompleted = challenge.progress / challenge.target >= 1;
      if (!isCompleted && !inTimeFrame(challenge)) {
        await _dao.updateObject(challenge.copyWith(isOpen: false));
      }

      /// If a challenge has been completed, select it as the current challenge so the user can collect rewards.
      else {
        _currentChallenge = challenge;
        _validator = ChallengeValidator(challenge: _currentChallenge!);
        startChallengeStream();
      }
    }
    _loadedChallengeState = true;
  }

  bool inTimeFrame(Challenge challenge) {
    var now = DateTime.now();
    return now.isAfter(challenge.begin) && now.isBefore(challenge.end);
  }

  void generateChallenge() async {
    if (_currentChallenge != null) return;
    _currentChallenge = await _dao.createObject(generatedChallenge);
    if (_currentChallenge == null) throw Exception("Couldn't generate new challenge.");
    _validator = ChallengeValidator(challenge: _currentChallenge!);
    startChallengeStream();
  }

  void deleteCurrentChallenge() {
    if (_currentChallenge == null) return;
    _dao.deleteObject(currentChallenge!);
  }

  void finishChallenge() {
    if (currentChallenge == null) return;
    var modified = currentChallenge!.copyWith(
      progress: (currentChallenge!.target * 1.25).toInt(),
      end: currentChallenge!.begin,
      begin: currentChallenge!.begin.subtract(Duration(days: intervalLengthInDays)),
    );
    _dao.updateObject(modified);
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
