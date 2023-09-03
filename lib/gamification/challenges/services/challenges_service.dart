import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:priobike/gamification/common/database/database.dart';
import 'package:priobike/gamification/common/database/model/challenges/challenge.dart';
import 'package:priobike/gamification/challenges/utils/challenge_validator.dart';
import 'package:priobike/gamification/challenges/utils/challenge_generator.dart';
import 'package:priobike/gamification/profile/services/profile_service.dart';
import 'package:priobike/main.dart';

/// This class is to be extended by a service, which manages only challenges in a certain timeframe, such as
/// weekly or daily challenges.
abstract class ChallengeService with ChangeNotifier {
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
  void completeChallenge() {
    if (_currentChallenge == null) return;
    // Do nothing, if the challenge wasn't completed yet.
    var notCompleted = _currentChallenge!.progress / _currentChallenge!.target < 1;
    if (notCompleted) return;

    // If the challenge has been completed, cancel the challenge stream, dispose the validator, and close it.
    _currentChallengeStream?.cancel();
    _validator?.dispose();
    _dao.updateObject(_currentChallenge!.copyWith(isOpen: false));
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
    var isCompleted = challenge.progress / challenge.target >= 1;

    // If an open challenge was not completed and the time did run out, close the challenge.
    if (!isCompleted && !currentlyActive(challenge)) {
      await _dao.updateObject(challenge.copyWith(isOpen: false));
      return;
    }

    /// If a challenge has been completed, or it still can be completed select it as the current challenge.
    _currentChallenge = challenge;
    _validator = ChallengeValidator(challenge: challenge);
    startChallengeStream();
  }

  /// Check, if a challenge is still active, which means the current timepoint is in the challenge interval.
  bool currentlyActive(Challenge challenge) {
    var now = DateTime.now();
    return now.isBefore(challenge.closingTime);
  }

  /// If the current challenge is null, generate a new challenge.
  Future<List<Challenge>?> generateChallenge() async {
    if (_currentChallenge != null) return null;
    _challengeChoices.clear();
    // Generate as many challenges, as choices are allowed for the user.
    for (int i = 0; i < _numberOfChoices; i++) {
      var newChallenge = await _dao.createObject(_generator.generate());
      if (newChallenge != null) _challengeChoices.add(newChallenge);
    }
    if (_challengeChoices.length != _numberOfChoices) throw Exception("Couldn't generate new challenge.");
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

  /// TODO helper function
  void deleteCurrentChallenge() {
    if (_currentChallenge == null) return;
    _dao.deleteObject(currentChallenge!);
  }

  /// TODO helper function
  void finishChallenge() {
    if (_currentChallenge == null) return;
    var modified = _currentChallenge!.copyWith(progress: (_currentChallenge!.target * 1.25).toInt());
    _dao.updateObject(modified);
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
  int get _numberOfChoices => getIt<GameProfileService>().profile!.dailyChallengeChoices;
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
  int get _numberOfChoices => getIt<GameProfileService>().profile!.weeklyChallengeChoices;
}
