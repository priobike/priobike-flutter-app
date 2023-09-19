import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:priobike/gamification/challenges/services/challenges_profile_service.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';
import 'package:priobike/gamification/challenges/utils/challenge_validator.dart';
import 'package:priobike/gamification/challenges/utils/challenge_generator.dart';
import 'package:priobike/gamification/common/services/evaluation_data_service.dart';
import 'package:priobike/logging/logger.dart';
import 'package:priobike/main.dart';

/// This class is to be extended by a service, which manages only challenges in a certain timeframe, such as
/// weekly or daily challenges.
abstract class ChallengeService with ChangeNotifier {
  final log = Logger('ChallengeService');

  /// DAO to access the challenges in the database.
  final ChallengeDao _dao = AppDatabase.instance.challengeDao;

  /// Generator to generate new challenges according to the user goals.
  ChallengeGenerator get _generator;

  /// Validator to continuously check the progress of the current open challenge corresponding to this service.
  ChallengeValidator? _validator;

  /// The stream subscription for the db updates of the current challenge. Required to cancel the stream later.
  StreamSubscription? _currentChallengeStream;

  /// The currently open challenge. This challenge can still be active, which means the user has still time to complete
  /// it, or it can be inactive and completed, such that the user can collect their rewards.
  Challenge? _currentChallenge;
  Challenge? get currentChallenge => _currentChallenge;

  /// This bool determines wether it should be allowed to generate a new challenge. This is only allowed, if there is
  /// no current challenge, or if the user hasn't started a challenge in the current timeframe yet.
  bool _allowNew = false;
  bool get allowNew => _allowNew;

  /// The length of the timeframe the user has to complete the challenges corresponding to this service.
  int get _intervalLengthInDays;

  /// The start day of the current timeframe the user has to complete the challenges corresponding to this service.
  DateTime get _intervalStartDay;

  /// Returns a list of challenges corresponding to the timeframe of this service, which are still open.
  Future<List<Challenge>> get _openChallenges;

  /// Whether only weekly challenges should be taken into consideration.
  bool get _isWeekly;

  List<Challenge> _challengeChoices = [];
  List<Challenge> get challengeChoices => _challengeChoices;

  int get _numberOfChoices;

  ChallengeService() {
    () async {
      await loadOpenChallenges();

      /// Set the allowNew variable to false, if there already is a challenge in the current timeframe.
      _dao.streamChallengesInInterval(_intervalStartDay, _intervalLengthInDays).listen((update) {
        update = update.where((challenge) => challenge.isWeekly == _isWeekly).toList();
        _allowNew = update.isEmpty;
      });
    }();
  }

  /// If the current challenge has been completed by the user and this method is called, the challenge is closed.
  void completeChallenge() async {
    if (_currentChallenge == null) return;
    // Do nothing, if the challenge wasn't completed yet.
    var notCompleted = _currentChallenge!.progress / _currentChallenge!.target < 1;
    if (notCompleted) return;

    // If the challenge has been completed, cancel the challenge stream, dispose the validator, and close it.
    _currentChallengeStream?.cancel();
    _validator?.dispose();
    var closedChallenge = _currentChallenge!.copyWith(isOpen: false);
    var result = await _dao.updateObject(closedChallenge);
    if (!result) throw Exception("Couldn't save challenge in database!");
    sendChallengeDataToBackend(closedChallenge);
    _currentChallenge = null;
  }

  /// This function starts a stream which listens for changes in the current challenge.
  void startChallengeStream() {
    if (_currentChallenge == null) return;
    _currentChallengeStream?.cancel();
    _currentChallengeStream = _dao.streamObjectByPrimaryKey(_currentChallenge!.id).listen((update) {
      _currentChallenge = update;
      notifyListeners();

      /// Cancel the stream, if the challenge has been deleted for some reason.
      if (update == null) _currentChallengeStream?.cancel();
    });
  }

