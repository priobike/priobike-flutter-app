import 'package:drift/drift.dart';

class Challenges extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get xp => integer()();
  DateTimeColumn get intervalStart => dateTime()();
  DateTimeColumn get intervalEnd => dateTime()();
}

class DistanceChallenges extends Challenges {
  RealColumn get targetDistance => real()();
}
