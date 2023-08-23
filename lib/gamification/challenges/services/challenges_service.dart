import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';
import 'package:priobike/gamification/challenges/utils/challenge_validator.dart';
import 'package:priobike/gamification/challenges/utils/challenge_generator.dart';

abstract class ChallengeService with ChangeNotifier {
  final ChallengesDao _dao = AppDatabase.instance.challengesDao;

  final ChallengeGenerator _generator = ChallengeGenerator();

  ChallengeValidator? _validator;

  Challenge? _currentChallenge;
  Challenge? get currentChallenge => _currentChallenge;

  bool _allowNew = false;
  bool get allowNew => _allowNew;

  int get _intervalLengthInDays;

  DateTime get _intervalStartDay;

  Future<List<Challenge>> get _openChallenges;

  ChallengesCompanion get _generatedChallenge;

  StreamSubscription? _stream;

  ChallengeService() {
    loadOpenChallenges();
    startTimeWindowStream();
  }

  void startTimeWindowStream() {
    _dao.streamChallengesInInterval(_intervalStartDay, _intervalLengthInDays).listen((update) {
      _allowNew = update.isEmpty;
    });
  }

  void completeChallenge() {
    if (_currentChallenge == null) return;
    // Do nothing, if the challenge wasn't completed yet.
    var notCompleted = _currentChallenge!.progress / _currentChallenge!.target < 1;
    if (notCompleted) return;

    _stream?.cancel();
    _validator?.dispose();
    _dao.updateObject(_currentChallenge!.copyWith(isOpen: false));
    _currentChallenge = null;
  }

  void startChallengeStream() {
    if (_currentChallenge == null) return;
    _stream?.cancel();
    _stream = _dao.streamObjectByPrimaryKey(_currentChallenge!.id).listen((update) {
      _currentChallenge = update;
      notifyListeners();
      if (update == null) _stream?.cancel();
    });
  }

  Future<void> loadOpenChallenges() async {
    for (var challenge in (await _openChallenges)) {
      // If an open challenge was not completed, but the time did run out, close the challenge.
      var isCompleted = challenge.progress / challenge.target >= 1;
      if (!isCompleted && !currentlyActive(challenge)) {
        await _dao.updateObject(challenge.copyWith(isOpen: false));
      }

      /// If a challenge has been completed, select it as the current challenge so the user can collect rewards.
      else {
        _currentChallenge = challenge;
        _validator = ChallengeValidator(challenge: _currentChallenge!);
        startChallengeStream();
      }
    }
  }

  bool currentlyActive(Challenge challenge) {
    var now = DateTime.now();
    return now.isAfter(challenge.begin) && now.isBefore(challenge.end);
  }

  void generateChallenge() async {
    if (_currentChallenge != null) return;
    _currentChallenge = await _dao.createObject(_generatedChallenge);
    if (_currentChallenge == null) throw Exception("Couldn't generate new challenge.");
    _validator = ChallengeValidator(challenge: _currentChallenge!);
    startChallengeStream();
  }

  void deleteCurrentChallenge() {
    if (_currentChallenge == null) return;
    _dao.deleteObject(currentChallenge!);
  }

  void finishChallenge() {
    if (_currentChallenge == null) return;
    var modified = _currentChallenge!.copyWith(progress: (_currentChallenge!.target * 1.25).toInt());
    _dao.updateObject(modified);
  }
}

class DailyChallengeService extends ChallengeService {
  @override
  int get _intervalLengthInDays => 1;

  @override
  DateTime get _intervalStartDay => DateTime.now();

  @override
  Future<List<Challenge>> get _openChallenges => _dao.getOpenDailyChallenges();

  @override
  ChallengesCompanion get _generatedChallenge => _generator.generateDailyChallenge();
}

class WeeklyChallengeService extends ChallengeService {
  @override
  int get _intervalLengthInDays => DateTime.daysPerWeek;

  @override
  DateTime get _intervalStartDay => DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

  @override
  Future<List<Challenge>> get _openChallenges => _dao.getOpenWeeklyChallenges();

  @override
  ChallengesCompanion get _generatedChallenge => _generator.generateWeeklyChallenge();
}