  /// This function checks if there are open challenges and either closes them or updates the current challenge.
  Future<void> loadOpenChallenges() async {
    var openChallenges = await _openChallenges;
    // If no challenges are open, do nothing.
    if (openChallenges.isEmpty) return;

    // If multiple challenges are open, those are already generated challenge choices for the user.
    if (openChallenges.length > 1) {
      _challengeChoices = openChallenges;
      notifyListeners();
      return;
    }

    // If only one challenge is open, validate its progress with the current rides and determine whether it has been completed.
    var challenge = openChallenges.first;
    var rides = await AppDatabase.instance.rideSummaryDao.getRidesInInterval(
      challenge.startTime,
      challenge.closingTime,
    );
    await ChallengeValidator(challenge: challenge, startStream: false).validate(rides);
    try {
      challenge = (await AppDatabase.instance.challengeDao.getObjectByPrimaryKey(challenge.id))!;
    } catch (e) {
      log.e('Failed to validate open challenge');
    }
    var isCompleted = challenge.progress / challenge.target >= 1;

    // If an open challenge was not completed and the time did run out, close the challenge and send it to the backend.
    if (!isCompleted && !currentlyActive(challenge)) {
      var closedChallenge = challenge.copyWith(isOpen: false);
      var result = await _dao.updateObject(closedChallenge);
      if (result) sendChallengeDataToBackend(closedChallenge);
      return;
    }

    // If a challenge has been completed, or it still can be completed select it as the current challenge.
    _currentChallenge = challenge;
    _validator = ChallengeValidator(challenge: challenge);
    startChallengeStream();
  }

  /// Check, if a challenge is still active, which means the current timepoint is in the challenge interval.
  bool currentlyActive(Challenge challenge) {
    var now = DateTime.now();
    return now.isBefore(challenge.closingTime);
  }

  /// If the current challenge is null, generate new challenges.
  Future<List<Challenge>?> generateChallengeChoices() async {
    if (_currentChallenge != null) return null;
    _challengeChoices.clear();
    // Generate as many challenges, as choices are allowed for the user.
    var newChallenges = _generator.generateChallenges(_numberOfChoices);
    for (var c in newChallenges) {
      var challenge = await _dao.createObject(c);
      if (challenge != null) _challengeChoices.add(challenge);
    }
    // If something went wrong, delete generated challenges and return null.
    if (_challengeChoices.length != _numberOfChoices) {
      for (var c in _challengeChoices) {
        await _dao.deleteObject(c);
      }
      _challengeChoices.clear();
      return null;
    }
    // Return challenge choices to user.
    return _challengeChoices;
  }

  /// Select a challenge out of the available choices and start it. Delete the other choices.
  void selectAndStartChallenge(int choiceIndex) {
    if (_currentChallenge != null) return;
    // Save selected challenge as current challenge.
    _currentChallenge = _challengeChoices.elementAt(choiceIndex);
    _challengeChoices.remove(_currentChallenge);
    // Delete other open challenge choices.
    for (var challenge in _challengeChoices) {
      _dao.deleteObject(challenge);
    }
    _challengeChoices.clear();
    // Start the validator and observe changes in the challenge.
    _validator = ChallengeValidator(challenge: _currentChallenge!);
    startChallengeStream();
  }

  /// Send a given completed challenge to the backend.
  Future<void> sendChallengeDataToBackend(Challenge challenge) async {
    Map<String, dynamic> challengeData = {
      'challengeType': challenge.type,
      'isWeekly': challenge.isWeekly,
      'reachedValue': challenge.progress,
      'targetValue': challenge.target,
      'xp': challenge.xp,
      'completed': challenge.progress >= challenge.target,
      'startingTime': challenge.startTime.millisecondsSinceEpoch,
      'closingTime': challenge.closingTime.millisecondsSinceEpoch,
    };
    getIt<EvaluationDataService>().sendJsonToAddress('challenges/send-challenge/', challengeData);
  }
}

/// This service implements the challenge service and manages daily challenges.
class DailyChallengeService extends ChallengeService {
  @override
  int get _intervalLengthInDays => 1;

  @override
  DateTime get _intervalStartDay => DateTime.now();

  @override
  Future<List<Challenge>> get _openChallenges => _dao.getOpenDailyChallenges();

  @override
  ChallengeGenerator get _generator => DailyChallengeGenerator();

  @override
  bool get _isWeekly => false;

  @override
  int get _numberOfChoices => getIt<ChallengesProfileService>().profile!.dailyChallengeChoices;
}

/// This service implements the challenge service and manages weekly challenges.
class WeeklyChallengeService extends ChallengeService {
  @override
  int get _intervalLengthInDays => DateTime.daysPerWeek;

  @override
  DateTime get _intervalStartDay => DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));

  @override
  Future<List<Challenge>> get _openChallenges => _dao.getOpenWeeklyChallenges();

  @override
  ChallengeGenerator get _generator => WeeklyChallengeGenerator();

  @override
  bool get _isWeekly => true;

  @override
  int get _numberOfChoices => getIt<ChallengesProfileService>().profile!.weeklyChallengeChoices;
}
